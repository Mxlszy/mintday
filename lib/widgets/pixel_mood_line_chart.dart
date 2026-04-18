import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/utils.dart';
import '../models/check_in.dart';

/// 单日聚合点（最近 30 天窗口内的一天）。
class MoodDaySample {
  final int dayIndex;
  final DateTime date;
  final double moodAvg;

  const MoodDaySample({
    required this.dayIndex,
    required this.date,
    required this.moodAvg,
  });
}

/// 近 30 天心情折线（CustomPainter，无第三方图表库）。
class PixelMoodLineChart extends StatelessWidget {
  final List<CheckIn> checkIns;

  const PixelMoodLineChart({super.key, required this.checkIns});

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// mood != null、非跳过；窗口内按日取平均；按日期顺序。
  static List<MoodDaySample> buildSamples(List<CheckIn> checkIns) {
    final today = _dayOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 29));

    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final c in checkIns) {
      if (c.mood == null || c.status == CheckInStatus.skipped) continue;
      final d = _dayOnly(c.date);
      if (d.isBefore(start) || d.isAfter(today)) continue;
      final k =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      sums[k] = (sums[k] ?? 0) + c.mood!;
      counts[k] = (counts[k] ?? 0) + 1;
    }

    final samples = <MoodDaySample>[];
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      final k =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final n = counts[k];
      if (n == null || n == 0) continue;
      samples.add(MoodDaySample(dayIndex: i, date: d, moodAvg: sums[k]! / n));
    }
    samples.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    return samples;
  }

  static String _moodEmoji(double value) {
    final r = value.round().clamp(1, 5);
    return switch (r) {
      1 => '😣',
      2 => '😐',
      3 => '🙂',
      4 => '😊',
      5 => '🤩',
      _ => '🙂',
    };
  }

  static String _xTickLabel(DateTime d) => '${d.month}/${d.day}';

  @override
  Widget build(BuildContext context) {
    final samples = buildSamples(checkIns);
    final today = _dayOnly(DateTime.now());
    final windowStart = today.subtract(const Duration(days: 29));

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: AppTheme.spacingM),
          if (samples.isEmpty)
            const _MoodChartEmptyState()
          else
            _MoodChartBody(
              samples: samples,
              windowStart: windowStart,
              onPointTap: (sample) {
                final msg =
                    '${AppUtils.friendlyDate(sample.date)}（${_xTickLabel(sample.date)}）· '
                    '心情 ${_moodEmoji(sample.moodAvg)} ${sample.moodAvg.toStringAsFixed(1)} / 5';
                AppUtils.showSnackBar(context, msg);
              },
            ),
          const SizedBox(height: 8),
          Text(
            samples.isEmpty
                ? '打卡时记录心情，即可在此看到 1–5 分轨迹'
                : '纵轴 1–5 分 · 同一天多次打卡取平均 · 点圆点查看当日',
            style: AppTextStyle.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        PixelIcon(icon: PixelIcons.chart, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text('近 30 天心情', style: AppTextStyle.label),
      ],
    );
  }
}

class _MoodChartEmptyState extends StatelessWidget {
  const _MoodChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelIcon(
                    icon: PixelIcons.chart,
                    size: 32,
                    color: AppTheme.accent.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 16),
                  PixelIcon(
                    icon: PixelIcons.sprout,
                    size: 28,
                    color: AppTheme.accentStrong.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 16),
                  PixelIcon(
                    icon: PixelIcons.heart,
                    size: 28,
                    color: AppTheme.bonusRose.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              '开始打卡后，心情轨迹会在这里浮现',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChartBody extends StatelessWidget {
  final List<MoodDaySample> samples;
  final DateTime windowStart;
  final void Function(MoodDaySample sample) onPointTap;

  const _MoodChartBody({
    required this.samples,
    required this.windowStart,
    required this.onPointTap,
  });

  static const double _yAxisW = 26;
  static const double _chartH = 200;
  static const double _xLabelH = 22;
  static const double _plotTopPad = 6;
  static const double _plotBottomPad = 6;
  static const double _dotR = 4;
  static const double _hitExpand = 20;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartH + _xLabelH,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final plotW = (w - _yAxisW).clamp(1.0, double.infinity);
          final plotH = _chartH - _plotTopPad - _plotBottomPad;

          final plotLeft = _yAxisW;
          final plotTop = _plotTopPad;

          double xForIndex(int i) => plotLeft + (i / 29.0) * plotW;
          double yForMood(double mood) {
            final t = (mood.clamp(1.0, 5.0) - 1.0) / 4.0;
            return plotTop + plotH - t * plotH;
          }

          final offsets = <Offset>[];
          for (final s in samples) {
            offsets.add(Offset(xForIndex(s.dayIndex), yForMood(s.moodAvg)));
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _chartH,
                child: CustomPaint(
                  size: Size(w, _chartH),
                  painter: _MoodTrendPainter(
                    plotRect: Rect.fromLTWH(plotLeft, plotTop, plotW, plotH),
                    points: offsets,
                    accent: AppTheme.accent,
                    accentLine: AppTheme.accentStrong,
                    fillAlpha: 0.15,
                    gridColor: AppTheme.border,
                    dotRadius: _dotR,
                  ),
                ),
              ),
              for (var i = 0; i < samples.length; i++)
                Positioned(
                  left: offsets[i].dx - _hitExpand,
                  top: offsets[i].dy - _hitExpand,
                  width: _hitExpand * 2,
                  height: _hitExpand * 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onPointTap(samples[i]),
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: _chartH,
                height: _xLabelH,
                child: CustomPaint(
                  painter: _XAxisLabelsPainter(
                    windowStart: windowStart,
                    plotLeft: plotLeft,
                    plotWidth: plotW,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 横向虚线网格 + 左侧 Y 刻度 + 折线 + 填充 + 圆点。
class _MoodTrendPainter extends CustomPainter {
  final Rect plotRect;
  final List<Offset> points;
  final Color accent;
  final Color accentLine;
  final double fillAlpha;
  final Color gridColor;
  final double dotRadius;

  _MoodTrendPainter({
    required this.plotRect,
    required this.points,
    required this.accent,
    required this.accentLine,
    required this.fillAlpha,
    required this.gridColor,
    required this.dotRadius,
  });

  static void _dashHLine(
    Canvas canvas,
    double y,
    double x1,
    double x2,
    Paint paint,
  ) {
    const dash = 4.0;
    const gap = 3.0;
    var x = x1;
    var draw = true;
    while (x < x2) {
      final seg = draw ? dash : gap;
      final xn = (x + seg).clamp(x1, x2);
      if (draw) {
        canvas.drawLine(Offset(x, y), Offset(xn, y), paint);
      }
      x = xn;
      draw = !draw;
    }
  }

  double _yAtMoodLevel(Rect r, int level) {
    final t = (level - 1) / 4.0;
    return r.bottom - t * r.height;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (var level = 1; level <= 5; level++) {
      final y = _yAtMoodLevel(plotRect, level);
      _dashHLine(canvas, y, plotRect.left, plotRect.right, gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$level',
          style: AppTextStyle.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((plotRect.left - tp.width) / 2, y - tp.height / 2),
      );
    }

    if (points.isEmpty) return;

    final fillPaint = Paint()..color = accent.withValues(alpha: fillAlpha);

    if (points.length == 1) {
      final p = points.first;
      const w = 10.0;
      final fillPath = Path()
        ..moveTo(p.dx - w, plotRect.bottom)
        ..lineTo(p.dx + w, plotRect.bottom)
        ..lineTo(p.dx, p.dy)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
    } else {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, plotRect.bottom);
      fillPath.lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, plotRect.bottom);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    if (points.length >= 2) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = accentLine
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }

    final dotFill = Paint()
      ..color = accent
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final dotRing = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    for (final p in points) {
      canvas.drawCircle(p, dotRadius, dotFill);
      canvas.drawCircle(p, dotRadius, dotRing);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    return oldDelegate.plotRect != plotRect ||
        !listEquals(oldDelegate.points, points) ||
        oldDelegate.accent != accent ||
        oldDelegate.accentLine != accentLine ||
        oldDelegate.fillAlpha != fillAlpha ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.dotRadius != dotRadius;
  }
}

/// X 轴：每 5 天一个刻度（0,5,10,15,20,25,29）。
class _XAxisLabelsPainter extends CustomPainter {
  final DateTime windowStart;
  final double plotLeft;
  final double plotWidth;

  _XAxisLabelsPainter({
    required this.windowStart,
    required this.plotLeft,
    required this.plotWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const indices = [0, 5, 10, 15, 20, 25, 29];
    for (final i in indices) {
      final d = windowStart.add(Duration(days: i));
      final x = plotLeft + (i / 29.0) * plotWidth;
      final tp = TextPainter(
        text: TextSpan(
          text: '${d.month}/${d.day}',
          style: AppTextStyle.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _XAxisLabelsPainter oldDelegate) {
    return oldDelegate.windowStart != windowStart ||
        oldDelegate.plotLeft != plotLeft ||
        oldDelegate.plotWidth != plotWidth;
  }
}
