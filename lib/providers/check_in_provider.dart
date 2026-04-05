import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/check_in.dart';
import '../models/milestone_progress.dart';
import '../services/database_service.dart';
import '../core/constants.dart';
import 'gamification_provider.dart';

class CheckInProvider extends ChangeNotifier {
  CheckInProvider({GamificationProvider? gamification})
      : _gamification = gamification;

  final GamificationProvider? _gamification;
  final _uuid = const Uuid();

  List<CheckIn> _checkIns = [];
  final Map<String, bool> _todayCheckedMap = {};
  final Map<String, int> _streakMap = {};

  bool _isLoading = false;

  /// 最近一次解锁的里程碑（用于弹窗展示，展示后调用 clearPendingMilestone）
  MilestoneProgress? _pendingMilestone;
  MilestoneProgress? get pendingMilestone => _pendingMilestone;
  void clearPendingMilestone() => _pendingMilestone = null;

  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);
  bool get isLoading => _isLoading;

  bool isTodayChecked(String goalId) => _todayCheckedMap[goalId] ?? false;
  int getStreak(String goalId) => _streakMap[goalId] ?? 0;

  /// 每日期打卡次数（热力图、统计）
  Map<String, int> get checkInCountByDate {
    final Map<String, int> result = {};
    for (final checkIn in _checkIns) {
      if (checkIn.status != CheckInStatus.skipped) {
        result[checkIn.dateString] =
            (result[checkIn.dateString] ?? 0) + 1;
      }
    }
    return result;
  }

  /// 每个日历日一条聚合状态（用于月历热力图）。
  /// 单日仅一条记录时用其 status；同日多条时取 done > partial > skipped。
  Map<String, CheckInStatus> get dateStatusMap {
    final byDate = <String, List<CheckIn>>{};
    for (final c in _checkIns) {
      byDate.putIfAbsent(c.dateString, () => []).add(c);
    }
    final out = <String, CheckInStatus>{};
    for (final e in byDate.entries) {
      final list = List<CheckIn>.from(e.value)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (list.length == 1) {
        out[e.key] = list.single.status;
        continue;
      }
      final set = list.map((c) => c.status).toSet();
      if (set.contains(CheckInStatus.done)) {
        out[e.key] = CheckInStatus.done;
      } else if (set.contains(CheckInStatus.partial)) {
        out[e.key] = CheckInStatus.partial;
      } else {
        out[e.key] = CheckInStatus.skipped;
      }
    }
    return out;
  }

  /// 最近 10 条记录中快速打卡占多数时，提示用户体验反思模式
  bool get shouldShowReflectionGuide {
    final recent = _checkIns.take(10).toList();
    if (recent.length < 5) return false;
    final quickCount = recent.where((c) => c.mode == CheckInMode.quick).length;
    return quickCount >= 5;
  }

  Future<void> init() async {
    await loadCheckIns();
  }

  Future<void> loadCheckIns() async {
    _isLoading = true;
    notifyListeners();

    try {
      _checkIns = await DatabaseService.getAllCheckIns();
      log('[CheckInProvider] 加载打卡: ${_checkIns.length} 条',
          name: 'CheckInProvider');
      await _refreshTodayAndStreaks();
    } catch (e, s) {
      log('[CheckInProvider] 加载失败: $e',
          name: 'CheckInProvider', error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshTodayAndStreaks() async {
    // 获取所有活跃目标的 goalId
    final goalIds = _checkIns.map((c) => c.goalId).toSet();
    for (final goalId in goalIds) {
      _todayCheckedMap[goalId] =
          await DatabaseService.hasCheckedInToday(goalId);
      _streakMap[goalId] = await DatabaseService.getStreakDays(goalId);
    }
  }

  /// 提交打卡
  Future<CheckIn?> submitCheckIn({
    required String goalId,
    required CheckInMode mode,
    required CheckInStatus status,
    int? mood,
    int? duration,
    String? note,
    String? reflectionProgress,
    String? reflectionBlocker,
    String? reflectionNext,
    List<String> imagePaths = const [],
  }) async {
    // 防止重复打卡
    if (_todayCheckedMap[goalId] == true) {
      log('[CheckInProvider] 今日已打卡: $goalId', name: 'CheckInProvider');
      return null;
    }

    try {
      final now = DateTime.now();
      final checkIn = CheckIn(
        id: _uuid.v4(),
        goalId: goalId,
        date: now,
        mode: mode,
        status: status,
        mood: mood,
        duration: duration,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        reflectionProgress: reflectionProgress?.trim().isEmpty == true
            ? null
            : reflectionProgress?.trim(),
        reflectionBlocker: reflectionBlocker?.trim().isEmpty == true
            ? null
            : reflectionBlocker?.trim(),
        reflectionNext: reflectionNext?.trim().isEmpty == true
            ? null
            : reflectionNext?.trim(),
        imagePaths: imagePaths,
        createdAt: now,
      );

      await DatabaseService.insertCheckIn(checkIn);
      _checkIns.insert(0, checkIn);
      _todayCheckedMap[goalId] = true;

      // 更新连续天数
      final newStreak = await DatabaseService.getStreakDays(goalId);
      _streakMap[goalId] = newStreak;

      // 静默检测并写入里程碑
      await _checkAndWriteMilestones(goalId, newStreak);

      // 成就判定、赛季进度与跨赛季总结落库
      await _gamification?.onAfterCheckInCommitted();

      notifyListeners();
      log('[CheckInProvider] 打卡成功: goalId=$goalId, streak=$newStreak',
          name: 'CheckInProvider');
      return checkIn;
    } catch (e, s) {
      log('[CheckInProvider] 打卡失败: $e',
          name: 'CheckInProvider', error: e, stackTrace: s);
      return null;
    }
  }

  /// 检测里程碑，首次解锁时写入 DB 并设置 pendingMilestone 供 UI 展示
  Future<void> _checkAndWriteMilestones(
      String goalId, int currentStreak) async {
    final existing = await DatabaseService.getMilestonesByGoal(goalId);

    for (final target in AppConstants.streakMilestones) {
      if (currentStreak < target) continue;

      final alreadyExists = existing.any(
        (m) => m.type == MilestoneType.streak && m.targetValue == target,
      );
      if (alreadyExists) continue;

      final milestone = MilestoneProgress(
        id: _uuid.v4(),
        goalId: goalId,
        type: MilestoneType.streak,
        title: MilestonePresets.streakTitle(target),
        description: MilestonePresets.streakDescription(target),
        targetValue: target,
        currentValue: currentStreak,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await DatabaseService.insertMilestone(milestone);

      // 只保留最高级别里程碑用于本次弹窗（取 target 最大的）
      if (_pendingMilestone == null ||
          target > (_pendingMilestone!.targetValue)) {
        _pendingMilestone = milestone;
      }
      log('[CheckInProvider] 解锁里程碑: ${milestone.title}',
          name: 'CheckInProvider');
    }
  }

  /// 获取某目标的所有打卡记录
  List<CheckIn> getCheckInsForGoal(String goalId) {
    return _checkIns.where((c) => c.goalId == goalId).toList();
  }

  /// 按日期分组的打卡记录（用于历史页）
  Map<String, List<CheckIn>> get groupedByDate {
    final Map<String, List<CheckIn>> result = {};
    for (final checkIn in _checkIns) {
      final key = checkIn.dateString;
      result.putIfAbsent(key, () => []).add(checkIn);
    }
    return result;
  }

  /// 某目标的打卡日期集合（用于热力图）
  Set<String> getCheckedDateStrings(String goalId) {
    return _checkIns
        .where((c) => c.goalId == goalId && c.status != CheckInStatus.skipped)
        .map((c) => c.dateString)
        .toSet();
  }

  /// 刷新单个目标的今日状态和连续天数
  Future<void> refreshGoalStatus(String goalId) async {
    _todayCheckedMap[goalId] =
        await DatabaseService.hasCheckedInToday(goalId);
    _streakMap[goalId] = await DatabaseService.getStreakDays(goalId);
    notifyListeners();
  }
}
