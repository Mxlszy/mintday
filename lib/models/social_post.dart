import 'dart:convert';

import 'avatar_config.dart';

enum PostType {
  checkIn,
  achievement,
  milestone,
  nftMint,
  goalComplete,
  thought,
}

enum PostVisibility { public, friends }

extension PostVisibilityX on PostVisibility {
  String get label => switch (this) {
    PostVisibility.public => '公开',
    PostVisibility.friends => '仅好友可见',
  };

  bool get isPublic => this == PostVisibility.public;
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.avatarConfig,
    required this.content,
    required this.type,
    this.visibility = PostVisibility.public,
    this.title,
    this.subtitle,
    this.goalId,
    this.goalTitle,
    this.mood,
    this.streak,
    this.imagePaths = const <String>[],
    this.metadata,
    required this.likeCount,
    required this.commentCount,
    this.shareCount = 0,
    required this.isLikedByMe,
    required this.createdAt,
    this.isOfficial = false,
    this.isFriendActivity = false,
    this.sourceCheckInId,
    this.sourceGoalId,
    this.sourceNftId,
    this.sourceMilestoneId,
    this.sourceAchievementId,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final AvatarConfig? avatarConfig;
  final String content;
  final PostType type;
  final PostVisibility visibility;
  final String? title;
  final String? subtitle;
  final String? goalId;
  final String? goalTitle;
  final int? mood;
  final int? streak;
  final List<String> imagePaths;
  final Map<String, dynamic>? metadata;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLikedByMe;
  final DateTime createdAt;
  final bool isOfficial;
  final bool isFriendActivity;
  final String? sourceCheckInId;
  final String? sourceGoalId;
  final String? sourceNftId;
  final String? sourceMilestoneId;
  final String? sourceAchievementId;

  Map<String, dynamic> get extraData => metadata ?? const <String, dynamic>{};

  bool get isPublic => visibility.isPublic;

  String get moodEmoji {
    switch (mood) {
      case 1:
        return '😣';
      case 2:
        return '😕';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '🌱';
    }
  }

  SocialPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    AvatarConfig? avatarConfig,
    String? content,
    PostType? type,
    PostVisibility? visibility,
    String? title,
    String? subtitle,
    String? goalId,
    String? goalTitle,
    int? mood,
    int? streak,
    List<String>? imagePaths,
    Map<String, dynamic>? metadata,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLikedByMe,
    DateTime? createdAt,
    bool? isOfficial,
    bool? isFriendActivity,
    String? sourceCheckInId,
    String? sourceGoalId,
    String? sourceNftId,
    String? sourceMilestoneId,
    String? sourceAchievementId,
  }) {
    return SocialPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      content: content ?? this.content,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      goalId: goalId ?? this.goalId,
      goalTitle: goalTitle ?? this.goalTitle,
      mood: mood ?? this.mood,
      streak: streak ?? this.streak,
      imagePaths: imagePaths ?? this.imagePaths,
      metadata: metadata ?? this.metadata,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt ?? this.createdAt,
      isOfficial: isOfficial ?? this.isOfficial,
      isFriendActivity: isFriendActivity ?? this.isFriendActivity,
      sourceCheckInId: sourceCheckInId ?? this.sourceCheckInId,
      sourceGoalId: sourceGoalId ?? this.sourceGoalId,
      sourceNftId: sourceNftId ?? this.sourceNftId,
      sourceMilestoneId: sourceMilestoneId ?? this.sourceMilestoneId,
      sourceAchievementId: sourceAchievementId ?? this.sourceAchievementId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'avatar_config': avatarConfig == null
          ? null
          : jsonEncode(avatarConfig!.toJson()),
      'content': content,
      'type': type.name,
      'visibility': visibility.name,
      'title': title,
      'subtitle': subtitle,
      'goal_id': goalId,
      'goal_title': goalTitle,
      'mood': mood,
      'streak': streak,
      'image_paths': jsonEncode(imagePaths),
      'metadata': metadata == null ? null : jsonEncode(metadata),
      'achievement_title': type == PostType.achievement ? title : null,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'created_at': createdAt.toIso8601String(),
      'is_official': isOfficial ? 1 : 0,
      'is_friend_activity': isFriendActivity ? 1 : 0,
      'source_check_in_id': sourceCheckInId,
      'source_goal_id': sourceGoalId,
      'source_nft_id': sourceNftId,
      'source_milestone_id': sourceMilestoneId,
      'source_achievement_id': sourceAchievementId,
    };
  }

  factory SocialPost.fromMap(Map<String, dynamic> map) {
    AvatarConfig? avatarConfig;
    final avatarConfigRaw = map['avatar_config'];
    if (avatarConfigRaw is String && avatarConfigRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(avatarConfigRaw);
        if (decoded is Map<String, dynamic>) {
          avatarConfig = AvatarConfig.fromJson(decoded);
        } else if (decoded is Map) {
          avatarConfig = AvatarConfig.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    final typeValue = map['type'] as String? ?? PostType.checkIn.name;
    final type = PostType.values.firstWhere(
      (item) => item.name == typeValue,
      orElse: () => PostType.checkIn,
    );
    final visibilityValue =
        map['visibility'] as String? ?? PostVisibility.public.name;
    final visibility = PostVisibility.values.firstWhere(
      (item) => item.name == visibilityValue,
      orElse: () => PostVisibility.public,
    );

    Map<String, dynamic>? metadata;
    final metadataRaw = map['metadata'];
    if (metadataRaw is String && metadataRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadataRaw);
        if (decoded is Map<String, dynamic>) {
          metadata = decoded;
        } else if (decoded is Map) {
          metadata = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    List<String> imagePaths = const <String>[];
    final imagePathsRaw = map['image_paths'];
    if (imagePathsRaw is String && imagePathsRaw.trim().isNotEmpty) {
      try {
        imagePaths = List<String>.from(jsonDecode(imagePathsRaw));
      } catch (_) {}
    }

    final moodValue = map['mood'];
    final streakValue = map['streak'];

    return SocialPost(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userAvatar: map['user_avatar'] as String?,
      avatarConfig: avatarConfig,
      content: map['content'] as String? ?? '',
      type: type,
      visibility: visibility,
      title: map['title'] as String? ?? map['achievement_title'] as String?,
      subtitle: map['subtitle'] as String?,
      goalId: map['goal_id'] as String?,
      goalTitle: map['goal_title'] as String?,
      mood: moodValue is int ? moodValue : int.tryParse('$moodValue'),
      streak: streakValue is int ? streakValue : int.tryParse('$streakValue'),
      imagePaths: imagePaths,
      metadata: metadata,
      likeCount: map['like_count'] as int? ?? 0,
      commentCount: map['comment_count'] as int? ?? 0,
      shareCount: map['share_count'] as int? ?? 0,
      isLikedByMe: (map['is_liked_by_me'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      isOfficial: (map['is_official'] as int? ?? 0) == 1,
      isFriendActivity: (map['is_friend_activity'] as int? ?? 0) == 1,
      sourceCheckInId: map['source_check_in_id'] as String?,
      sourceGoalId: map['source_goal_id'] as String?,
      sourceNftId: map['source_nft_id'] as String?,
      sourceMilestoneId: map['source_milestone_id'] as String?,
      sourceAchievementId: map['source_achievement_id'] as String?,
    );
  }
}
