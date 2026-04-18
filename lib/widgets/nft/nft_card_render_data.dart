import '../../models/avatar_config.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../models/nft_asset.dart';

class NftCardRenderData {
  const NftCardRenderData({
    required this.title,
    required this.description,
    required this.createdAt,
    required this.nickname,
    required this.rarity,
    this.avatarConfig,
    this.primaryCheckIn,
    this.goal,
    this.collectionCheckIns = const <CheckIn>[],
    this.streakDays = 0,
    this.totalCheckIns = 0,
    this.focusMinutes = 0,
    this.metadata = const <String, dynamic>{},
  });

  final String title;
  final String description;
  final DateTime createdAt;
  final String nickname;
  final NftRarity rarity;
  final AvatarConfig? avatarConfig;
  final CheckIn? primaryCheckIn;
  final Goal? goal;
  final List<CheckIn> collectionCheckIns;
  final int streakDays;
  final int totalCheckIns;
  final int focusMinutes;
  final Map<String, dynamic> metadata;

  NftCardRenderData copyWith({
    String? title,
    String? description,
    DateTime? createdAt,
    String? nickname,
    NftRarity? rarity,
    AvatarConfig? avatarConfig,
    CheckIn? primaryCheckIn,
    Goal? goal,
    List<CheckIn>? collectionCheckIns,
    int? streakDays,
    int? totalCheckIns,
    int? focusMinutes,
    Map<String, dynamic>? metadata,
  }) {
    return NftCardRenderData(
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      nickname: nickname ?? this.nickname,
      rarity: rarity ?? this.rarity,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      primaryCheckIn: primaryCheckIn ?? this.primaryCheckIn,
      goal: goal ?? this.goal,
      collectionCheckIns: collectionCheckIns ?? this.collectionCheckIns,
      streakDays: streakDays ?? this.streakDays,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      metadata: metadata ?? this.metadata,
    );
  }

  String get goalTitle {
    return goal?.title ??
        metadata['goalTitle']?.toString() ??
        metadata['goal_title']?.toString() ??
        '今天的记录';
  }

  String get primaryNote {
    final checkIn = primaryCheckIn;
    return checkIn?.note ??
        checkIn?.reflectionProgress ??
        checkIn?.reflectionNext ??
        description;
  }

  int get primaryMood {
    final mood = primaryCheckIn?.mood;
    if (mood != null && mood >= 1 && mood <= 5) {
      return mood;
    }

    final moodSeries = recentMoodSeries;
    if (moodSeries.isEmpty) return 3;
    final average = moodSeries.reduce((a, b) => a + b) / moodSeries.length;
    final rounded = average.round();
    if (rounded < 1) return 1;
    if (rounded > 5) return 5;
    return rounded;
  }

  List<int> get recentMoodSeries {
    final source = collectionCheckIns.isNotEmpty
        ? collectionCheckIns
        : primaryCheckIn == null
        ? const <CheckIn>[]
        : <CheckIn>[primaryCheckIn!];

    return source
        .map((item) => item.mood)
        .whereType<int>()
        .where((value) => value >= 1 && value <= 5)
        .toList();
  }

  List<CheckIn> get effectiveCollection {
    if (collectionCheckIns.isNotEmpty) return collectionCheckIns;
    if (primaryCheckIn != null) return <CheckIn>[primaryCheckIn!];
    return const <CheckIn>[];
  }

  String? get primaryImagePath {
    final images = primaryCheckIn?.imagePaths;
    if (images == null || images.isEmpty) return null;
    return images.first;
  }
}
