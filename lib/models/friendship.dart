import 'dart:convert';

import 'avatar_config.dart';

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  blocked('blocked');

  const FriendshipStatus(this.value);

  final String value;

  static FriendshipStatus fromValue(String value) {
    return FriendshipStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => FriendshipStatus.pending,
    );
  }
}

class Friendship {
  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  Friendship copyWith({
    String? id,
    String? userId,
    String? friendId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    bool clearAcceptedAt = false,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: clearAcceptedAt ? null : (acceptedAt ?? this.acceptedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      friendId: map['friend_id'] as String,
      status: FriendshipStatus.fromValue(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      acceptedAt: map['accepted_at'] == null
          ? null
          : DateTime.parse(map['accepted_at'] as String),
    );
  }

  bool involves(String userId) => this.userId == userId || friendId == userId;

  String otherUserId(String currentUserId) {
    return userId == currentUserId ? friendId : userId;
  }
}

class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.nickname,
    this.avatarAssetPath,
    this.avatarConfig,
    this.totalCheckIns = 0,
    this.currentStreak = 0,
    this.activeGoals = 0,
    this.lastActiveAt,
    this.lastSyncedAt,
  });

  final String id;
  final String nickname;
  final String? avatarAssetPath;
  final Map<String, dynamic>? avatarConfig;
  final int totalCheckIns;
  final int currentStreak;
  final int activeGoals;
  final DateTime? lastActiveAt;
  final DateTime? lastSyncedAt;

  AvatarConfig? get parsedAvatarConfig {
    if (avatarConfig == null) return null;
    return AvatarConfig.fromJson(Map<String, dynamic>.from(avatarConfig!));
  }

  FriendProfile copyWith({
    String? id,
    String? nickname,
    String? avatarAssetPath,
    Map<String, dynamic>? avatarConfig,
    int? totalCheckIns,
    int? currentStreak,
    int? activeGoals,
    DateTime? lastActiveAt,
    DateTime? lastSyncedAt,
    bool clearAvatarAssetPath = false,
    bool clearAvatarConfig = false,
    bool clearLastActiveAt = false,
    bool clearLastSyncedAt = false,
  }) {
    return FriendProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarAssetPath: clearAvatarAssetPath
          ? null
          : (avatarAssetPath ?? this.avatarAssetPath),
      avatarConfig: clearAvatarConfig
          ? null
          : (avatarConfig ?? this.avatarConfig),
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      currentStreak: currentStreak ?? this.currentStreak,
      activeGoals: activeGoals ?? this.activeGoals,
      lastActiveAt: clearLastActiveAt
          ? null
          : (lastActiveAt ?? this.lastActiveAt),
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
    );
  }

  Map<String, dynamic> toCacheMap({DateTime? lastSyncedAt}) {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_data': jsonEncode({
        'avatarAssetPath': avatarAssetPath,
        'avatarConfig': avatarConfig,
      }),
      'stats_json': jsonEncode({
        'totalCheckIns': totalCheckIns,
        'currentStreak': currentStreak,
        'activeGoals': activeGoals,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
      }),
      'last_synced': (lastSyncedAt ?? this.lastSyncedAt ?? DateTime.now())
          .toIso8601String(),
    };
  }

  factory FriendProfile.fromCacheMap(Map<String, dynamic> map) {
    Map<String, dynamic> avatarData = const {};
    Map<String, dynamic> statsData = const {};

    try {
      final decodedAvatar = jsonDecode(map['avatar_data'] as String? ?? '{}');
      if (decodedAvatar is Map) {
        avatarData = Map<String, dynamic>.from(decodedAvatar);
      }
    } catch (_) {}

    try {
      final decodedStats = jsonDecode(map['stats_json'] as String? ?? '{}');
      if (decodedStats is Map) {
        statsData = Map<String, dynamic>.from(decodedStats);
      }
    } catch (_) {}

    final avatarConfig = avatarData['avatarConfig'];
    final avatarConfigMap = avatarConfig is Map
        ? Map<String, dynamic>.from(avatarConfig)
        : null;

    return FriendProfile(
      id: map['id'] as String,
      nickname: map['nickname'] as String? ?? 'MintDay 伙伴',
      avatarAssetPath: avatarData['avatarAssetPath'] as String?,
      avatarConfig: avatarConfigMap,
      totalCheckIns: (statsData['totalCheckIns'] as int?) ?? 0,
      currentStreak: (statsData['currentStreak'] as int?) ?? 0,
      activeGoals: (statsData['activeGoals'] as int?) ?? 0,
      lastActiveAt: _parseDateTime(statsData['lastActiveAt']),
      lastSyncedAt: _parseDateTime(map['last_synced']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class FriendRecord {
  const FriendRecord({required this.friendship, required this.profile});

  final Friendship friendship;
  final FriendProfile profile;
}

enum FriendRelationType {
  none,
  self,
  friend,
  incomingPending,
  outgoingPending,
  blocked,
}

class FriendSearchResult {
  const FriendSearchResult({
    required this.profile,
    required this.relationType,
    this.friendship,
  });

  final FriendProfile profile;
  final FriendRelationType relationType;
  final Friendship? friendship;

  bool get canSendRequest => relationType == FriendRelationType.none;
  bool get isFriend => relationType == FriendRelationType.friend;
}
