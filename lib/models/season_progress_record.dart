/// 当前赛季进度快照（表 `season_progress`，每次打卡后刷新）。
class SeasonProgressRecord {
  final String seasonId;
  final int seasonIndex;
  final DateTime windowStartInclusive;
  final DateTime windowEndInclusive;
  final double completionRate;
  final int bestStreakDays;
  final int checkInsInSeason;
  final int achievementsUnlockedInSeason;
  final DateTime updatedAt;

  const SeasonProgressRecord({
    required this.seasonId,
    required this.seasonIndex,
    required this.windowStartInclusive,
    required this.windowEndInclusive,
    required this.completionRate,
    required this.bestStreakDays,
    required this.checkInsInSeason,
    required this.achievementsUnlockedInSeason,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'season_id': seasonId,
        'season_index': seasonIndex,
        'window_start': windowStartInclusive.toIso8601String(),
        'window_end': windowEndInclusive.toIso8601String(),
        'completion_rate': completionRate,
        'best_streak_days': bestStreakDays,
        'check_ins_in_season': checkInsInSeason,
        'achievements_unlocked_in_season': achievementsUnlockedInSeason,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SeasonProgressRecord.fromMap(Map<String, dynamic> map) {
    return SeasonProgressRecord(
      seasonId: map['season_id'] as String,
      seasonIndex: (map['season_index'] as num).toInt(),
      windowStartInclusive: DateTime.parse(map['window_start'] as String),
      windowEndInclusive: DateTime.parse(map['window_end'] as String),
      completionRate: (map['completion_rate'] as num).toDouble(),
      bestStreakDays: (map['best_streak_days'] as num).toInt(),
      checkInsInSeason: (map['check_ins_in_season'] as num).toInt(),
      achievementsUnlockedInSeason:
          (map['achievements_unlocked_in_season'] as num).toInt(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
