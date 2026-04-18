import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/user_profile_model.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../models/nft_asset.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/nft_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/share_export_service.dart';
import '../../services/user_profile_prefs.dart';
import '../../widgets/local_image_preview.dart';
import '../../widgets/nft/nft_card_factory.dart';
import '../../widgets/nft/nft_card_render_data.dart';
import '../../widgets/nft/nft_visuals.dart';

class NftDetailPage extends StatefulWidget {
  const NftDetailPage({super.key, required this.assetId});

  final String assetId;

  @override
  State<NftDetailPage> createState() => _NftDetailPageState();
}

class _NftDetailPageState extends State<NftDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _mintController;
  late final AnimationController _successController;
  late final AnimationController _rarityController;

  bool _mintBusy = false;
  bool _shareBusy = false;
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    _mintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _rarityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _mintController.dispose();
    _successController.dispose();
    _rarityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<NftProvider, CheckInProvider, GoalProvider>(
      builder: (context, nftProvider, checkInProvider, goalProvider, _) {
        final asset = nftProvider.getNftById(widget.assetId);
        if (asset == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('NFT 不存在或已被移除')),
          );
        }

        final checkIn = _findCheckIn(checkInProvider.checkIns, asset.checkInId);
        final goal = checkIn == null
            ? null
            : goalProvider.getGoalById(checkIn.goalId);
        final renderData = _buildRenderData(
          asset: asset,
          checkIn: checkIn,
          goal: goal,
          profile: context.read<UserProfileProvider>().profile,
          allCheckIns: checkInProvider.checkIns,
        );
        final isMinting = asset.status == NftStatus.minting || _mintBusy;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('NFT 详情')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              120,
            ),
            children: [
              _buildHeroCard(asset, renderData, isMinting),
              const SizedBox(height: AppTheme.spacingL),
              _buildActionRow(asset, renderData),
              const SizedBox(height: AppTheme.spacingL),
              _SectionCard(
                title: '纪念信息',
                child: Column(
                  children: [
                    _InfoRow(label: '标题', value: asset.title),
                    _InfoRow(label: '描述', value: asset.description),
                    _InfoRow(label: '类别', value: asset.category.label),
                    _InfoRow(label: '稀有度', value: asset.effectiveRarity.label),
                    _InfoRow(
                      label: '创建时间',
                      value: _formatDateTime(asset.createdAt),
                    ),
                    _InfoRow(label: '状态', value: asset.status.label),
                  ],
                ),
              ),
              if (asset.category == NftCategory.moment && checkIn != null) ...[
                const SizedBox(height: AppTheme.spacingL),
                _MomentInfoSection(checkIn: checkIn, goal: goal),
              ],
              if (asset.metadataMap.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingL),
                _MetadataSection(metadata: asset.metadataMap),
              ],
              if (asset.status == NftStatus.minted) ...[
                const SizedBox(height: AppTheme.spacingL),
                _SectionCard(
                  title: '模拟链上信息',
                  child: Column(
                    children: [
                      _InfoRow(label: '交易哈希', value: _shortHash(asset.txHash)),
                      _InfoRow(label: 'Token ID', value: asset.tokenId ?? '--'),
                      _InfoRow(
                        label: '铸造时间',
                        value: asset.mintedAt == null
                            ? '--'
                            : _formatDateTime(asset.mintedAt!),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                0,
                AppTheme.spacingL,
                AppTheme.spacingL,
              ),
              child: asset.status == NftStatus.minted
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.bonusMint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.bonusMint.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '这张纪念卡已经成功铸造完成',
                          style: AppTextStyle.body.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: isMinting ? null : () => _handleMint(asset.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: isMinting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('正在铸造纪念卡...'),
                                ],
                              )
                            : const Text('铸造为 NFT'),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(
    NftAsset asset,
    NftCardRenderData renderData,
    bool isMinting,
  ) {
    final rarityPalette = nftRarityPalette(asset.effectiveRarity);
    final image = asset.imagePath.isEmpty
        ? buildNftArtwork(
            category: asset.category,
            data: renderData,
            templateId: asset.templateId,
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              return LocalImagePreview(
                imagePath: asset.imagePath,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                borderRadius: AppTheme.radiusXL,
                fit: BoxFit.cover,
              );
            },
          );

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mintController,
        _successController,
        _rarityController,
      ]),
      builder: (context, child) {
        final mintValue = _mintController.value;
        final successValue = _successController.value;
        final pulse =
            0.7 + math.sin(_rarityController.value * math.pi * 2) * 0.3;
        final glowOpacity = switch (asset.effectiveRarity) {
          NftRarity.common => 0.18,
          NftRarity.rare => 0.28,
          NftRarity.epic => 0.34,
          NftRarity.legendary => 0.44,
        };
        final scale = isMinting
            ? 1 + math.sin(mintValue * math.pi * 2) * 0.03
            : 1.0;
        final rotation = isMinting
            ? math.sin(mintValue * math.pi * 2) * 0.02
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(
              color: rarityPalette.base.withValues(alpha: 0.6 + pulse * 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: rarityPalette.glow.withValues(
                  alpha: glowOpacity * pulse,
                ),
                blurRadius: 26 + pulse * 8,
                offset: const Offset(0, 14),
              ),
              ...AppTheme.neuRaised,
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  NftStatusChip(status: asset.status),
                  const SizedBox(width: 10),
                  NftRarityChip(rarity: asset.effectiveRarity, compact: true),
                  const Spacer(),
                  NftCategoryChip(category: asset.category, compact: true),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                height: 420,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: asset.heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXL,
                            ),
                            child: child!,
                          ),
                        ),
                        if (isMinting)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXL,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.04),
                                      AppTheme.goldAccent.withValues(
                                        alpha: 0.18,
                                      ),
                                      Colors.white.withValues(alpha: 0.04),
                                    ],
                                    stops: [
                                      (mintValue - 0.25).clamp(0.0, 1.0),
                                      mintValue.clamp(0.0, 1.0),
                                      (mintValue + 0.25).clamp(0.0, 1.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (successValue > 0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _MintSuccessPainter(
                                  progress: successValue,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: image,
    );
  }

  Widget _buildActionRow(NftAsset asset, NftCardRenderData renderData) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareBusy ? null : () => _shareAsset(asset, renderData),
            icon: _shareBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded, size: 18),
            label: const Text('分享'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _avatarBusy ? null : () => _setAvatarBackground(asset),
            icon: _avatarBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.image_outlined, size: 18),
            label: const Text('设为头像背景'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleMint(String assetId) async {
    if (_mintBusy) return;
    setState(() => _mintBusy = true);
    _mintController.repeat();

    final nftProvider = context.read<NftProvider>();
    final result = await nftProvider.mintNft(assetId);

    _mintController.stop();
    _mintController.reset();
    if (result?.status == NftStatus.minted && mounted) {
      await _successController.forward(from: 0);
      if (!mounted) return;
      AppUtils.showSnackBar(context, '铸造完成，这张纪念卡已经进入你的收藏库');
    } else if (mounted) {
      AppUtils.showSnackBar(context, '铸造失败，请稍后再试', isError: true);
    }

    if (mounted) {
      setState(() => _mintBusy = false);
    }
  }

  Future<void> _shareAsset(NftAsset asset, NftCardRenderData renderData) async {
    if (_shareBusy) return;
    setState(() => _shareBusy = true);

    try {
      final bytes = await ShareExportService.captureWidgetToPng(
        context,
        Material(
          color: Colors.transparent,
          child: Center(
            child: SizedBox(
              width: 420,
              height: 560,
              child: buildNftArtwork(
                category: asset.category,
                data: renderData,
                templateId: asset.templateId,
              ),
            ),
          ),
        ),
        targetSize: const Size(420, 560),
        delay: const Duration(milliseconds: 300),
      );
      if (!mounted) return;
      await ShareExportService.sharePngBytes(
        bytes,
        'mintday_nft_${asset.id}',
        text: '这是我在 MintDay 铸造的一张纪念 NFT',
      );
    } catch (_) {
      if (!mounted) return;
      AppUtils.showSnackBar(context, '分享失败，请稍后再试', isError: true);
    } finally {
      if (mounted) {
        setState(() => _shareBusy = false);
      }
    }
  }

  Future<void> _setAvatarBackground(NftAsset asset) async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      await UserProfilePrefs.setAvatarBackgroundNftId(asset.id);
      if (!mounted) return;
      AppUtils.showSnackBar(context, '已将这张 NFT 设为头像背景候选');
    } catch (_) {
      if (!mounted) return;
      AppUtils.showSnackBar(context, '设置失败，请稍后重试', isError: true);
    } finally {
      if (mounted) {
        setState(() => _avatarBusy = false);
      }
    }
  }

  NftCardRenderData _buildRenderData({
    required NftAsset asset,
    required CheckIn? checkIn,
    required Goal? goal,
    required UserProfileModel profile,
    required List<CheckIn> allCheckIns,
  }) {
    final metadata = asset.metadataMap;
    final collectionIds = List<String>.from(
      metadata['collectionCheckInIds'] as List<dynamic>? ?? const [],
    );
    final collectionCheckIns = allCheckIns
        .where((item) => collectionIds.contains(item.id))
        .toList();
    final capturedAt =
        DateTime.tryParse(metadata['capturedAt']?.toString() ?? '') ??
        checkIn?.createdAt ??
        asset.createdAt;

    return NftCardRenderData(
      title: asset.title,
      description: asset.description,
      createdAt: capturedAt,
      nickname: profile.nickname,
      rarity: asset.effectiveRarity,
      avatarConfig: profile.avatarConfig,
      primaryCheckIn: checkIn,
      goal: goal,
      collectionCheckIns: collectionCheckIns,
      streakDays: _readInt(metadata['streakDays']),
      totalCheckIns: _readInt(metadata['totalCheckIns']),
      focusMinutes: _readInt(metadata['focusMinutes']),
      metadata: metadata,
    );
  }

  CheckIn? _findCheckIn(List<CheckIn> checkIns, String? checkInId) {
    if (checkInId == null) return null;
    try {
      return checkIns.firstWhere((item) => item.id == checkInId);
    } catch (_) {
      return null;
    }
  }

  int _readInt(dynamic value) {
    return value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
  }

  String _shortHash(String? value) {
    if (value == null || value.length < 12) return value ?? '--';
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.h3),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 76, child: Text(label, style: AppTextStyle.label)),
          Expanded(child: Text(value, style: AppTextStyle.body)),
        ],
      ),
    );
  }
}

class _MomentInfoSection extends StatelessWidget {
  const _MomentInfoSection({required this.checkIn, required this.goal});

  final CheckIn checkIn;
  final Goal? goal;

  @override
  Widget build(BuildContext context) {
    final imagePath = checkIn.imagePaths.isEmpty
        ? null
        : checkIn.imagePaths.first;
    return _SectionCard(
      title: '关联打卡数据',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              child: LocalImagePreview(
                imagePath: imagePath,
                width: double.infinity,
                height: 180,
                borderRadius: AppTheme.radiusL,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
          _InfoRow(label: '目标', value: goal?.title ?? '未找到目标'),
          _InfoRow(label: '心情', value: '等级 ${checkIn.mood ?? 3}'),
          if (checkIn.note != null) _InfoRow(label: '笔记', value: checkIn.note!),
          if (checkIn.reflectionProgress != null)
            _InfoRow(label: '进展', value: checkIn.reflectionProgress!),
          if (checkIn.reflectionNext != null)
            _InfoRow(label: '下一步', value: checkIn.reflectionNext!),
        ],
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.metadata});

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[];
    void add(String label, String key) {
      final value = metadata[key];
      if (value == null) return;
      rows.add(MapEntry(label, value.toString()));
    }

    add('模板', 'templateLabel');
    add('节日', 'holidayLabel');
    add('连续天数', 'streakDays');
    add('累计次数', 'totalCheckIns');
    add('专注时长', 'focusMinutes');

    final reasons = List<String>.from(
      metadata['rarityReasons'] as List<dynamic>? ?? const [],
    );

    return _SectionCard(
      title: '生成参数',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows.map(
            (entry) => _InfoRow(label: entry.key, value: entry.value),
          ),
          if (reasons.isNotEmpty) ...[
            Text('稀有度说明', style: AppTextStyle.label),
            const SizedBox(height: 8),
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(reason, style: AppTextStyle.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MintSuccessPainter extends CustomPainter {
  const _MintSuccessPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.goldAccent.withValues(alpha: 0.28 * (1 - progress)),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.45),
          );

    canvas.drawCircle(center, size.width * (0.12 + progress * 0.42), glowPaint);

    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.86 * (1 - progress * 0.65))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final angle = (math.pi * 2 / 18) * i;
      final start =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (32 + progress * 12);
      final end =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (78 + progress * 82);
      canvas.drawLine(start, end, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MintSuccessPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
