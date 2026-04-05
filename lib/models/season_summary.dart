/// 单个 30 天滚动赛季结束时的总结卡数据（供后续 UI / 上链展示）。
class SeasonSummaryCard {
  /// 与 [Goal.seasonId] 对齐的赛季标识。
  final String seasonId;

  /// 赛季序号（自锚点起的第 N 个 30 日窗，0-based）。
  final int seasonIndex;

  /// 赛季窗口起始日（含），本地日历日 0 点语义由调用方与时区约定。
  final DateTime windowStartInclusive;

  /// 赛季窗口结束日（含）。
  final DateTime windowEndInclusive;

  /// 参与统计的目标数量。
  final int goalsInSeasonCount;

  /// 日均完成率：赛季窗口内，每个日历日的「已打卡目标数 / 当日应统计目标数」之算术平均，范围 [0,1]。
  /// 若应统计目标数为 0，则为 0。
  final double completionRate;

  /// 赛季窗口内，「至少完成过一次非跳过打卡」的连续日历日最大长度。
  final int bestStreakDays;

  /// 该赛季周期内新解锁的成就数量（由上层传入解锁事件或持久化结果汇总）。
  final int achievementsUnlockedCount;

  /// 该赛季窗口内非跳过打卡总次数。
  final int totalCheckInsInWindow;

  const SeasonSummaryCard({
    required this.seasonId,
    required this.seasonIndex,
    required this.windowStartInclusive,
    required this.windowEndInclusive,
    required this.goalsInSeasonCount,
    required this.completionRate,
    required this.bestStreakDays,
    required this.achievementsUnlockedCount,
    required this.totalCheckInsInWindow,
  });

  Map<String, dynamic> toJson() => {
        'season_id': seasonId,
        'season_index': seasonIndex,
        'window_start': windowStartInclusive.toIso8601String(),
        'window_end': windowEndInclusive.toIso8601String(),
        'goals_in_season_count': goalsInSeasonCount,
        'completion_rate': completionRate,
        'best_streak_days': bestStreakDays,
        'achievements_unlocked_count': achievementsUnlockedCount,
        'total_check_ins_in_window': totalCheckInsInWindow,
      };
}
