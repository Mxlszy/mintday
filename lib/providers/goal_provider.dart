import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/season_rolling_utils.dart';
import '../models/goal.dart';
import '../services/database_service.dart';

class GoalProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => List.unmodifiable(_goals);
  List<Goal> get activeGoals =>
      _goals.where((g) => g.status == GoalStatus.active).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await loadGoals();
  }

  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await DatabaseService.getAllGoals();
      log('[GoalProvider] 加载目标: ${_goals.length} 条', name: 'GoalProvider');
    } catch (e, s) {
      _error = '加载失败，请重试';
      log(
        '[GoalProvider] 加载失败: $e',
        name: 'GoalProvider',
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建新目标
  Future<Goal?> createGoal({
    required String title,
    required GoalCategory category,
    String? reason,
    String? vision,
    DateTime? deadline,
    List<String> steps = const [],
    bool isPublic = false,
  }) async {
    try {
      final now = DateTime.now();
      final goal = Goal(
        id: _uuid.v4(),
        title: title,
        category: category,
        reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
        vision: vision?.trim().isEmpty == true ? null : vision?.trim(),
        deadline: deadline,
        steps: steps,
        completedSteps: List.filled(steps.length, false),
        status: GoalStatus.active,
        createdAt: now,
        updatedAt: now,
        isMintable: true,
        seasonId: SeasonRollingUtils.seasonIdAt(now),
        isPublic: isPublic,
        reward: '达成里程碑后可铸造成专属 NFT 纪念卡',
      );

      await DatabaseService.insertGoal(goal);
      _goals.insert(0, goal);
      notifyListeners();
      log('[GoalProvider] 创建目标: ${goal.title}', name: 'GoalProvider');
      return goal;
    } catch (e, s) {
      log(
        '[GoalProvider] 创建目标失败: $e',
        name: 'GoalProvider',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// 更新子步骤完成状态
  Future<bool> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) return false;

    final previous = _goals[index];
    final updated = goal.copyWith(updatedAt: DateTime.now());
    _goals[index] = updated;
    notifyListeners();

    try {
      await DatabaseService.updateGoal(updated);
      log('[GoalProvider] 更新目标: ${updated.title}', name: 'GoalProvider');
      return true;
    } catch (e, s) {
      _goals[index] = previous;
      notifyListeners();
      log(
        '[GoalProvider] 更新目标失败: $e',
        name: 'GoalProvider',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<void> toggleStep(String goalId, int stepIndex) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = _goals[index];
    if (stepIndex >= goal.completedSteps.length) return;

    final newCompleted = List<bool>.from(goal.completedSteps);
    newCompleted[stepIndex] = !newCompleted[stepIndex];

    final updated = goal.copyWith(
      completedSteps: newCompleted,
      updatedAt: DateTime.now(),
    );

    _goals[index] = updated;
    notifyListeners();

    try {
      await DatabaseService.updateGoal(updated);
    } catch (e) {
      // 回滚
      _goals[index] = goal;
      notifyListeners();
    }
  }

  /// 标记目标为完成
  Future<void> completeGoal(String goalId) async {
    await _updateStatus(goalId, GoalStatus.completed);
  }

  /// 归档目标
  Future<void> archiveGoal(String goalId) async {
    await _updateStatus(goalId, GoalStatus.archived);
  }

  Future<void> _updateStatus(String goalId, GoalStatus status) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = _goals[index];
    final updated = goal.copyWith(status: status, updatedAt: DateTime.now());
    _goals[index] = updated;
    notifyListeners();

    try {
      await DatabaseService.updateGoal(updated);
    } catch (e) {
      _goals[index] = goal;
      notifyListeners();
    }
  }

  /// 删除目标
  Future<void> deleteGoal(String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = _goals[index];
    _goals.removeAt(index);
    notifyListeners();

    try {
      await DatabaseService.deleteGoal(goalId);
    } catch (e) {
      _goals.insert(index, goal);
      notifyListeners();
    }
  }

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
