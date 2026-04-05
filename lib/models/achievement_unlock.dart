/// 已解锁成就（与表 `achievement_unlocks` 对应）。
class AchievementUnlock {
  final String achievementId;
  final DateTime unlockedAt;

  const AchievementUnlock({
    required this.achievementId,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
        'achievement_id': achievementId,
        'unlocked_at': unlockedAt.toIso8601String(),
      };

  factory AchievementUnlock.fromMap(Map<String, dynamic> map) {
    return AchievementUnlock(
      achievementId: map['achievement_id'] as String,
      unlockedAt: DateTime.parse(map['unlocked_at'] as String),
    );
  }
}
