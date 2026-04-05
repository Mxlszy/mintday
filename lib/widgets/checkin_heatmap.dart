import 'package:flutter/material.dart';

import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';
import '../models/check_in.dart';

/// 按自然月展示的打卡热力图（可切换月份）。
class CheckInHeatmap extends StatefulWidget {
  /// key: `yyyy-MM-dd`，value: 当日聚合 [CheckInStatus]（见 [CheckInProvider.dateStatusMap]）
  final Map<String, CheckInStatus> dateStatusMap;

  const CheckInHeatmap({
    super.key,
    required this.dateStatusMap,
  });

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 未打卡 / 跳过 / 部分 / 完成；今日且完成时为 [AppTheme.primary]。
  static Color colorForStatus({
    required bool isFuture,
    required bool isToday,
    CheckInStatus? status,
  }) {
    if (isFuture) return Colors.transparent;
    if (status == null) return AppTheme.heatmapCellEmpty;
    if (isToday && status == CheckInStatus.done) {
      return AppTheme.primary;
    }
    return switch (status) {
      CheckInStatus.skipped => AppTheme.heatmapCellSkipped,
      CheckInStatus.partial => AppTheme.heatmapCellPartial,
      CheckInStatus.done => AppTheme.heatmapCellDone,
    };
  }

  @override
  State<CheckInHeatmap> createState() => _CheckInHeatmapState();
}

class _CheckInHeatmapState extends State<CheckInHeatmap> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _visibleMonth = DateTime(n.year, n.month, 1);
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _currentMonthStart =>
      DateTime(_today.year, _today.month, 1);

  bool get _canGoNext => _visibleMonth.isBefore(_currentMonthStart);

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  /// 展示月内、且不超过「今天」的日历日数（用于完成率分母）。
  int _eligibleDaysInMonth() {
    final y = _visibleMonth.year;
    final m = _visibleMonth.month;
    final last = DateTime(y, m + 1, 0).day;
    if (DateTime(y, m) == DateTime(_today.year, _today.month)) {
      return _today.day;
    }
    if (DateTime(y, m).isBefore(DateTime(_today.year, _today.month))) {
      return last;
    }
    return 0;
  }

  /// 展示月内有打卡记录的日历日数（含跳过）。
  int _activeDaysInMonth() {
    final y = _visibleMonth.year;
    final m = _visibleMonth.month;
    final last = DateTime(y, m + 1, 0).day;
    var n = 0;
    for (var d = 1; d <= last; d++) {
      final day = DateTime(y, m, d);
      if (day.isAfter(_today)) break;
      final key = CheckInHeatmap._dateKey(day);
      if (widget.dateStatusMap.containsKey(key)) n++;
    }
    return n;
  }

  String _monthTitle() => '${_visibleMonth.year}年${_visibleMonth.month}月';

  Widget _buildHeader() {
    return Row(
      children: [
        _MonthNavButton(
          icon: Icons.chevron_left,
          onTap: _prevMonth,
        ),
        Expanded(
          child: Text(
            _monthTitle(),
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        _MonthNavButton(
          icon: Icons.chevron_right,
          onTap: _canGoNext ? _nextMonth : null,
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final hint = AppTextStyle.caption.copyWith(
      fontSize: 12,
      color: AppTheme.textHint,
    );
    Widget swatch(Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('跳过', style: hint),
        const SizedBox(width: 4),
        swatch(AppTheme.heatmapCellSkipped),
        Text(' · ', style: hint),
        Text('部分', style: hint),
        const SizedBox(width: 4),
        swatch(AppTheme.heatmapCellPartial),
        Text(' · ', style: hint),
        Text('完成', style: hint),
        const SizedBox(width: 4),
        swatch(AppTheme.heatmapCellDone),
      ],
    );
  }

  Widget _buildStatLine() {
    final checked = _activeDaysInMonth();
    if (checked == 0) {
      return Text(
        '本月暂无打卡记录',
        style: AppTextStyle.caption.copyWith(color: AppTheme.textSecondary),
      );
    }
    final denom = _eligibleDaysInMonth();
    final rate = denom <= 0
        ? 0
        : ((checked / denom) * 100).round().clamp(0, 100);
    return Text(
      '本月打卡 $checked 天 · 完成率 $rate%',
      style: AppTextStyle.caption.copyWith(
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PixelIcon(
                    icon: PixelIcons.leaf,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('打卡热力图', style: AppTextStyle.label),
                ],
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatLine(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildHeader(),
          const SizedBox(height: AppTheme.spacingM),
          _buildLegend(),
          const SizedBox(height: AppTheme.spacingS),
          _MonthHeatGrid(
            month: _visibleMonth,
            today: _today,
            dateStatusMap: widget.dateStatusMap,
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null ? AppTheme.textHint : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MonthHeatGrid extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final Map<String, CheckInStatus> dateStatusMap;

  const _MonthHeatGrid({
    required this.month,
    required this.today,
    required this.dateStatusMap,
  });

  @override
  Widget build(BuildContext context) {
    const cellSize = 12.0;
    const gap = 2.0;

    final y = month.year;
    final m = month.month;
    final first = DateTime(y, m, 1);
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final leading = (first.weekday - 1) % 7;
    final totalCells = leading + daysInMonth;
    final rowCount = (totalCells + 6) ~/ 7;

    final gridW = 7 * cellSize + 6 * gap;

    return SizedBox(
      width: gridW,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rowCount, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < rowCount - 1 ? gap : 0),
            child: Row(
              children: List.generate(7, (col) {
                final idx = row * 7 + col;
                if (idx < leading || idx >= leading + daysInMonth) {
                  return Padding(
                    padding: EdgeInsets.only(right: col < 6 ? gap : 0),
                    child: SizedBox(width: cellSize, height: cellSize),
                  );
                }
                final dayNum = idx - leading + 1;
                final day = DateTime(y, m, dayNum);
                final key = CheckInHeatmap._dateKey(day);
                final status = dateStatusMap[key];
                final isToday = day == today;
                final isFuture = day.isAfter(today);

                return Padding(
                  padding: EdgeInsets.only(right: col < 6 ? gap : 0),
                  child: _HeatCell(
                    day: day,
                    isToday: isToday,
                    isFuture: isFuture,
                    status: status,
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

class _HeatCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isFuture;
  final CheckInStatus? status;

  const _HeatCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.status,
  });

  String _tooltipMessage() {
    if (isFuture) return '';
    final prefix = '${day.month}/${day.day}';
    if (status == null) return '$prefix 暂无记录';
    return switch (status!) {
      CheckInStatus.skipped => '$prefix · 跳过',
      CheckInStatus.partial => '$prefix · 部分完成',
      CheckInStatus.done => '$prefix · 完成',
    };
  }

  @override
  Widget build(BuildContext context) {
    final fill = CheckInHeatmap.colorForStatus(
      isFuture: isFuture,
      isToday: isToday,
      status: status,
    );

    Border? border;
    if (!isFuture && isToday) {
      if (status == CheckInStatus.done) {
        border = Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        );
      } else {
        border = Border.all(color: AppTheme.primary, width: 1.5);
      }
    }

    return Tooltip(
      message: _tooltipMessage(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(2),
          border: border,
        ),
      ),
    );
  }
}
