import 'package:flutter/material.dart';

import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';

/// 单目标近 12 周打卡密度热力图（GitHub 式周列 × 7 行，像素方格 + 可点击）。
class GoalTwelveWeekHeatmap extends StatelessWidget {
  /// key: `yyyy-MM-dd`，value: 当日该目标非跳过打卡次数
  final Map<String, int> countByDate;

  /// 点击某个「已落在网格内的日历日」时回调（不含未来占位格）。
  final void Function(DateTime date)? onDayTap;

  const GoalTwelveWeekHeatmap({
    super.key,
    required this.countByDate,
    this.onDayTap,
  });

  static const int weeks = 12;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Color _levelColor(int level) {
    return switch (level) {
      0 => AppTheme.surfaceDeep,
      1 => AppTheme.heatmapIntensity1,
      2 => AppTheme.heatmapIntensity2,
      3 => AppTheme.heatmapIntensity3,
      _ => AppTheme.heatmapIntensity4,
    };
  }

  static int _countToLevel(int count) {
    if (count <= 0) return 0;
    if (count == 1) return 1;
    if (count == 2) return 2;
    if (count == 3) return 3;
    return 4;
  }

  static Color colorForCount(int count) => _levelColor(_countToLevel(count));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = weeks * 7;
    final startRaw = today.subtract(Duration(days: totalDays - 1));
    final leadingDays = (startRaw.weekday - 1) % 7;
    final start = startRaw.subtract(Duration(days: leadingDays));

    final days = <DateTime>[];
    for (var i = 0; ; i++) {
      final d = start.add(Duration(days: i));
      if (d.isAfter(today)) break;
      days.add(d);
    }

    final colCount = (days.length / 7).ceil();
    var total = 0;
    var activeDays = 0;
    for (final d in days) {
      final c = countByDate[_dateKey(d)] ?? 0;
      total += c;
      if (c > 0) activeDays++;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: AppTheme.neuSubtle,
      ),
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
                  Text('近 12 周热力', style: AppTextStyle.label),
                ],
              ),
              Text(
                '$activeDays 天有记录 · $total 次',
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          _legendRow(),
          const SizedBox(height: AppTheme.spacingM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(colCount, (col) {
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: List.generate(7, (row) {
                      final idx = col * 7 + row;
                      if (idx >= days.length) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: SizedBox(width: 14, height: 14),
                        );
                      }
                      final day = days[idx];
                      final key = _dateKey(day);
                      final count = countByDate[key] ?? 0;
                      final isToday = day == today;
                      final isFuture = day.isAfter(today);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _HeatCell(
                          count: count,
                          isToday: isToday,
                          isFuture: isFuture,
                          onTap: isFuture || onDayTap == null
                              ? null
                              : () => onDayTap!(DateTime(
                                    day.year,
                                    day.month,
                                    day.day,
                                  )),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '左滑查看更早 · 点格子查看当天',
            style: AppTextStyle.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('少', style: AppTextStyle.caption.copyWith(fontSize: 10)),
        const SizedBox(width: 4),
        ...List.generate(5, (level) {
          return Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _levelColor(level),
                border: Border.all(color: AppTheme.primary, width: 1),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text('多', style: AppTextStyle.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  final int count;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;

  const _HeatCell({
    required this.count,
    required this.isToday,
    required this.isFuture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 14.0;
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isFuture ? AppTheme.surfaceVariant : GoalTwelveWeekHeatmap.colorForCount(count),
        border: Border.all(
          color: isToday ? AppTheme.primary : AppTheme.textPrimary,
          width: isToday ? 2 : 1,
        ),
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
