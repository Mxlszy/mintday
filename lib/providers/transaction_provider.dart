import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';

class CategoryExpenseBreakdown {
  final TransactionCategory category;
  final double amount;
  final double share;

  const CategoryExpenseBreakdown({
    required this.category,
    required this.amount,
    required this.share,
  });
}

class TransactionProvider extends ChangeNotifier {
  static const _name = 'TransactionProvider';

  final _uuid = const Uuid();

  List<Transaction> _transactions = [];
  List<TransactionCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        DatabaseService.getAllTransactions(),
        DatabaseService.getAllTransactionCategories(),
      ]);

      _transactions = List<Transaction>.from(results[0] as List<Transaction>)
        ..sort(_compareTransactions);
      _categories = List<TransactionCategory>.from(
        results[1] as List<TransactionCategory>,
      );
    } catch (e, s) {
      _error = '加载账本失败，请稍后重试';
      log('[$_name] loadData 失败: $e', name: _name, error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TransactionCategory> categoriesForType(TransactionType type) {
    return _categories.where((category) => category.type == type).toList();
  }

  TransactionCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  Future<Transaction?> addTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    String? goalId,
    String? note,
    required DateTime date,
  }) async {
    final category = getCategoryById(categoryId);
    if (category == null || category.type != type) {
      _error = '请选择对应类型的分类';
      notifyListeners();
      return null;
    }

    final transaction = Transaction(
      id: _uuid.v4(),
      amount: _normalizeAmount(amount, type),
      type: type,
      categoryId: categoryId,
      goalId: _normalizeOptional(goalId),
      note: _normalizeOptional(note),
      date: date,
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseService.insertTransaction(transaction);
      _transactions = [transaction, ..._transactions]
        ..sort(_compareTransactions);
      _error = null;
      notifyListeners();
      return transaction;
    } catch (e, s) {
      _error = '保存记账失败，请稍后重试';
      log(
        '[$_name] addTransaction 失败: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) return false;

    final category = getCategoryById(transaction.categoryId);
    if (category == null || category.type != transaction.type) {
      _error = '当前分类与收支类型不匹配';
      notifyListeners();
      return false;
    }

    final previous = _transactions[index];
    final normalized = transaction.copyWith(
      amount: _normalizeAmount(transaction.amount, transaction.type),
      goalId: _normalizeOptional(transaction.goalId),
      note: _normalizeOptional(transaction.note),
    );

    _transactions[index] = normalized;
    _transactions.sort(_compareTransactions);
    notifyListeners();

    try {
      await DatabaseService.updateTransaction(normalized);
      _error = null;
      notifyListeners();
      return true;
    } catch (e, s) {
      _transactions[index] = previous;
      _transactions.sort(_compareTransactions);
      _error = '更新记账失败，请稍后重试';
      log(
        '[$_name] updateTransaction 失败: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    final removed = _transactions.removeAt(index);
    notifyListeners();

    try {
      await DatabaseService.deleteTransaction(id);
      return true;
    } catch (e, s) {
      _transactions.insert(index, removed);
      _transactions.sort(_compareTransactions);
      _error = '删除记录失败，请稍后重试';
      log(
        '[$_name] deleteTransaction 失败: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return false;
    }
  }

  Future<TransactionCategory?> createCategory({
    required String name,
    required String emoji,
    required TransactionType type,
  }) async {
    final category = TransactionCategory(
      id: _uuid.v4(),
      name: name.trim(),
      emoji: emoji,
      type: type,
    );

    try {
      await DatabaseService.insertTransactionCategory(category);
      _categories = [..._categories, category];
      notifyListeners();
      return category;
    } catch (e, s) {
      _error = '创建分类失败，请稍后重试';
      log(
        '[$_name] createCategory 失败: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCategory(TransactionCategory category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index == -1) return false;

    final previous = _categories[index];
    _categories[index] = category;
    notifyListeners();

    try {
      await DatabaseService.updateTransactionCategory(category);
      return true;
    } catch (e, s) {
      _categories[index] = previous;
      _error = '更新分类失败，请稍后重试';
      log(
        '[$_name] updateCategory 失败: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    final index = _categories.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    if (_categories[index].isDefault) return false;
    if (_transactions.any((item) => item.categoryId == id)) return false;

    final removed = _categories.removeAt(index);
    notifyListeners();

    try {
      await DatabaseService.deleteTransactionCategory(id);
      return true;
    } catch (e, s) {
      _categories.insert(index, removed);
      _error = '删除分类失败，请稍后重试';
      log(
        '[$_name] deleteCategory 失败: $e',
        name: _name,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
      return false;
    }
  }

  List<Transaction> getTransactionsForMonth(int year, int month) {
    return _transactions
        .where((item) => _isInMonth(item.date, year, month))
        .toList();
  }

  double getMonthlyIncome(int year, int month) {
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.income &&
              _isInMonth(item.date, year, month),
        )
        .fold(0.0, (sum, item) => sum + item.amount.abs());
  }

  double getMonthlyExpense(int year, int month) {
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              _isInMonth(item.date, year, month),
        )
        .fold(0.0, (sum, item) => sum + item.amount.abs());
  }

  double getMonthlyBalance(int year, int month) {
    return getMonthlyIncome(year, month) - getMonthlyExpense(year, month);
  }

  List<CategoryExpenseBreakdown> getCategoryBreakdown(int year, int month) {
    final amounts = <String, double>{};
    for (final transaction in _transactions) {
      if (transaction.type != TransactionType.expense ||
          !_isInMonth(transaction.date, year, month)) {
        continue;
      }
      amounts[transaction.categoryId] =
          (amounts[transaction.categoryId] ?? 0) + transaction.amount.abs();
    }

    final totalExpense = amounts.values.fold(0.0, (sum, value) => sum + value);
    final breakdown = <CategoryExpenseBreakdown>[];

    amounts.forEach((categoryId, amount) {
      final category = getCategoryById(categoryId);
      if (category == null) return;
      breakdown.add(
        CategoryExpenseBreakdown(
          category: category,
          amount: amount,
          share: totalExpense == 0 ? 0 : amount / totalExpense,
        ),
      );
    });

    breakdown.sort((a, b) => b.amount.compareTo(a.amount));
    return breakdown;
  }

  double getGoalRelatedExpense(String goalId) {
    return _transactions
        .where(
          (item) =>
              item.goalId == goalId && item.type == TransactionType.expense,
        )
        .fold(0.0, (sum, item) => sum + item.amount.abs());
  }

  Map<DateTime, double> getDailyExpenses(int year, int month) {
    final result = <DateTime, double>{};
    for (final transaction in _transactions) {
      if (transaction.type != TransactionType.expense ||
          !_isInMonth(transaction.date, year, month)) {
        continue;
      }

      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      result[day] = (result[day] ?? 0) + transaction.amount.abs();
    }
    return result;
  }

  List<Transaction> getRecentTransactions(int limit) {
    if (limit <= 0) return const [];
    return _transactions.take(limit).toList();
  }

  static bool _isInMonth(DateTime date, int year, int month) {
    return date.year == year && date.month == month;
  }

  static int _compareTransactions(Transaction a, Transaction b) {
    final dateCompare = b.date.compareTo(a.date);
    if (dateCompare != 0) return dateCompare;
    return b.createdAt.compareTo(a.createdAt);
  }

  static double _normalizeAmount(double amount, TransactionType type) {
    final value = amount.abs();
    return type == TransactionType.income ? value : -value;
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
