import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/check_in.dart';
import '../models/milestone_progress.dart';
import '../services/database_service.dart';
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
  MilestoneProgress? _pendingMilestone;

  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);
  bool get isLoading => _isLoading;
  MilestoneProgress? get pendingMilestone => _pendingMilestone;

  bool isTodayChecked(String goalId) => _todayCheckedMap[goalId] ?? false;
  int getStreak(String goalId) => _streakMap[goalId] ?? 0;

  void clearPendingMilestone() => _pendingMilestone = null;

  Map<String, int> get checkInCountByDate {
    final result = <String, int>{};
    for (final checkIn in _checkIns) {
      if (checkIn.status == CheckInStatus.skipped) continue;
      result[checkIn.dateString] = (result[checkIn.dateString] ?? 0) + 1;
    }
    return result;
  }

  Map<String, CheckInStatus> get dateStatusMap {
    final byDate = <String, List<CheckIn>>{};
    for (final checkIn in _checkIns) {
      byDate.putIfAbsent(checkIn.dateString, () => []).add(checkIn);
    }

    final result = <String, CheckInStatus>{};
    for (final entry in byDate.entries) {
      final items = List<CheckIn>.from(entry.value)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (items.length == 1) {
        result[entry.key] = items.single.status;
        continue;
      }

      final statuses = items.map((item) => item.status).toSet();
      if (statuses.contains(CheckInStatus.done)) {
        result[entry.key] = CheckInStatus.done;
      } else if (statuses.contains(CheckInStatus.partial)) {
        result[entry.key] = CheckInStatus.partial;
      } else {
        result[entry.key] = CheckInStatus.skipped;
      }
    }

    return result;
  }

  bool get shouldShowReflectionGuide {
    final recent = _checkIns.take(10).toList();
    if (recent.length < 5) return false;
    final quickCount = recent
        .where((checkIn) => checkIn.mode == CheckInMode.quick)
        .length;
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
      log(
        '[CheckInProvider] loaded ${_checkIns.length} check-ins',
        name: 'CheckInProvider',
      );
      await _refreshTodayAndStreaks();
    } catch (e, s) {
      log(
        '[CheckInProvider] load failed: $e',
        name: 'CheckInProvider',
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshTodayAndStreaks() async {
    final goalIds = _checkIns.map((checkIn) => checkIn.goalId).toSet();
    for (final goalId in goalIds) {
      _todayCheckedMap[goalId] = await DatabaseService.hasCheckedInToday(
        goalId,
      );
      _streakMap[goalId] = await DatabaseService.getStreakDays(goalId);
    }
  }

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
    if (_todayCheckedMap[goalId] == true) {
      log(
        '[CheckInProvider] duplicate check-in prevented for $goalId',
        name: 'CheckInProvider',
      );
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

      final newStreak = await DatabaseService.getStreakDays(goalId);
      _streakMap[goalId] = newStreak;

      await _checkAndWriteMilestones(goalId, newStreak);
      await _gamification?.onAfterCheckInCommitted();

      notifyListeners();
      log(
        '[CheckInProvider] submitted check-in for $goalId, streak=$newStreak',
        name: 'CheckInProvider',
      );
      return checkIn;
    } catch (e, s) {
      log(
        '[CheckInProvider] submit failed: $e',
        name: 'CheckInProvider',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> _checkAndWriteMilestones(
    String goalId,
    int currentStreak,
  ) async {
    final existing = await DatabaseService.getMilestonesByGoal(goalId);

    for (final target in AppConstants.streakMilestones) {
      if (currentStreak < target) continue;

      final alreadyExists = existing.any(
        (milestone) =>
            milestone.type == MilestoneType.streak &&
            milestone.targetValue == target,
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

      if (_pendingMilestone == null ||
          target > _pendingMilestone!.targetValue) {
        _pendingMilestone = milestone;
      }

      log(
        '[CheckInProvider] unlocked milestone ${milestone.title}',
        name: 'CheckInProvider',
      );
    }
  }

  List<CheckIn> getCheckInsForGoal(String goalId) {
    return _checkIns.where((checkIn) => checkIn.goalId == goalId).toList();
  }

  List<CheckIn> searchCheckIns(String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<CheckIn>.from(_checkIns);
    }

    return _checkIns.where((checkIn) {
      final searchableValues = [
        checkIn.note,
        checkIn.reflectionProgress,
        checkIn.reflectionNext,
      ];
      return searchableValues.any(
        (value) => value != null && value.toLowerCase().contains(normalized),
      );
    }).toList();
  }

  List<CheckIn> filterByGoalIds(List<String> ids) {
    if (ids.isEmpty) {
      return List<CheckIn>.from(_checkIns);
    }

    final goalIds = ids.toSet();
    return _checkIns
        .where((checkIn) => goalIds.contains(checkIn.goalId))
        .toList();
  }

  Map<String, List<CheckIn>> get groupedByDate {
    final result = <String, List<CheckIn>>{};
    for (final checkIn in _checkIns) {
      result.putIfAbsent(checkIn.dateString, () => []).add(checkIn);
    }
    return result;
  }

  Set<String> getCheckedDateStrings(String goalId) {
    return _checkIns
        .where(
          (checkIn) =>
              checkIn.goalId == goalId &&
              checkIn.status != CheckInStatus.skipped,
        )
        .map((checkIn) => checkIn.dateString)
        .toSet();
  }

  Future<void> refreshGoalStatus(String goalId) async {
    _todayCheckedMap[goalId] = await DatabaseService.hasCheckedInToday(goalId);
    _streakMap[goalId] = await DatabaseService.getStreakDays(goalId);
    notifyListeners();
  }
}
