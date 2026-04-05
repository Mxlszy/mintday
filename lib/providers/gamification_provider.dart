import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/achievement_evaluator.dart';
import '../core/season_rolling_utils.dart';
import '../models/achievement.dart';
import '../models/check_in.dart';
import '../models/goal.dart';
import '../models/season_progress_record.dart';
import '../models/season_summary_record.dart';
import '../services/database_service.dart';

/// 成就判定、赛季进度快照与赛季总结落库（打卡成功后由 [CheckInProvider] 驱动）。
class GamificationProvider extends ChangeNotifier {
  static const _name = 'GamificationProvider';
  static const _prefLastSeasonIndex = 'mintday_gamification_last_season_index';

  final _uuid = const Uuid();

  Set<String> _unlockedAchievementSlugs = {};
  List<AchievementId> _pendingAchievementUnlocks = [];
  SeasonProgressRecord? _currentSeasonProgress;
  List<SeasonSummaryRecord> _seasonSummaries = [];

  Set<String> get unlockedAchievementSlugs =>
      Set.unmodifiable(_unlockedAchievementSlugs);

  /// 本轮打卡周期内新写入库的成就（供后续 UI 消费，展示后调用 [clearPendingAchievements]）。
  List<AchievementId> get pendingAchievementUnlocks =>
      List.unmodifiable(_pendingAchievementUnlocks);

  SeasonProgressRecord? get currentSeasonProgress => _currentSeasonProgress;

  List<SeasonSummaryRecord> get seasonSummaries =>
      List.unmodifiable(_seasonSummaries);

  Future<void> init() async {
    await refreshFromDatabase();
  }

  /// 从数据库刷新成就与赛季缓存（不推进赛季游标、不生成历史总结）。
  Future<void> refreshFromDatabase() async {
    try {
      final goals = await DatabaseService.getAllGoals();
      final checkIns = await DatabaseService.getAllCheckIns();
      await _syncAchievements(goals, checkIns, silent: true);
      await _recomputeAndPersistCurrentSeasonProgress(goals, checkIns);
      _seasonSummaries = await DatabaseService.getSeasonSummaries(limit: 50);
      log('[$_name] 刷新完成: 成就=${_unlockedAchievementSlugs.length}, '
          '赛季总结=${_seasonSummaries.length}',
          name: _name);
      notifyListeners();
    } catch (e, s) {
      log('[$_name] refreshFromDatabase 失败: $e',
          name: _name, error: e, stackTrace: s);
    }
  }

  /// 打卡已成功写入 DB 后调用：成就解锁、跨赛季总结、当前赛季进度快照。
  Future<void> onAfterCheckInCommitted() async {
    try {
      final goals = await DatabaseService.getAllGoals();
      final checkIns = await DatabaseService.getAllCheckIns();

      await _syncAchievements(goals, checkIns);

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final nowIndex = SeasonRollingUtils.seasonIndexAt(now);
      final lastRaw = prefs.getInt(_prefLastSeasonIndex);

      if (lastRaw != null && nowIndex > lastRaw) {
        log('[$_name] 检测到赛季推进: $lastRaw → $nowIndex，生成中间赛季总结',
            name: _name);
        for (var s = lastRaw; s < nowIndex; s++) {
          await _persistSeasonSummaryIfNeeded(s, goals, checkIns);
        }
      }

      await prefs.setInt(_prefLastSeasonIndex, nowIndex);

      await _recomputeAndPersistCurrentSeasonProgress(goals, checkIns);
      _seasonSummaries = await DatabaseService.getSeasonSummaries(limit: 50);

      log('[$_name] 打卡后同步完成: 待展示成就=${_pendingAchievementUnlocks.length}',
          name: _name);
      notifyListeners();
    } catch (e, s) {
      log('[$_name] onAfterCheckInCommitted 失败: $e',
          name: _name, error: e, stackTrace: s);
    }
  }

  void clearPendingAchievements() {
    _pendingAchievementUnlocks = [];
    notifyListeners();
  }

  Future<void> _syncAchievements(
    List<Goal> goals,
    List<CheckIn> checkIns, {
    bool silent = false,
  }) async {
    final snapshot = AchievementEvaluationSnapshot.build(
      goals: goals,
      checkIns: checkIns,
    );
    final shouldUnlock = AchievementEvaluator.evaluateAllUnlocked(snapshot);

    _unlockedAchievementSlugs =
        await DatabaseService.getAllUnlockedAchievementIds();

    final pending = <AchievementId>[];
    final now = DateTime.now();

    for (final id in shouldUnlock) {
      if (_unlockedAchievementSlugs.contains(id.name)) continue;
      final inserted = await DatabaseService.insertAchievementUnlockIfAbsent(
        id.name,
        now,
      );
      if (inserted) {
        _unlockedAchievementSlugs.add(id.name);
        pending.add(id);
      }
    }

    pending.sort((a, b) => a.name.compareTo(b.name));
    _pendingAchievementUnlocks = silent ? [] : pending;

    if (!silent && pending.isNotEmpty) {
      log('[$_name] 新解锁成就: ${pending.map((e) => e.name).join(', ')}',
          name: _name);
    }
  }

  Future<void> _persistSeasonSummaryIfNeeded(
    int seasonIndex,
    List<Goal> goals,
    List<CheckIn> checkIns,
  ) async {
    if (await DatabaseService.hasSeasonSummaryForSeasonIndex(seasonIndex)) {
      return;
    }

    final window = SeasonRollingUtils.windowForIndex(seasonIndex);
    final endExclusive = window.endInclusive.add(const Duration(days: 1));
    final achCount = await DatabaseService.countAchievementUnlocksBetween(
      window.startInclusive,
      endExclusive,
    );

    final card = SeasonRollingUtils.buildSeasonSummary(
      seasonIndex: seasonIndex,
      goals: goals,
      checkIns: checkIns,
      achievementsUnlockedInSeason: achCount,
    );

    final record = SeasonSummaryRecord(
      id: _uuid.v4(),
      card: card,
      generatedAt: DateTime.now(),
    );

    await DatabaseService.insertSeasonSummaryIfAbsent(record);
  }

  Future<void> _recomputeAndPersistCurrentSeasonProgress(
    List<Goal> goals,
    List<CheckIn> checkIns,
  ) async {
    final now = DateTime.now();
    final nowIndex = SeasonRollingUtils.seasonIndexAt(now);
    final window = SeasonRollingUtils.windowForIndex(nowIndex);
    final endExclusive = window.endInclusive.add(const Duration(days: 1));
    final achCount = await DatabaseService.countAchievementUnlocksBetween(
      window.startInclusive,
      endExclusive,
    );

    final summary = SeasonRollingUtils.buildSeasonSummary(
      seasonIndex: nowIndex,
      goals: goals,
      checkIns: checkIns,
      achievementsUnlockedInSeason: achCount,
    );

    final record = SeasonProgressRecord(
      seasonId: summary.seasonId,
      seasonIndex: summary.seasonIndex,
      windowStartInclusive: summary.windowStartInclusive,
      windowEndInclusive: summary.windowEndInclusive,
      completionRate: summary.completionRate,
      bestStreakDays: summary.bestStreakDays,
      checkInsInSeason: summary.totalCheckInsInWindow,
      achievementsUnlockedInSeason: achCount,
      updatedAt: DateTime.now(),
    );

    await DatabaseService.upsertSeasonProgress(record);
    _currentSeasonProgress = record;
  }
}
