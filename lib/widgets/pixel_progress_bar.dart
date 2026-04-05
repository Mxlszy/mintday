import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PixelProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final int blockCount;
  final Color? activeColor;
  final Color? inactiveColor;

  const PixelProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
    this.blockCount = 12,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _PixelProgressPainter(
          progress: progress.clamp(0.0, 1.0),
          blockCount: blockCount,
          activeColor: activeColor ?? AppTheme.primary,
          inactiveColor: inactiveColor ?? AppTheme.surfaceVariant,
        ),
      ),
    );
  }
}

class _PixelProgressPainter extends CustomPainter {
  final double progress;
  final int blockCount;
  final Color activeColor;
  final Color inactiveColor;

  _PixelProgressPainter({
    required this.progress,
    required this.blockCount,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gap = 2.0;
    final totalGaps = (blockCount - 1) * gap;
    final blockWidth = (size.width - totalGaps) / blockCount;
    final blockHeight = size.height;
    final filledCount = (progress * blockCount).ceil();

    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = inactiveColor;

    for (int i = 0; i < blockCount; i++) {
      final x = i * (blockWidth + gap);
      final rect = Rect.fromLTWH(x, 0, blockWidth, blockHeight);
      canvas.drawRect(rect, i < filledCount ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelProgressPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.blockCount != blockCount;
}
