import '../models/check_in.dart';
import '../models/goal.dart';
import '../models/season_summary.dart';

/// 以固定锚点划分的「每赛季连续 30 个日历日」工具（与 [AppUtils] 相同为纯静态方法）。
///
/// 约定：
/// - 第 0 赛季：锚点当日开始的连续 30 天（含首尾共 30 个日历日）。
/// - 第 n 赛季：锚点 + 30n 天起的连续 30 天。
/// - `seasonId` 与 [Goal.seasonId] 对齐，格式：`s30_<index>`。
class SeasonRollingUtils {
  SeasonRollingUtils._();

  /// 默认锚点（本地日历日）；产品可改为用户首次启动日或配置下发。
  static final DateTime defaultAnchorDate = DateTime(2024, 1, 1);
  static const int defaultSeasonLengthDays = 30;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _resolvedAnchor(DateTime? anchor) =>
      _dateOnly(anchor ?? defaultAnchorDate);

  /// 稳定赛季 ID，可写入 [Goal.seasonId]。
  static String seasonIdForIndex(int index) => 's30_$index';

  static int? tryParseSeasonIndex(String? seasonId) {
    if (seasonId == null || !seasonId.startsWith('s30_')) return null;
    return int.tryParse(seasonId.substring(4));
  }

  /// 自锚点起经过的整天数（`day` 与 `anchor` 均取日期部分）。
  static int daysSinceAnchor(
    DateTime day, {
    DateTime? anchor,
  }) {
    final a = _resolvedAnchor(anchor);
    final b = _dateOnly(day);
    return b.difference(a).inDays;
  }

  /// `at` 所在赛季序号（锚点之前一律视为 0，避免负数赛季）。
  static int seasonIndexAt(
    DateTime at, {
    DateTime? anchor,
    int seasonLengthDays = defaultSeasonLengthDays,
  }) {
    final d = daysSinceAnchor(at, anchor: anchor);
    if (d < 0) return 0;
    return d ~/ seasonLengthDays;
  }

  static String seasonIdAt(
    DateTime at, {
    DateTime? anchor,
    int seasonLengthDays = defaultSeasonLengthDays,
  }) {
    return seasonIdForIndex(
      seasonIndexAt(at, anchor: anchor, seasonLengthDays: seasonLengthDays),
    );
  }

  /// 第 [index] 个赛季的起止日（含），均为本地日历日 0 点。
  static SeasonWindow windowForIndex(
    int index, {
    DateTime? anchor,
    int seasonLengthDays = defaultSeasonLengthDays,
  }) {
    final anc = _resolvedAnchor(anchor);
    final start =
        anc.add(Duration(days: index * seasonLengthDays));
    final end = start.add(Duration(days: seasonLengthDays - 1));
    return SeasonWindow(
      index: index,
      seasonId: seasonIdForIndex(index),
      startInclusive: start,
      endInclusive: end,
    );
  }

  static SeasonWindow windowContaining(
    DateTime at, {
    DateTime? anchor,
    int seasonLengthDays = defaultSeasonLengthDays,
  }) {
    return windowForIndex(
      seasonIndexAt(at, anchor: anchor, seasonLengthDays: seasonLengthDays),
      anchor: anchor,
      seasonLengthDays: seasonLengthDays,
    );
  }

  /// `at` 的日期部分是否已晚于该赛季窗口结束日。
  static bool isPastSeasonEnd(
    int seasonIndex,
    DateTime at, {
    DateTime? anchor,
    int seasonLengthDays = defaultSeasonLengthDays,
  }) {
    final w = windowForIndex(seasonIndex,
        anchor: anchor, seasonLengthDays: seasonLengthDays);
    return _dateOnly(at).isAfter(w.endInclusive);
  }

  /// 生成赛季总结卡数据。
  ///
  /// [achievementsUnlockedInSeason]：该赛季窗口内解锁的成就数量（由持久化层统计）。
  static SeasonSummaryCard buildSeasonSummary({
    required int seasonIndex,
    required List<Goal> goals,
    required List<CheckIn> checkIns,
    int achievementsUnlockedInSeason = 0,
    DateTime? anchor,
    int seasonLengthDays = defaultSeasonLengthDays,
  }) {
    final window = windowForIndex(seasonIndex,
        anchor: anchor, seasonLengthDays: seasonLengthDays);
    final inWindow =
        checkIns.where((c) => _isDateInWindow(c.date, window)).toList();
    final nonSkip =
        inWindow.where((c) => c.status != CheckInStatus.skipped).toList();

    var scopedGoals =
        goals.where((g) => g.seasonId == window.seasonId).toList();

    if (scopedGoals.isEmpty) {
      final ids = nonSkip.map((c) => c.goalId).toSet();
      scopedGoals = goals.where((g) => ids.contains(g.id)).toList();
    }
    if (scopedGoals.isEmpty) {
      scopedGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    }

    final goalIds = scopedGoals.map((g) => g.id).toSet();
    final rate = _averageDailyCompletionRate(
      window: window,
      goalIds: goalIds,
      nonSkipInWindow: nonSkip,
      seasonLengthDays: seasonLengthDays,
    );
    final streak = _bestStreakInWindow(
      window: window,
      nonSkipInWindow: nonSkip,
      goalIds: goalIds,
    );

    return SeasonSummaryCard(
      seasonId: window.seasonId,
      seasonIndex: seasonIndex,
      windowStartInclusive: window.startInclusive,
      windowEndInclusive: window.endInclusive,
      goalsInSeasonCount: goalIds.length,
      completionRate: rate,
      bestStreakDays: streak,
      achievementsUnlockedCount: achievementsUnlockedInSeason,
      totalCheckInsInWindow: nonSkip.length,
    );
  }

  static double _averageDailyCompletionRate({
    required SeasonWindow window,
    required Set<String> goalIds,
    required List<CheckIn> nonSkipInWindow,
    required int seasonLengthDays,
  }) {
    if (goalIds.isEmpty) return 0;

    final byDay = <DateTime, Set<String>>{};
    for (final c in nonSkipInWindow) {
      if (!goalIds.contains(c.goalId)) continue;
      final d = _dateOnly(c.date);
      byDay.putIfAbsent(d, () => <String>{}).add(c.goalId);
    }

    var sum = 0.0;
    final n = seasonLengthDays;
    for (var i = 0; i < n; i++) {
      final day = window.startInclusive.add(Duration(days: i));
      final done = byDay[day]?.length ?? 0;
      sum += done / goalIds.length;
    }
    return sum / n;
  }

  static int _bestStreakInWindow({
    required SeasonWindow window,
    required List<CheckIn> nonSkipInWindow,
    required Set<String> goalIds,
  }) {
    final days = <DateTime>{};
    for (final c in nonSkipInWindow) {
      if (!goalIds.contains(c.goalId)) continue;
      final d = _dateOnly(c.date);
      if (_isDateInWindow(d, window)) days.add(d);
    }
    if (days.isEmpty) return 0;

    final sorted = days.toList()..sort();
    var best = 1;
    var cur = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
    }
    return best;
  }

  static bool _isDateInWindow(DateTime day, SeasonWindow window) {
    final d = _dateOnly(day);
    return !d.isBefore(window.startInclusive) &&
        !d.isAfter(window.endInclusive);
  }
}

class SeasonWindow {
  const SeasonWindow({
    required this.index,
    required this.seasonId,
    required this.startInclusive,
    required this.endInclusive,
  });

  final int index;
  final String seasonId;
  final DateTime startInclusive;
  final DateTime endInclusive;
}
