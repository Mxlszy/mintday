class FocusSession {
  static const _sentinel = Object();

  final String id;
  final String goalId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final bool isCompleted;
  final String? note;
  final DateTime createdAt;

  const FocusSession({
    required this.id,
    required this.goalId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.isCompleted,
    this.note,
    required this.createdAt,
  });

  FocusSession copyWith({
    String? id,
    String? goalId,
    DateTime? startTime,
    Object? endTime = _sentinel,
    int? durationSeconds,
    bool? isCompleted,
    Object? note = _sentinel,
    DateTime? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      startTime: startTime ?? this.startTime,
      endTime: identical(endTime, _sentinel)
          ? this.endTime
          : endTime as DateTime?,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      note: identical(note, _sentinel) ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'is_completed': isCompleted ? 1 : 0,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
