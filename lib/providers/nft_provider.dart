import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/app_navigator.dart';
import '../models/nft_asset.dart';
import '../services/database_service.dart';
import '../services/share_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/nft/nft_card_factory.dart';
import '../widgets/nft/nft_card_render_data.dart';

class NftProvider extends ChangeNotifier {
  static const _name = 'NftProvider';

  final _uuid = const Uuid();
  final _random = math.Random();

  List<NftAsset> _assets = [];
  bool _isLoading = false;
  String? _error;

  List<NftAsset> get assets => List.unmodifiable(_assets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await loadNfts();
  }

  Future<void> loadNfts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await DatabaseService.getAllNftAssets();
    } catch (e, s) {
      _error = '加载 NFT 失败，请稍后重试';
      log('[$_name] loadNfts failed: $e', name: _name, error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<NftAsset> getMyNfts() => List.unmodifiable(_assets);

  NftAsset? getNftById(String id) {
    try {
      return _assets.firstWhere((asset) => asset.id == id);
    } catch (_) {
      return null;
    }
  }

  NftAsset? findByCheckInTemplate({
    required NftCategory category,
    String? checkInId,
    String? templateId,
  }) {
    if (checkInId == null) return null;
    try {
      return _assets.firstWhere(
        (asset) =>
            asset.category == category &&
            asset.checkInId == checkInId &&
            asset.templateId == templateId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<NftAsset?> generateNftCard(
    String title,
    String description,
    NftCategory category,
    String? sourceId,
  ) async {
    final renderData = NftCardRenderData(
      title: title,
      description: description,
      createdAt: DateTime.now(),
      nickname: 'MintDay',
      rarity: NftRarity.common,
      metadata: const <String, dynamic>{'legacy': true},
    );

    return createRenderedNft(
      category: category,
      sourceId: sourceId,
      renderData: renderData,
      allowExistingMatch: true,
    );
  }

  Future<NftAsset?> createRenderedNft({
    required NftCategory category,
    required NftCardRenderData renderData,
    String? sourceId,
    String? checkInId,
    String? templateId,
    bool allowExistingMatch = false,
  }) async {
    final existing = _findExistingAsset(
      category: category,
      sourceId: sourceId,
      checkInId: checkInId,
      templateId: templateId,
      allowExistingMatch: allowExistingMatch,
    );
    if (existing != null) return existing;

    final context = appNavigatorKey.currentContext;
    if (context == null) {
      _error = '暂时无法生成 NFT 卡片，请稍后重试';
      notifyListeners();
      return null;
    }

    try {
      final createdAt = renderData.createdAt;
      final bytes = await ShareExportService.captureWidgetToPng(
        context,
        InheritedTheme.captureAll(
          context,
          Material(
            color: Colors.transparent,
            child: Center(
              child: SizedBox(
                width: 420,
                height: 560,
                child: buildNftArtwork(
                  category: category,
                  data: renderData,
                  templateId: templateId,
                ),
              ),
            ),
          ),
        ),
        targetSize: const Size(420, 560),
        delay: const Duration(milliseconds: 420),
      );

      final imagePath = await StorageService.saveBytes(
        bytes,
        folderName: 'nft_cards',
      );
      if (imagePath == null) {
        throw StateError(
          'Current platform does not support saving NFT images.',
        );
      }

      final metadata = renderData.metadata.isEmpty
          ? null
          : jsonEncode(renderData.metadata);
      final asset = NftAsset(
        id: _uuid.v4(),
        title: renderData.title,
        description: renderData.description,
        category: category,
        sourceId: sourceId,
        checkInId: checkInId,
        templateId: templateId,
        metadata: metadata,
        imagePath: imagePath,
        status: NftStatus.pending,
        rarity: renderData.rarity,
        createdAt: createdAt,
      );

      await DatabaseService.insertNftAsset(asset);
      if (sourceId != null &&
          (category == NftCategory.milestone ||
              category == NftCategory.streak)) {
        await DatabaseService.updateMilestoneCardImage(sourceId, imagePath);
      }

      _assets = [asset, ..._assets];
      _error = null;
      notifyListeners();
      return asset;
    } catch (e, s) {
      _error = '生成 NFT 卡片失败，请稍后重试';
      log(
        '[$_name] createRenderedNft failed: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return null;
    }
  }

  Future<NftAsset?> mintNft(String assetId) async {
    final index = _assets.indexWhere((asset) => asset.id == assetId);
    if (index == -1) return null;

    final asset = _assets[index];
    if (asset.status == NftStatus.minting || asset.status == NftStatus.minted) {
      return asset;
    }

    final mintingAsset = asset.copyWith(status: NftStatus.minting);
    await _commitAsset(index, mintingAsset);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final txHash = _buildTxHash();
      final tokenId = _buildTokenId();
      final mintedAt = DateTime.now();
      final mintedAsset = mintingAsset.copyWith(
        status: NftStatus.minted,
        txHash: txHash,
        tokenId: tokenId,
        mintedAt: mintedAt,
      );

      await _commitAsset(index, mintedAsset);
      if (mintedAsset.sourceId != null &&
          (mintedAsset.category == NftCategory.milestone ||
              mintedAsset.category == NftCategory.streak)) {
        await DatabaseService.markMilestoneMinted(
          mintedAsset.sourceId!,
          txHash: txHash,
          cardImagePath: mintedAsset.imagePath,
        );
      }
      _error = null;
      return mintedAsset;
    } catch (e, s) {
      final failedAsset = asset.copyWith(status: NftStatus.failed);
      await _commitAsset(index, failedAsset);
      _error = '模拟铸造失败，请稍后重试';
      log('[$_name] mintNft failed: $e', name: _name, error: e, stackTrace: s);
      notifyListeners();
      return failedAsset;
    }
  }

  NftAsset? _findExistingAsset({
    required NftCategory category,
    String? sourceId,
    String? checkInId,
    String? templateId,
    required bool allowExistingMatch,
  }) {
    if (!allowExistingMatch) return null;

    if (checkInId != null) {
      try {
        return _assets.firstWhere(
          (asset) =>
              asset.category == category &&
              asset.checkInId == checkInId &&
              asset.templateId == templateId,
        );
      } catch (_) {}
    }

    if (sourceId != null) {
      try {
        return _assets.firstWhere(
          (asset) => asset.category == category && asset.sourceId == sourceId,
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> _commitAsset(int index, NftAsset asset) async {
    _assets[index] = asset;
    notifyListeners();
    await DatabaseService.updateNftAsset(asset);
  }

  String _buildTxHash() {
    const chars = '0123456789abcdef';
    final buffer = StringBuffer('0x');
    for (var i = 0; i < 64; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  String _buildTokenId() {
    final value = BigInt.parse(
      List.generate(12, (_) => _random.nextInt(16).toRadixString(16)).join(),
      radix: 16,
    );
    return value.toString();
  }
}
