import 'dart:convert';

enum GoalCategory {
  habit('habit', '习惯养成'),
  project('project', '项目计划'),
  study('study', '学习提升'),
  health('health', '健康运动'),
  wish('wish', '愿望清单'),
  custom('custom', '自定义');

  const GoalCategory(this.value, this.label);
  final String value;
  final String label;

  static GoalCategory fromValue(String value) {
    return GoalCategory.values.firstWhere(
      (item) => item.value == value,
      orElse: () => GoalCategory.custom,
    );
  }
}

enum GoalStatus {
  active('active'),
  completed('completed'),
  archived('archived');

  const GoalStatus(this.value);
  final String value;

  static GoalStatus fromValue(String value) {
    return GoalStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => GoalStatus.active,
    );
  }
}

class Goal {
  final String id;
  final String title;
  final GoalCategory category;
  final String? reason;
  final String? vision;
  final DateTime? deadline;
  final List<String> steps;
  final List<bool> completedSteps;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isMintable;
  final String? seasonId;
  final bool isPublic;
  final String? reward;

  const Goal({
    required this.id,
    required this.title,
    required this.category,
    this.reason,
    this.vision,
    this.deadline,
    this.steps = const [],
    this.completedSteps = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isMintable = false,
    this.seasonId,
    this.isPublic = false,
    this.reward,
  });

  Goal copyWith({
    String? id,
    String? title,
    GoalCategory? category,
    String? reason,
    String? vision,
    DateTime? deadline,
    List<String>? steps,
    List<bool>? completedSteps,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isMintable,
    String? seasonId,
    bool? isPublic,
    String? reward,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      vision: vision ?? this.vision,
      deadline: deadline ?? this.deadline,
      steps: steps ?? this.steps,
      completedSteps: completedSteps ?? this.completedSteps,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMintable: isMintable ?? this.isMintable,
      seasonId: seasonId ?? this.seasonId,
      isPublic: isPublic ?? this.isPublic,
      reward: reward ?? this.reward,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.value,
      'reason': reason,
      'vision': vision,
      'deadline': deadline?.toIso8601String(),
      'steps': jsonEncode(steps),
      'completed_steps': jsonEncode(completedSteps),
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_mintable': isMintable ? 1 : 0,
      'season_id': seasonId,
      'is_public': isPublic ? 1 : 0,
      'reward': reward,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    final stepsRaw = map['steps'] as String? ?? '[]';
    final completedRaw = map['completed_steps'] as String? ?? '[]';

    List<String> steps = [];
    List<bool> completedSteps = [];

    try {
      steps = List<String>.from(jsonDecode(stepsRaw));
      completedSteps = List<bool>.from(jsonDecode(completedRaw));
    } catch (_) {}

    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      category: GoalCategory.fromValue(map['category'] as String),
      reason: map['reason'] as String?,
      vision: map['vision'] as String?,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      steps: steps,
      completedSteps: completedSteps,
      status: GoalStatus.fromValue(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isMintable: (map['is_mintable'] as int? ?? 0) == 1,
      seasonId: map['season_id'] as String?,
      isPublic: (map['is_public'] as int? ?? 0) == 1,
      reward: map['reward'] as String?,
    );
  }

  int get completedStepCount => completedSteps.where((item) => item).length;

  double get progress {
    if (steps.isEmpty) return 0.0;
    return completedStepCount / steps.length;
  }

  @override
  String toString() => 'Goal(id: $id, title: $title, status: ${status.value})';
}
