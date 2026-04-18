import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_item.dart';
import '../services/database_service.dart';

class TodoProgress {
  const TodoProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  int get remaining => total - completed;
  double get ratio => total == 0 ? 0 : completed / total;
  bool get isEmpty => total == 0;
  bool get isCompleted => total > 0 && completed == total;
  String get label => '$completed/$total 已完成';

  factory TodoProgress.fromItems(List<TodoItem> items) {
    final completed = items.where((item) => item.isCompleted).length;
    return TodoProgress(completed: completed, total: items.length);
  }
}

class TodoProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  final Map<String, List<TodoItem>> _todosByGoalDate = {};
  final Map<String, List<TodoItem>> _todosByDate = {};
  final Map<String, String> _activeDateByGoal = {};
  final Set<String> _loadingGoalDates = {};
  final Set<String> _loadingDates = {};

  bool _isInitialized = false;

  bool get isLoadingToday => _loadingDates.contains(_dateKey(DateTime.now()));

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await loadTodosForDate(DateTime.now(), force: true);
  }

  List<TodoItem> getTodos(String goalId, DateTime date) {
    final key = _goalDateKey(goalId, _dateKey(date));
    return List.unmodifiable(_todosByGoalDate[key] ?? const <TodoItem>[]);
  }

  List<TodoItem> getTodosForDate(DateTime date) {
    final key = _dateKey(date);
    return List.unmodifiable(_todosByDate[key] ?? const <TodoItem>[]);
  }

  TodoProgress todayProgress(String goalId) {
    return progressFor(goalId, DateTime.now());
  }

  TodoProgress progressFor(String goalId, DateTime date) {
    final dateKey = _dateKey(date);
    final goalDateKey = _goalDateKey(goalId, dateKey);
    final items =
        _todosByGoalDate[goalDateKey] ??
        _todosByDate[dateKey]
            ?.where((item) => item.goalId == goalId)
            .toList() ??
        const <TodoItem>[];
    return TodoProgress.fromItems(items);
  }

  bool isLoadingGoalDate(String goalId, DateTime date) {
    return _loadingGoalDates.contains(_goalDateKey(goalId, _dateKey(date)));
  }

  Future<void> loadTodos(
    String goalId,
    DateTime date, {
    bool force = false,
  }) async {
    final dateKey = _dateKey(date);
    final cacheKey = _goalDateKey(goalId, dateKey);
    _activeDateByGoal[goalId] = dateKey;

    if (!force && _todosByGoalDate.containsKey(cacheKey)) {
      notifyListeners();
      return;
    }
    if (_loadingGoalDates.contains(cacheKey)) return;

    _loadingGoalDates.add(cacheKey);
    notifyListeners();

    try {
      final todos = await DatabaseService.getTodoItemsByGoalAndDate(
        goalId,
        dateKey,
      );
      _todosByGoalDate[cacheKey] = List<TodoItem>.from(todos)
        ..sort(_compareWithinGoal);
      _replaceGoalItemsInDateCache(goalId, dateKey, todos);
      log(
        '[TodoProvider] loaded ${todos.length} todos for goal=$goalId date=$dateKey',
        name: 'TodoProvider',
      );
    } catch (error, stackTrace) {
      log(
        '[TodoProvider] loadTodos failed: $error',
        name: 'TodoProvider',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _loadingGoalDates.remove(cacheKey);
      notifyListeners();
    }
  }

  Future<void> loadTodosForDate(DateTime date, {bool force = false}) async {
    final dateKey = _dateKey(date);
    if (!force && _todosByDate.containsKey(dateKey)) return;
    if (_loadingDates.contains(dateKey)) return;

    _loadingDates.add(dateKey);
    notifyListeners();

    try {
      final todos = await DatabaseService.getTodoItemsByDate(dateKey);
      _todosByDate[dateKey] = List<TodoItem>.from(todos)..sort(_compareByDate);
      _hydrateGoalCachesForDate(dateKey, todos);
      log(
        '[TodoProvider] loaded ${todos.length} todos for date=$dateKey',
        name: 'TodoProvider',
      );
    } catch (error, stackTrace) {
      log(
        '[TodoProvider] loadTodosForDate failed: $error',
        name: 'TodoProvider',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _loadingDates.remove(dateKey);
      notifyListeners();
    }
  }

  Future<TodoItem?> addTodo(String goalId, String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty) return null;

    final dateKey = _activeDateByGoal[goalId] ?? _dateKey(DateTime.now());
    final cacheKey = _goalDateKey(goalId, dateKey);
    if (!_todosByGoalDate.containsKey(cacheKey) ||
        _loadingGoalDates.contains(cacheKey)) {
      final existing = await DatabaseService.getTodoItemsByGoalAndDate(
        goalId,
        dateKey,
      );
      _todosByGoalDate[cacheKey] = List<TodoItem>.from(existing)
        ..sort(_compareWithinGoal);
      _replaceGoalItemsInDateCache(goalId, dateKey, existing);
    }

    final currentTodos = _todosByGoalDate[cacheKey] ?? const <TodoItem>[];
    final now = DateTime.now();
    final nextSortOrder = currentTodos.isEmpty
        ? 0
        : currentTodos
                  .map((item) => item.sortOrder)
                  .reduce(
                    (value, element) => value > element ? value : element,
                  ) +
              1;

    final todoItem = TodoItem(
      id: _uuid.v4(),
      goalId: goalId,
      content: normalized,
      isCompleted: false,
      createdAt: now,
      sortOrder: nextSortOrder,
      date: dateKey,
    );

    try {
      await DatabaseService.insertTodoItem(todoItem);
      _upsertItem(todoItem);
      notifyListeners();
      return todoItem;
    } catch (error, stackTrace) {
      log(
        '[TodoProvider] addTodo failed: $error',
        name: 'TodoProvider',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<TodoItem?> toggleTodo(String todoId) async {
    try {
      final updated = await DatabaseService.toggleTodoItem(todoId);
      if (updated == null) return null;
      _upsertItem(updated);
      notifyListeners();
      return updated;
    } catch (error, stackTrace) {
      log(
        '[TodoProvider] toggleTodo failed: $error',
        name: 'TodoProvider',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> deleteTodo(String todoId) async {
    try {
      await DatabaseService.deleteTodoItem(todoId);
      _removeItem(todoId);
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      log(
        '[TodoProvider] deleteTodo failed: $error',
        name: 'TodoProvider',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> reorderTodos(
    String goalId,
    DateTime date,
    List<TodoItem> newOrder,
  ) async {
    final dateKey = _dateKey(date);
    final cacheKey = _goalDateKey(goalId, dateKey);
    final reordered = <TodoItem>[
      for (final entry in newOrder.asMap().entries)
        entry.value.copyWith(sortOrder: entry.key),
    ];

    try {
      await Future.wait(
        reordered.map((item) => DatabaseService.updateTodoItem(item)),
      );

      _todosByGoalDate[cacheKey] = List<TodoItem>.from(reordered)
        ..sort(_compareWithinGoal);
      _replaceGoalItemsInDateCache(goalId, dateKey, reordered);
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      log(
        '[TodoProvider] reorderTodos failed: $error',
        name: 'TodoProvider',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void _upsertItem(TodoItem todoItem) {
    final goalKey = _goalDateKey(todoItem.goalId, todoItem.date);

    for (final entry in _todosByGoalDate.entries) {
      if (entry.key == goalKey) continue;
      entry.value.removeWhere((item) => item.id == todoItem.id);
    }
    for (final entry in _todosByDate.entries) {
      if (entry.key == todoItem.date) continue;
      entry.value.removeWhere((item) => item.id == todoItem.id);
    }

    final goalList = List<TodoItem>.from(
      _todosByGoalDate[goalKey] ?? const <TodoItem>[],
    );
    final goalIndex = goalList.indexWhere((item) => item.id == todoItem.id);
    if (goalIndex == -1) {
      goalList.add(todoItem);
    } else {
      goalList[goalIndex] = todoItem;
    }
    goalList.sort(_compareWithinGoal);
    _todosByGoalDate[goalKey] = goalList;

    if (_todosByDate.containsKey(todoItem.date)) {
      final dateList = List<TodoItem>.from(_todosByDate[todoItem.date]!);
      final dateIndex = dateList.indexWhere((item) => item.id == todoItem.id);
      if (dateIndex == -1) {
        dateList.add(todoItem);
      } else {
        dateList[dateIndex] = todoItem;
      }
      dateList.sort(_compareByDate);
      _todosByDate[todoItem.date] = dateList;
    }
  }

  void _removeItem(String todoId) {
    for (final entry in _todosByGoalDate.entries) {
      entry.value.removeWhere((item) => item.id == todoId);
    }
    for (final entry in _todosByDate.entries) {
      entry.value.removeWhere((item) => item.id == todoId);
    }
  }

  void _replaceGoalItemsInDateCache(
    String goalId,
    String dateKey,
    List<TodoItem> items,
  ) {
    if (!_todosByDate.containsKey(dateKey)) return;
    final merged =
        _todosByDate[dateKey]!.where((item) => item.goalId != goalId).toList()
          ..addAll(items);
    merged.sort(_compareByDate);
    _todosByDate[dateKey] = merged;
  }

  void _hydrateGoalCachesForDate(String dateKey, List<TodoItem> items) {
    final grouped = <String, List<TodoItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.goalId, () => <TodoItem>[]).add(item);
    }

    final dateSuffix = '|$dateKey';
    final existingKeys = _todosByGoalDate.keys
        .where((key) => key.endsWith(dateSuffix))
        .toList();

    for (final key in existingKeys) {
      final goalId = key.split('|').first;
      _todosByGoalDate[key] = List<TodoItem>.from(
        grouped[goalId] ?? const <TodoItem>[],
      )..sort(_compareWithinGoal);
    }
  }

  static int _compareWithinGoal(TodoItem a, TodoItem b) {
    final bySortOrder = a.sortOrder.compareTo(b.sortOrder);
    if (bySortOrder != 0) return bySortOrder;
    return a.createdAt.compareTo(b.createdAt);
  }

  static int _compareByDate(TodoItem a, TodoItem b) {
    final byGoal = a.goalId.compareTo(b.goalId);
    if (byGoal != 0) return byGoal;
    return _compareWithinGoal(a, b);
  }

  static String _goalDateKey(String goalId, String dateKey) {
    return '$goalId|$dateKey';
  }

  static String _dateKey(DateTime date) {
    return TodoItem.dateKeyFromDate(date);
  }
}
