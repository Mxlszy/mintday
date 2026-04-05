import 'season_summary.dart';

/// 已落库的赛季总结卡（表 `season_summaries`）。
class SeasonSummaryRecord {
  final String id;
  final SeasonSummaryCard card;
  final DateTime generatedAt;

  const SeasonSummaryRecord({
    required this.id,
    required this.card,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'season_id': card.seasonId,
        'season_index': card.seasonIndex,
        'window_start': card.windowStartInclusive.toIso8601String(),
        'window_end': card.windowEndInclusive.toIso8601String(),
        'goals_in_season_count': card.goalsInSeasonCount,
        'completion_rate': card.completionRate,
        'best_streak_days': card.bestStreakDays,
        'achievements_unlocked_count': card.achievementsUnlockedCount,
        'total_check_ins_in_window': card.totalCheckInsInWindow,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory SeasonSummaryRecord.fromMap(Map<String, dynamic> map) {
    final card = SeasonSummaryCard(
      seasonId: map['season_id'] as String,
      seasonIndex: (map['season_index'] as num).toInt(),
      windowStartInclusive: DateTime.parse(map['window_start'] as String),
      windowEndInclusive: DateTime.parse(map['window_end'] as String),
      goalsInSeasonCount: (map['goals_in_season_count'] as num).toInt(),
      completionRate: (map['completion_rate'] as num).toDouble(),
      bestStreakDays: (map['best_streak_days'] as num).toInt(),
      achievementsUnlockedCount:
          (map['achievements_unlocked_count'] as num).toInt(),
      totalCheckInsInWindow:
          (map['total_check_ins_in_window'] as num).toInt(),
    );
    return SeasonSummaryRecord(
      id: map['id'] as String,
      card: card,
      generatedAt: DateTime.parse(map['generated_at'] as String),
    );
  }
}
