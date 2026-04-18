import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/neumorphic.dart';
import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nft_asset.dart';
import '../../providers/nft_provider.dart';
import '../../widgets/local_image_preview.dart';
import '../../widgets/nft/nft_collectible_card.dart';
import 'mint_nft_page.dart';
import 'nft_detail_page.dart';

class WalletNftTab extends StatefulWidget {
  const WalletNftTab({super.key});

  @override
  State<WalletNftTab> createState() => _WalletNftTabState();
}

class _WalletNftTabState extends State<WalletNftTab> {
  NftCategory? _categoryFilter;
  NftRarity? _rarityFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer<NftProvider>(
      builder: (context, nftProvider, _) {
        final assets = nftProvider.getMyNfts();
        final rarityCounts = <NftRarity, int>{
          for (final rarity in NftRarity.values)
            rarity: assets
                .where((item) => item.effectiveRarity == rarity)
                .length,
        };
        final filteredAssets = assets.where((asset) {
          final matchCategory =
              _categoryFilter == null || asset.category == _categoryFilter;
          final matchRarity =
              _rarityFilter == null || asset.effectiveRarity == _rarityFilter;
          return matchCategory && matchRarity;
        }).toList();
        final waterfall = _splitForWaterfall(filteredAssets);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            0,
            AppTheme.spacingL,
            AppTheme.spacingXL,
          ),
          children: [
            _WalletHero(
              totalCount: assets.length,
              rarityCounts: rarityCounts,
              onMintTap: () => Navigator.of(
                context,
              ).push(sharedAxisRoute(const MintNftPage())),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text('筛选收藏', style: AppTextStyle.h3),
            const SizedBox(height: 8),
            _FilterStrip<NftCategory>(
              current: _categoryFilter,
              labelBuilder: (item) => item.label,
              items: NftCategory.values,
              onChanged: (value) => setState(() => _categoryFilter = value),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _FilterStrip<NftRarity>(
              current: _rarityFilter,
              labelBuilder: (item) => item.label,
              items: NftRarity.values,
              onChanged: (value) => setState(() => _rarityFilter = value),
            ),
            const SizedBox(height: AppTheme.spacingL),
            if (nftProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: AppTheme.spacingXL),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (assets.isEmpty)
              const _WalletEmptyState()
            else if (filteredAssets.isEmpty)
              const _WalletFilteredEmptyState()
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: waterfall.left
                          .map(
                            (asset) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingM,
                              ),
                              child: _WalletGridCard(asset: asset),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      children: waterfall.right
                          .map(
                            (asset) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingM,
                              ),
                              child: _WalletGridCard(asset: asset),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  _WaterfallColumns _splitForWaterfall(List<NftAsset> assets) {
    final left = <NftAsset>[];
    final right = <NftAsset>[];
    double leftWeight = 0;
    double rightWeight = 0;

    for (final asset in assets) {
      final estimate = switch (asset.category) {
        NftCategory.moment => 1.18,
        NftCategory.creative => 1.12,
        NftCategory.collection => 1.08,
        _ => 0.96,
      };
      final descriptionFactor = asset.description.length / 120;
      final total = estimate + descriptionFactor;
      if (leftWeight <= rightWeight) {
        left.add(asset);
        leftWeight += total;
      } else {
        right.add(asset);
        rightWeight += total;
      }
    }

    return _WaterfallColumns(left: left, right: right);
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.totalCount,
    required this.rarityCounts,
    required this.onMintTap,
  });

  final int totalCount;
  final Map<NftRarity, int> rarityCounts;
  final VoidCallback onMintTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10131D), Color(0xFF24324F), Color(0xFF4A7AA1)],
        ),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: PixelIcon(
                    icon: PixelIcons.diamond,
                    size: 28,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的 NFT 收藏馆',
                      style: AppTextStyle.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '把打卡瞬间、创意模板与周回顾都收进你的个人纪念宇宙。',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onMintTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('去铸造'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            '$totalCount',
            style: AppTextStyle.statNumber.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '总收藏数',
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: NftRarity.values
                .map(
                  (rarity) => _RarityCountBadge(
                    rarity: rarity,
                    count: rarityCounts[rarity] ?? 0,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WalletGridCard extends StatelessWidget {
  const _WalletGridCard({required this.asset});

  final NftAsset asset;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: AppTheme.radiusL,
      onTap: () {
        Navigator.of(
          context,
        ).push(sharedAxisRoute(NftDetailPage(assetId: asset.id)));
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _showPreview(context, asset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: asset.heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    child: AspectRatio(
                      aspectRatio: 0.78,
                      child: asset.imagePath.isNotEmpty
                          ? LocalImagePreview(
                              imagePath: asset.imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: AppTheme.radiusL,
                              fit: BoxFit.cover,
                            )
                          : NftCollectibleCard(
                              title: asset.title,
                              description: asset.description,
                              category: asset.category,
                              createdAt: asset.createdAt,
                              rarity: asset.effectiveRarity,
                              compact: true,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: NftRarityChip(
                    rarity: asset.effectiveRarity,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              asset.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                NftStatusChip(status: asset.status),
                NftCategoryChip(category: asset.category, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, NftAsset asset) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: asset.heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  child: SizedBox(
                    width: 280,
                    height: 374,
                    child: asset.imagePath.isNotEmpty
                        ? LocalImagePreview(
                            imagePath: asset.imagePath,
                            width: 280,
                            height: 374,
                            borderRadius: AppTheme.radiusXL,
                          )
                        : NftCollectibleCard(
                            title: asset.title,
                            description: asset.description,
                            category: asset.category,
                            createdAt: asset.createdAt,
                            rarity: asset.effectiveRarity,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(
                    context,
                  ).push(sharedAxisRoute(NftDetailPage(assetId: asset.id)));
                },
                child: const Text('查看详情'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterStrip<T> extends StatelessWidget {
  const _FilterStrip({
    required this.current,
    required this.labelBuilder,
    required this.items,
    required this.onChanged,
  });

  final T? current;
  final String Function(T item) labelBuilder;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: '全部',
            selected: current == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChipButton(
                label: labelBuilder(item),
                selected: current == item,
                onTap: () => onChanged(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RarityCountBadge extends StatelessWidget {
  const _RarityCountBadge({required this.rarity, required this.count});

  final NftRarity rarity;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = nftRarityPalette(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.base.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rarity.label,
            style: AppTextStyle.caption.copyWith(
              color: palette.soft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletEmptyState extends StatelessWidget {
  const _WalletEmptyState();

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 292,
            child: NftCollectibleCard(
              title: '第一张纪念卡',
              description: '完成一次打卡或进入铸造页后，这里会出现属于你的 NFT 收藏。',
              category: NftCategory.moment,
              createdAt: DateTime.now(),
              rarity: NftRarity.rare,
              compact: true,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text('还没有 NFT 收藏', style: AppTextStyle.h3),
          const SizedBox(height: 8),
          Text(
            '从打卡完成弹窗或这里的“去铸造”入口开始，把瞬间做成一张真正属于自己的纪念卡。',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WalletFilteredEmptyState extends StatelessWidget {
  const _WalletFilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off, color: AppTheme.textHint, size: 28),
          const SizedBox(height: 10),
          Text('当前筛选下还没有收藏', style: AppTextStyle.h3),
          const SizedBox(height: 6),
          Text('换一个类别或稀有度看看。', style: AppTextStyle.bodySmall),
        ],
      ),
    );
  }
}

class _WaterfallColumns {
  const _WaterfallColumns({required this.left, required this.right});

  final List<NftAsset> left;
  final List<NftAsset> right;
}
