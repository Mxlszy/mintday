import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/avatar_config.dart';
import '../../models/nft_asset.dart';
import '../avatar/pixel_avatar_painter.dart';
import '../local_image_preview.dart';
import 'nft_card_render_data.dart';
import 'nft_visuals.dart';

class MomentNftCard extends StatelessWidget {
  const MomentNftCard({super.key, required this.data, this.compact = false});

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final moodColors = moodToneColors(data.primaryMood);
    final rarityPalette = nftRarityPalette(data.rarity);
    final radius = compact ? 26.0 : 34.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodColors.first.withValues(alpha: 0.98),
            moodColors[1],
            moodColors.last.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: rarityPalette.base.withValues(alpha: 0.9),
          width: compact ? 1.4 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityPalette.glow.withValues(alpha: compact ? 0.24 : 0.34),
            blurRadius: compact ? 20 : 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: compact ? 12 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MomentBackground(
              imagePath: data.primaryImagePath,
              moodColors: moodColors,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.14),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            if (data.rarity == NftRarity.legendary)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LegendaryParticlePainter(
                      seed: data.title.hashCode,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(compact ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            'Moment Capture',
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        NftRarityChip(rarity: data.rarity, compact: compact),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 18),
                    _buildCoverImage(radius),
                    SizedBox(height: compact ? 16 : 18),
                    Text(
                      _formatDate(data.createdAt),
                      style: AppTextStyle.h2.copyWith(
                        color: Colors.white,
                        fontSize: compact ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.goalTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.h3.copyWith(
                        color: Colors.white,
                        fontSize: compact ? 16 : 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        PixelMoodFace(
                          mood: data.primaryMood,
                          size: compact ? 24 : 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data.primaryNote,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: compact ? 11.5 : 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 18),
                    _StatsRow(
                      compact: compact,
                      items: [
                        _StatItem(
                          icon: PixelIcons.fire,
                          label: '连续',
                          value: '${data.streakDays} 天',
                        ),
                        _StatItem(
                          icon: PixelIcons.chart,
                          label: '累计',
                          value: '${data.totalCheckIns} 次',
                        ),
                        _StatItem(
                          icon: PixelIcons.clock,
                          label: '专注',
                          value: '${data.focusMinutes} 分',
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: rarityPalette.soft.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          _AvatarBadge(
                            avatarConfig:
                                data.avatarConfig ?? AvatarConfig.defaultConfig,
                            compact: compact,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.nickname,
                                  style: AppTextStyle.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 13 : 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MintDay Memory',
                                  style: AppTextStyle.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.74),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            data.rarity.label.toUpperCase(),
                            style: AppTextStyle.caption.copyWith(
                              color: rarityPalette.soft,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(double radius) {
    final imagePath = data.primaryImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        height: compact ? 146 : 182,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 8),
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: moodToneColors(
                    data.primaryMood,
                  ).map((color) => color.withValues(alpha: 0.8)).toList(),
                ),
              ),
            ),
            Align(
              child: PixelIcon(
                icon: nftIconForCategory(NftCategory.moment),
                size: compact ? 48 : 60,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: compact ? 146 : 182,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius - 8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LocalImagePreview(
              imagePath: imagePath,
              width: double.infinity,
              height: double.infinity,
              borderRadius: radius - 8,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.24),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '打卡实拍',
                      style: AppTextStyle.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}.$mm.$dd';
  }
}

class _MomentBackground extends StatelessWidget {
  const _MomentBackground({required this.imagePath, required this.moodColors});

  final String? imagePath;
  final List<Color> moodColors;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return CustomPaint(painter: _PixelSkyPainter(colors: moodColors));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.24,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: LocalImagePreview(
                  imagePath: imagePath!,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  borderRadius: 0,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.8),
                  radius: 1.25,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    moodColors.first.withValues(alpha: 0.26),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items, required this.compact});

  final List<_StatItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item == items.last ? 0 : (compact ? 8 : 10),
                ),
                child: _StatTile(item: item, compact: compact),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final PixelIconData icon;
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item, required this.compact});

  final _StatItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixelIcon(
            icon: item.icon,
            size: compact ? 16 : 18,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: AppTextStyle.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12.5 : 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: AppTextStyle.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.avatarConfig, required this.compact});

  final AvatarConfig avatarConfig;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 48.0;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: PixelAvatar(config: avatarConfig, size: size - 12),
    );
  }
}

class _PixelSkyPainter extends CustomPainter {
  const _PixelSkyPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final pixel = math.max(12.0, size.shortestSide / 26);
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var row = 0; row < size.height / pixel; row++) {
      for (var col = 0; col < size.width / pixel; col++) {
        if ((row + col) % 3 != 0) continue;
        final alpha = 0.08 + ((row + col) % 5) * 0.03;
        dotPaint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.16));
        canvas.drawRect(
          Rect.fromLTWH(col * pixel, row * pixel, pixel - 2, pixel - 2),
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSkyPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _LegendaryParticlePainter extends CustomPainter {
  const _LegendaryParticlePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = const [
      Color(0xFFE040FB),
      Color(0xFFFFD740),
      Color(0xFF4FC3F7),
      Color(0xFFFF8A65),
    ];
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(seed);

    for (var i = 0; i < 24; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 1.6 + random.nextDouble() * 2.6;
      paint.color = colors[i % colors.length].withValues(alpha: 0.42);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendaryParticlePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
