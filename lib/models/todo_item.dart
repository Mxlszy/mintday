import 'package:intl/intl.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.goalId,
    required this.content,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.sortOrder,
    required this.date,
  });

  final String id;
  final String goalId;
  final String content;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int sortOrder;
  final String date;

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  static String dateKeyFromDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _dateFormatter.format(normalized);
  }

  TodoItem copyWith({
    String? id,
    String? goalId,
    String? content,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortOrder,
    String? date,
  }) {
    return TodoItem(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'content': content,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'sort_order': sortOrder,
      'date': date,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      content: map['content'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      sortOrder: map['sort_order'] as int? ?? 0,
      date: map['date'] as String,
    );
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, goalId: $goalId, date: $date, completed: $isCompleted)';
  }
}
