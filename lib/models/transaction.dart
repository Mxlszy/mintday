enum TransactionType {
  income('income', '收入'),
  expense('expense', '支出');

  const TransactionType(this.value, this.label);

  final String value;
  final String label;

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String? goalId;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.goalId,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? goalId,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      goalId: goalId ?? this.goalId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.value,
      'category_id': categoryId,
      'goal_id': goalId,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromValue(map['type'] as String),
      categoryId: map['category_id'] as String,
      goalId: map['goal_id'] as String?,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class TransactionCategory {
  final String id;
  final String name;
  final String emoji;
  final TransactionType type;
  final bool isDefault;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    this.isDefault = false,
  });

  TransactionCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    TransactionType? type,
    bool? isDefault,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'type': type.value,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      type: TransactionType.fromValue(map['type'] as String),
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}

const List<TransactionCategory> defaultTransactionCategories = [
  TransactionCategory(
    id: 'expense_food',
    name: '餐饮',
    emoji: '🍜',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_transport',
    name: '交通',
    emoji: '🚗',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_shopping',
    name: '购物',
    emoji: '🛒',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_learning',
    name: '学习投资',
    emoji: '📚',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_medical',
    name: '医疗',
    emoji: '💊',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_housing',
    name: '住房',
    emoji: '🏠',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_entertainment',
    name: '娱乐',
    emoji: '🎬',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_clothing',
    name: '服饰',
    emoji: '👕',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'expense_other',
    name: '其他',
    emoji: '🎁',
    type: TransactionType.expense,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'income_salary',
    name: '工资',
    emoji: '💰',
    type: TransactionType.income,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'income_finance',
    name: '理财',
    emoji: '📈',
    type: TransactionType.income,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'income_red_packet',
    name: '红包',
    emoji: '🎁',
    type: TransactionType.income,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'income_part_time',
    name: '兼职',
    emoji: '💼',
    type: TransactionType.income,
    isDefault: true,
  ),
  TransactionCategory(
    id: 'income_other',
    name: '其他',
    emoji: '📦',
    type: TransactionType.income,
    isDefault: true,
  ),
];
