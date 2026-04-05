import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils.dart';

class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final bool showLabel;
  final Color? color;
  final Color? backgroundColor;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.showLabel = false,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? AppTheme.primary;
    final bgColor = backgroundColor ?? AppTheme.surfaceVariant;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          ringColor: ringColor,
          backgroundColor: bgColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: showLabel
              ? Text(
                  AppUtils.progressText(progress),
                  // 字号随环尺寸变化，无法用固定 AppTextStyle 档位；继承主题字体族。
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                    color: ringColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
