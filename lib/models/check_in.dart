import 'dart:convert';

enum CheckInMode {
  quick('quick', '快速打卡'),
  reflection('reflection', '反思打卡');

  const CheckInMode(this.value, this.label);
  final String value;
  final String label;

  static CheckInMode fromValue(String value) {
    return CheckInMode.values.firstWhere(
      (item) => item.value == value,
      orElse: () => CheckInMode.quick,
    );
  }
}

enum CheckInStatus {
  done('done', '完成'),
  partial('partial', '部分完成'),
  skipped('skipped', '跳过');

  const CheckInStatus(this.value, this.label);
  final String value;
  final String label;

  static CheckInStatus fromValue(String value) {
    return CheckInStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => CheckInStatus.done,
    );
  }
}

class CheckIn {
  final String id;
  final String goalId;
  final DateTime date;
  final CheckInMode mode;
  final CheckInStatus status;
  final int? mood;
  final int? duration;
  final String? note;
  final String? reflectionProgress;
  final String? reflectionBlocker;
  final String? reflectionNext;
  final List<String> imagePaths;
  final DateTime createdAt;
  final String? evidenceType;
  final List<String> evidenceUrls;

  const CheckIn({
    required this.id,
    required this.goalId,
    required this.date,
    required this.mode,
    required this.status,
    this.mood,
    this.duration,
    this.note,
    this.reflectionProgress,
    this.reflectionBlocker,
    this.reflectionNext,
    this.imagePaths = const [],
    required this.createdAt,
    this.evidenceType,
    this.evidenceUrls = const [],
  });

  CheckIn copyWith({
    String? id,
    String? goalId,
    DateTime? date,
    CheckInMode? mode,
    CheckInStatus? status,
    int? mood,
    int? duration,
    String? note,
    String? reflectionProgress,
    String? reflectionBlocker,
    String? reflectionNext,
    List<String>? imagePaths,
    DateTime? createdAt,
    String? evidenceType,
    List<String>? evidenceUrls,
  }) {
    return CheckIn(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      mood: mood ?? this.mood,
      duration: duration ?? this.duration,
      note: note ?? this.note,
      reflectionProgress: reflectionProgress ?? this.reflectionProgress,
      reflectionBlocker: reflectionBlocker ?? this.reflectionBlocker,
      reflectionNext: reflectionNext ?? this.reflectionNext,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      evidenceType: evidenceType ?? this.evidenceType,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'date': _dateOnly(date),
      'mode': mode.value,
      'status': status.value,
      'mood': mood,
      'duration': duration,
      'note': note,
      'reflection_progress': reflectionProgress,
      'reflection_blocker': reflectionBlocker,
      'reflection_next': reflectionNext,
      'image_paths': jsonEncode(imagePaths),
      'created_at': createdAt.toIso8601String(),
      'evidence_type': evidenceType,
      'evidence_urls': jsonEncode(evidenceUrls),
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    List<String> imagePaths = [];
    List<String> evidenceUrls = [];

    try {
      imagePaths = List<String>.from(
        jsonDecode(map['image_paths'] as String? ?? '[]'),
      );
      evidenceUrls = List<String>.from(
        jsonDecode(map['evidence_urls'] as String? ?? '[]'),
      );
    } catch (_) {}

    return CheckIn(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      date: DateTime.parse(map['date'] as String),
      mode: CheckInMode.fromValue(map['mode'] as String),
      status: CheckInStatus.fromValue(map['status'] as String),
      mood: map['mood'] as int?,
      duration: map['duration'] as int?,
      note: map['note'] as String?,
      reflectionProgress: map['reflection_progress'] as String?,
      reflectionBlocker: map['reflection_blocker'] as String?,
      reflectionNext: map['reflection_next'] as String?,
      imagePaths: imagePaths,
      createdAt: DateTime.parse(map['created_at'] as String),
      evidenceType: map['evidence_type'] as String?,
      evidenceUrls: evidenceUrls,
    );
  }

  static String _dateOnly(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String get dateString => _dateOnly(date);

  String get moodEmoji {
    switch (mood) {
      case 1:
        return '😣';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '🙂';
    }
  }

  @override
  String toString() {
    return 'CheckIn(id: $id, goalId: $goalId, date: $dateString, status: ${status.value})';
  }
}
