/// 里程碑进度模型。
/// 当前主要用于记录连续打卡等成就，为后续图鉴与扩展能力预留数据结构。
enum MilestoneType {
  streak('streak', '连续打卡'),
  completion('completion', '目标完成'),
  custom('custom', '自定义');

  const MilestoneType(this.value, this.label);
  final String value;
  final String label;

  static MilestoneType fromValue(String value) {
    return MilestoneType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MilestoneType.custom,
    );
  }
}

class MilestoneProgress {
  final String id;
  final String goalId;
  final MilestoneType type;
  final String title;
  final String? description;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isMinted;
  final String? mintTxHash;
  final String? cardImagePath;

  const MilestoneProgress({
    required this.id,
    required this.goalId,
    required this.type,
    required this.title,
    this.description,
    required this.targetValue,
    required this.currentValue,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isMinted = false,
    this.mintTxHash,
    this.cardImagePath,
  });

  MilestoneProgress copyWith({
    String? id,
    String? goalId,
    MilestoneType? type,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isMinted,
    String? mintTxHash,
    String? cardImagePath,
  }) {
    return MilestoneProgress(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isMinted: isMinted ?? this.isMinted,
      mintTxHash: mintTxHash ?? this.mintTxHash,
      cardImagePath: cardImagePath ?? this.cardImagePath,
    );
  }

  double get progressRatio =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'type': type.value,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'is_minted': isMinted ? 1 : 0,
      'mint_tx_hash': mintTxHash,
      'card_image_path': cardImagePath,
    };
  }

  factory MilestoneProgress.fromMap(Map<String, dynamic> map) {
    return MilestoneProgress(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      type: MilestoneType.fromValue(map['type'] as String),
      title: map['title'] as String,
      description: map['description'] as String?,
      targetValue: map['target_value'] as int,
      currentValue: map['current_value'] as int,
      isUnlocked: (map['is_unlocked'] as int? ?? 0) == 1,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
      isMinted: (map['is_minted'] as int? ?? 0) == 1,
      mintTxHash: map['mint_tx_hash'] as String?,
      cardImagePath: map['card_image_path'] as String?,
    );
  }

  @override
  String toString() =>
      'MilestoneProgress(id: $id, type: ${type.value}, isUnlocked: $isUnlocked)';
}

class MilestonePresets {
  static const List<int> streakDays = [3, 7, 14, 30, 60, 100];

  static String streakTitle(int days) => '连续坚持 $days 天';

  static String streakDescription(int days) {
    if (days <= 3) return '迈出第一步，坚持本身就是进步。';
    if (days <= 7) return '整整一周，你已经证明了自己的意志力。';
    if (days <= 14) return '两周不间断，习惯正在成形。';
    if (days <= 30) return '一个月的坚持，这段旅程值得被记住。';
    if (days <= 60) return '两个月的积累，你已经超过了很多人。';
    return '百日坚持，这是属于你的传奇。';
  }
}
