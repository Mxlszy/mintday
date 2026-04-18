import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nft_asset.dart';
import 'nft_visuals.dart';

export 'nft_visuals.dart';

class NftCollectibleCard extends StatelessWidget {
  const NftCollectibleCard({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    this.rarity = NftRarity.common,
    this.compact = false,
  });

  final String title;
  final String description;
  final NftCategory category;
  final DateTime createdAt;
  final NftRarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = nftPaletteForCategory(category);
    final rarityPalette = nftRarityPalette(rarity);
    final icon = nftIconForCategory(category);
    final radius = compact ? 24.0 : AppTheme.radiusXL;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        border: Border.all(
          color: rarityPalette.base.withValues(alpha: 0.9),
          width: compact ? 1.4 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityPalette.glow.withValues(alpha: compact ? 0.22 : 0.34),
            blurRadius: compact ? 18 : 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: palette.glow.withValues(alpha: compact ? 0.16 : 0.24),
            blurRadius: compact ? 14 : 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: compact ? 10 : 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.15, -0.2),
                  radius: 1.1,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: compact ? -18 : -28,
              right: compact ? -12 : -18,
              child: _GlowOrb(size: compact ? 86 : 130, color: palette.glow),
            ),
            Positioned(
              bottom: compact ? 18 : 22,
              left: compact ? -18 : -26,
              child: _GlowOrb(
                size: compact ? 62 : 96,
                color: palette.secondary,
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _PixelFramePainter(
                  color: rarityPalette.base.withValues(alpha: 0.96),
                  radius: radius,
                ),
              ),
            ),
            if (rarity == NftRarity.legendary)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: rarityPalette.gradient
                            .map((color) => color.withValues(alpha: 0.18))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(compact ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardBadge(
                        label: category.label,
                        background: Colors.white.withValues(alpha: 0.14),
                      ),
                      const Spacer(),
                      NftRarityChip(rarity: rarity, compact: compact),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: compact ? 84 : 126,
                      height: compact ? 84 : 126,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Center(
                        child: PixelIcon(
                          icon: icon,
                          size: compact ? 42 : 66,
                          color: palette.icon,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 20),
                  Text(
                    title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.h3.copyWith(
                      color: Colors.white,
                      fontSize: compact ? 17 : 20,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: compact ? 11.5 : 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 12,
                      vertical: compact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        PixelIcon(
                          icon: PixelIcons.diamond,
                          size: 14,
                          color: AppTheme.goldAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MintDay Collectible',
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: AppTextStyle.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: compact ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}.$mm.$dd';
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelFramePainter extends CustomPainter {
  const _PixelFramePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final pixel = math.max(4.0, size.shortestSide * 0.022);
    final inset = pixel * 1.3;

    for (double dx = inset; dx < size.width - inset; dx += pixel * 1.85) {
      _paintPixel(canvas, paint, Offset(dx, inset), pixel);
      _paintPixel(
        canvas,
        paint,
        Offset(dx, size.height - inset - pixel),
        pixel,
      );
    }

    for (double dy = inset; dy < size.height - inset; dy += pixel * 1.85) {
      _paintPixel(canvas, paint, Offset(inset, dy), pixel);
      _paintPixel(canvas, paint, Offset(size.width - inset - pixel, dy), pixel);
    }

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        Radius.circular(radius),
      ),
      outlinePaint,
    );
  }

  void _paintPixel(Canvas canvas, Paint paint, Offset offset, double size) {
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, size, size), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelFramePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
