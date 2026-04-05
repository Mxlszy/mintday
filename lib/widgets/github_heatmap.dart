import 'package:flutter/material.dart';
import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';

class GithubHeatmap extends StatelessWidget {
  /// key: 'yyyy-MM-dd', value: check-in count for that day
  final Map<String, int> countByDate;
  final int weeksToShow;

  const GithubHeatmap({
    super.key,
    required this.countByDate,
    this.weeksToShow = 16,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build list of days from (weeksToShow * 7) ago to today
    final totalDays = weeksToShow * 7;
    // Pad to start on Monday
    final startRaw = today.subtract(Duration(days: totalDays - 1));
    final leadingDays = (startRaw.weekday - 1) % 7;
    final start = startRaw.subtract(Duration(days: leadingDays));

    final days = <DateTime>[];
    for (int i = 0; ; i++) {
      final d = start.add(Duration(days: i));
      if (d.isAfter(today)) break;
      days.add(d);
    }

    // Compute stats
    int total = countByDate.values.fold(0, (a, b) => a + b);
    int activeDays = countByDate.values.where((v) => v > 0).length;

    // Count columns (weeks)
    final colCount = (days.length / 7).ceil();

    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PixelIcon(
                    icon: PixelIcons.leaf,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('打卡热力图', style: AppTextStyle.label),
                ],
              ),
              Text(
                '$activeDays 天 · $total 次',
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildLegend(),
          const SizedBox(height: AppTheme.spacingS),
          _HeatmapGrid(
            days: days,
            countByDate: countByDate,
            today: today,
            colCount: colCount,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('少', style: AppTextStyle.caption.copyWith(fontSize: 10)),
        const SizedBox(width: 4),
        ...[0, 1, 2, 3].map((level) => Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _levelColor(level),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
        const SizedBox(width: 4),
        Text('多', style: AppTextStyle.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  /// 0 次空格色、1 次浅绿、2 次中绿、3 次及以上深绿
  static Color _levelColor(int level) {
    return switch (level) {
      0 => AppTheme.heatmapIntensity0,
      1 => AppTheme.heatmapIntensity1,
      2 => AppTheme.heatmapIntensity2,
      _ => AppTheme.heatmapIntensity4,
    };
  }

  static int _countToLevel(int count) {
    if (count <= 0) return 0;
    if (count == 1) return 1;
    if (count == 2) return 2;
    return 3;
  }

  static Color colorForCount(int count) => _levelColor(_countToLevel(count));
}

class _HeatmapGrid extends StatelessWidget {
  final List<DateTime> days;
  final Map<String, int> countByDate;
  final DateTime today;
  final int colCount;

  const _HeatmapGrid({
    required this.days,
    required this.countByDate,
    required this.today,
    required this.colCount,
  });

  @override
  Widget build(BuildContext context) {
    const cellSize = 12.0;
    const gap = 3.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(colCount, (col) {
          return Padding(
            padding: const EdgeInsets.only(right: gap),
            child: Column(
              children: List.generate(7, (row) {
                final idx = col * 7 + row;
                if (idx >= days.length) {
                  return SizedBox(
                    width: cellSize,
                    height: cellSize + gap,
                  );
                }
                final day = days[idx];
                final key =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final count = countByDate[key] ?? 0;
                final isToday = day == today;
                final isFuture = day.isAfter(today);

                return Padding(
                  padding: const EdgeInsets.only(bottom: gap),
                  child: Tooltip(
                    message: isFuture
                        ? ''
                        : count == 0
                            ? '${day.month}/${day.day} 暂无记录'
                            : '${day.month}/${day.day}  打卡 $count 次',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: isFuture
                            ? Colors.transparent
                            : GithubHeatmap.colorForCount(count),
                        borderRadius: BorderRadius.circular(2),
                        border: isToday
                            ? Border.all(
                                color: AppTheme.primary,
                                width: 1.5,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
