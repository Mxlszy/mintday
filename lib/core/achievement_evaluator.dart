import '../models/achievement.dart';
import '../models/check_in.dart';
import '../models/goal.dart';

/// 成就判定所需的只读快照（由原始目标与打卡表构建）。
class AchievementEvaluationSnapshot {
  AchievementEvaluationSnapshot._({
    required this.activeGoals,
    required this.goalById,
    required this.nonSkipCheckIns,
    required this.globalMaxStreakDays,
    required this.maxSingleGoalStreak,
    required this.distinctCalendarDays,
    required this.totalNonSkipCount,
  });

  final List<Goal> activeGoals;
  final Map<String, Goal> goalById;
  final List<CheckIn> nonSkipCheckIns;
  final int globalMaxStreakDays;
  final int maxSingleGoalStreak;
  final int distinctCalendarDays;
  final int totalNonSkipCount;

  /// 从全量目标与打卡构建快照（建议在内存中复用，避免重复扫描）。
  factory AchievementEvaluationSnapshot.build({
    required List<Goal> goals,
    required List<CheckIn> checkIns,
  }) {
    final active = goals.where((g) => g.status == GoalStatus.active).toList();
    final goalById = {for (final g in goals) g.id: g};
    final nonSkip =
        checkIns.where((c) => c.status != CheckInStatus.skipped).toList();

    final globalDates = _uniqueSortedCalendarDates(nonSkip);
    final globalMax = _longestConsecutiveStreakDays(globalDates);

    var maxGoal = 0;
    final byGoal = <String, List<CheckIn>>{};
    for (final c in nonSkip) {
      byGoal.putIfAbsent(c.goalId, () => []).add(c);
    }
    for (final entry in byGoal.entries) {
      final streak = _longestConsecutiveStreakDays(
        _uniqueSortedCalendarDates(entry.value),
      );
      if (streak > maxGoal) maxGoal = streak;
    }

    return AchievementEvaluationSnapshot._(
      activeGoals: active,
      goalById: goalById,
      nonSkipCheckIns: nonSkip,
      globalMaxStreakDays: globalMax,
      maxSingleGoalStreak: maxGoal,
      distinctCalendarDays: globalDates.length,
      totalNonSkipCount: nonSkip.length,
    );
  }
}

/// 成就解锁判定（纯函数，无副作用）。
class AchievementEvaluator {
  AchievementEvaluator._();

  static bool isUnlocked(
    AchievementId id,
    AchievementEvaluationSnapshot s,
  ) {
    switch (id) {
      case AchievementId.timeEarlyBird:
        return s.nonSkipCheckIns.any((c) {
          final h = c.createdAt.hour;
          return h >= 5 && h < 8;
        });
      case AchievementId.timeNightOwl:
        return s.nonSkipCheckIns.any((c) {
          final h = c.createdAt.hour;
          return h >= 23 || h < 2;
        });
      case AchievementId.timeDeepNight:
        return s.nonSkipCheckIns.any((c) {
          final h = c.createdAt.hour;
          return h >= 2 && h < 5;
        });
      case AchievementId.timeNoon:
        return s.nonSkipCheckIns.any((c) {
          final h = c.createdAt.hour;
          return h >= 11 && h < 14;
        });
      case AchievementId.timeAfterWork:
        return s.nonSkipCheckIns.any((c) {
          final h = c.createdAt.hour;
          return h >= 18 && h < 21;
        });

      case AchievementId.streakGlobal3:
        return s.globalMaxStreakDays >= 3;
      case AchievementId.streakGlobal7:
        return s.globalMaxStreakDays >= 7;
      case AchievementId.streakGlobal14:
        return s.globalMaxStreakDays >= 14;
      case AchievementId.streakGlobal30:
        return s.globalMaxStreakDays >= 30;
      case AchievementId.streakGlobal60:
        return s.globalMaxStreakDays >= 60;
      case AchievementId.streakGlobal100:
        return s.globalMaxStreakDays >= 100;
      case AchievementId.goalStreak7:
        return s.maxSingleGoalStreak >= 7;
      case AchievementId.goalStreak30:
        return s.maxSingleGoalStreak >= 30;

      case AchievementId.perfectDayOnce:
        return _hasPerfectDay(s);
      case AchievementId.tripleCheckInDay:
        return _maxCheckInsOnSameCalendarDay(s) >= 3;
      case AchievementId.firstReflection:
        return s.nonSkipCheckIns.any((c) => c.mode == CheckInMode.reflection);
      case AchievementId.reflectionMode10:
        return s.nonSkipCheckIns
                .where((c) => c.mode == CheckInMode.reflection)
                .length >=
            10;
      case AchievementId.quickMode20:
        return s.nonSkipCheckIns.where((c) => c.mode == CheckInMode.quick).length >=
            20;
      case AchievementId.withPhoto:
        return s.nonSkipCheckIns.any((c) => c.imagePaths.isNotEmpty);
      case AchievementId.moodHighFive:
        return s.nonSkipCheckIns.where((c) => (c.mood ?? 0) >= 4).length >= 5;
      case AchievementId.categories3:
        return _distinctCategoriesTouched(s) >= 3;
      case AchievementId.totalCheckIns50:
        return s.totalNonSkipCount >= 50;
      case AchievementId.totalCheckIns200:
        return s.totalNonSkipCount >= 200;
      case AchievementId.lifetimeDistinctDays14:
        return s.distinctCalendarDays >= 14;
      case AchievementId.weekendCheckIn4:
        return s.nonSkipCheckIns
                .where((c) => _isWeekend(_calendarDate(c.date)))
                .length >=
            4;
      case AchievementId.partialBrave:
        return s.nonSkipCheckIns
                .where((c) => c.status == CheckInStatus.partial)
                .length >=
            5;
      case AchievementId.doubleReflectionDay:
        return _maxReflectionOnSameCalendarDay(s) >= 2;
    }
  }

  /// 当前数据下所有已满足的成就 ID。
  static Set<AchievementId> evaluateAllUnlocked(
    AchievementEvaluationSnapshot snapshot,
  ) {
    final out = <AchievementId>{};
    for (final def in AchievementCatalog.all) {
      if (isUnlocked(def.id, snapshot)) {
        out.add(def.id);
      }
    }
    return out;
  }

  /// 相对上次已解锁集合，本次新满足的成就（用于增量提示）。
  static List<AchievementId> newlyUnlocked({
    required AchievementEvaluationSnapshot snapshot,
    required Set<AchievementId> previouslyUnlocked,
  }) {
    final now = evaluateAllUnlocked(snapshot);
    final delta = now.difference(previouslyUnlocked);
    final list = delta.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}

DateTime _calendarDate(DateTime d) => DateTime(d.year, d.month, d.day);

List<DateTime> _uniqueSortedCalendarDates(List<CheckIn> list) {
  final set = <DateTime>{};
  for (final c in list) {
    set.add(_calendarDate(c.date));
  }
  final sorted = set.toList()..sort();
  return sorted;
}

/// 在已排序的唯一日历日上，最长连续天数。
int _longestConsecutiveStreakDays(List<DateTime> sortedUniqueDays) {
  if (sortedUniqueDays.isEmpty) return 0;
  var best = 1;
  var current = 1;
  for (var i = 1; i < sortedUniqueDays.length; i++) {
    final diff = sortedUniqueDays[i].difference(sortedUniqueDays[i - 1]).inDays;
    if (diff == 1) {
      current++;
      if (current > best) best = current;
    } else {
      current = 1;
    }
  }
  return best;
}

bool _isWeekend(DateTime day) {
  final w = day.weekday;
  return w == DateTime.saturday || w == DateTime.sunday;
}

bool _hasPerfectDay(AchievementEvaluationSnapshot s) {
  if (s.activeGoals.isEmpty) return false;
  final activeIds = s.activeGoals.map((g) => g.id).toSet();
  final byDay = <DateTime, Set<String>>{};
  for (final c in s.nonSkipCheckIns) {
    if (!activeIds.contains(c.goalId)) continue;
    final d = _calendarDate(c.date);
    byDay.putIfAbsent(d, () => <String>{}).add(c.goalId);
  }
  for (final entry in byDay.entries) {
    if (entry.value.length >= activeIds.length) return true;
  }
  return false;
}

int _maxCheckInsOnSameCalendarDay(AchievementEvaluationSnapshot s) {
  final byDay = <DateTime, int>{};
  for (final c in s.nonSkipCheckIns) {
    final d = _calendarDate(c.date);
    byDay[d] = (byDay[d] ?? 0) + 1;
  }
  var max = 0;
  for (final n in byDay.values) {
    if (n > max) max = n;
  }
  return max;
}

int _maxReflectionOnSameCalendarDay(AchievementEvaluationSnapshot s) {
  final byDay = <DateTime, int>{};
  for (final c in s.nonSkipCheckIns) {
    if (c.mode != CheckInMode.reflection) continue;
    final d = _calendarDate(c.date);
    byDay[d] = (byDay[d] ?? 0) + 1;
  }
  var max = 0;
  for (final n in byDay.values) {
    if (n > max) max = n;
  }
  return max;
}

int _distinctCategoriesTouched(AchievementEvaluationSnapshot s) {
  final cats = <GoalCategory>{};
  for (final c in s.nonSkipCheckIns) {
    final g = s.goalById[c.goalId];
    if (g != null) cats.add(g.category);
  }
  return cats.length;
}
