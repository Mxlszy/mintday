import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/user_profile_model.dart';
import '../models/avatar_config.dart';
import '../models/friendship.dart';
import '../models/social_post.dart';
import '../services/database_service.dart';
import '../services/user_profile_prefs.dart';
import 'auth_provider.dart';
import 'user_profile_provider.dart';

class FriendProvider extends ChangeNotifier {
  FriendProvider({
    AuthProvider? authProvider,
    UserProfileProvider? userProfileProvider,
  }) : _authProvider = authProvider,
       _userProfileProvider = userProfileProvider;

  static const _seedNames = [
    '晨光拾荒者',
    '番茄钟骑士',
    '慢热冲刺员',
    '目标收藏家',
    '薄荷能量站',
    '清晨打卡机',
    '周末也发光',
    '火苗计划员',
    '准点梦想家',
    '步频研究所',
    '今日有进步',
    '深夜复盘官',
  ];

  static const _activityGoals = [
    '晨读 20 分钟',
    '一周跑步 4 次',
    'Flutter 手账开发',
    '英语口语练习',
    '早睡 23:30 前',
    '力量训练计划',
    '每日写作 300 字',
    '晚间复盘 10 分钟',
  ];

  static const _activityContents = [
    '今天状态一般，但还是把计划里的关键一步推进了。',
    '先做五分钟，结果顺着做完了整段任务。',
    '没有追求完美，先把连续性守住比什么都重要。',
    '差点想拖到明天，最后还是给今天交了一份答卷。',
    '把目标拆小之后，真的没那么难开始了。',
    '只完成了一部分，不过节奏还在，这就值得记录。',
    '今天比昨天更稳一点，继续把火种留住。',
    '完成后整个人都轻了一点，原来行动真的能治犹豫。',
  ];

  final Uuid _uuid = const Uuid();

  AuthProvider? _authProvider;
  UserProfileProvider? _userProfileProvider;

  final List<FriendRecord> _friends = [];
  final List<FriendRecord> _pendingRequests = [];
  final List<FriendRecord> _sentRequests = [];
  final List<FriendSearchResult> _searchResults = [];
  final Map<String, List<SocialPost>> _activityCache = {};

  bool _didInit = false;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isSearching = false;
  bool _syncingSession = false;

  String? _currentUserId;
  String _searchQuery = '';

  List<FriendRecord> get friends => List.unmodifiable(_friends);
  List<FriendRecord> get pendingRequests => List.unmodifiable(_pendingRequests);
  List<FriendRecord> get sentRequests => List.unmodifiable(_sentRequests);
  List<FriendSearchResult> get searchResults =>
      List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isSearching => _isSearching;
  String get currentUserId => _currentUserId ?? '';
  String get searchQuery => _searchQuery;
  int get friendCount => _friends.length;
  int get pendingRequestCount => _pendingRequests.length;

  List<SocialPost> get prioritizedFriendFeed {
    final posts =
        _friends
            .expand(
              (record) =>
                  _activityCache[record.profile.id] ?? const <SocialPost>[],
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(posts.take(12));
  }

  void updateDependencies({
    required AuthProvider authProvider,
    required UserProfileProvider userProfileProvider,
  }) {
    final previousAuthId = _authProvider?.user?.id;
    final previousProfile = _userProfileProvider?.profile;

    _authProvider = authProvider;
    _userProfileProvider = userProfileProvider;

    final authChanged = previousAuthId != authProvider.user?.id;
    final profileChanged = previousProfile != userProfileProvider.profile;

    if (!_didInit) {
      unawaited(init());
      return;
    }

    if (authChanged || profileChanged) {
      unawaited(_syncSessionAndMaybeReload());
    }
  }

  Future<void> init() async {
    if (_didInit) return;
    _didInit = true;
    _isLoading = true;
    notifyListeners();

    try {
      await _syncSessionAndMaybeReload(force: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      await _syncSessionAndMaybeReload(force: true);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<List<FriendSearchResult>> searchUsers(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return searchResults;
    }

    _isSearching = true;
    notifyListeners();

    try {
      await _ensureSeedProfiles();
      final cachedProfiles = await DatabaseService.searchFriendProfiles(
        _searchQuery,
      );
      final results = <FriendSearchResult>[
        ...cachedProfiles.map(_buildSearchResultForProfile),
      ];

      final selfProfile = _buildCurrentUserSearchProfile();
      if (selfProfile != null) {
        final matchesSelf =
            selfProfile.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            selfProfile.nickname.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        final alreadyIncluded = results.any(
          (item) => item.profile.id == selfProfile.id,
        );
        if (matchesSelf && !alreadyIncluded) {
          results.insert(
            0,
            FriendSearchResult(
              profile: selfProfile,
              relationType: FriendRelationType.self,
            ),
          );
        }
      }

      results.removeWhere(
        (item) =>
            item.profile.id != currentUserId &&
            item.relationType == FriendRelationType.blocked,
      );

      _searchResults
        ..clear()
        ..addAll(results);
      return searchResults;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isEmpty && _searchResults.isEmpty) return;
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String friendId) async {
    final userId = await _ensureCurrentUserId();
    if (friendId == userId || friendId.trim().isEmpty) {
      return false;
    }

    final existing = await DatabaseService.getFriendshipBetween(
      userId,
      friendId,
    );
    if (existing != null) {
      return false;
    }

    final profile =
        await DatabaseService.getFriendProfileById(friendId) ??
        _buildFallbackProfile(friendId);
    await DatabaseService.upsertFriendProfile(profile);
    await DatabaseService.upsertFriendship(
      Friendship(
        id: _uuid.v4(),
        userId: userId,
        friendId: friendId,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _reloadState(refreshSearch: true);
    return true;
  }

  Future<bool> acceptRequest(String friendshipId) async {
    final friendship = await DatabaseService.getFriendshipById(friendshipId);
    if (friendship == null || friendship.status != FriendshipStatus.pending) {
      return false;
    }

    if (friendship.friendId != currentUserId) {
      return false;
    }

    await DatabaseService.upsertFriendship(
      friendship.copyWith(
        status: FriendshipStatus.accepted,
        acceptedAt: DateTime.now(),
      ),
    );
    await _reloadState(refreshSearch: true);
    return true;
  }

  Future<bool> rejectRequest(String friendshipId) async {
    final count = await DatabaseService.deleteFriendship(friendshipId);
    if (count <= 0) return false;
    await _reloadState(refreshSearch: true);
    return true;
  }

  Future<bool> removeFriend(String friendId) async {
    final count = await DatabaseService.deleteFriendshipsBetween(
      currentUserId,
      friendId,
    );
    if (count <= 0) return false;
    _activityCache.remove(friendId);
    await _reloadState(refreshSearch: true);
    return true;
  }

  Future<bool> blockUser(String userId) async {
    if (userId == currentUserId || userId.trim().isEmpty) {
      return false;
    }

    await DatabaseService.deleteFriendshipsBetween(currentUserId, userId);
    await DatabaseService.upsertFriendship(
      Friendship(
        id: _uuid.v4(),
        userId: currentUserId,
        friendId: userId,
        status: FriendshipStatus.blocked,
        createdAt: DateTime.now(),
      ),
    );
    _activityCache.remove(userId);
    await _reloadState(refreshSearch: true);
    return true;
  }

  Future<List<SocialPost>> getFriendActivity(String friendId) async {
    final cached = _activityCache[friendId];
    if (cached != null) {
      return List.unmodifiable(cached);
    }

    final profile =
        findCachedProfile(friendId) ??
        await DatabaseService.getFriendProfileById(friendId) ??
        _buildFallbackProfile(friendId);
    final activity = _buildSyntheticActivity(profile);
    _activityCache[friendId] = activity;
    return List.unmodifiable(activity);
  }

  Future<FriendProfile> getResolvedProfile(String userId) async {
    return findCachedProfile(userId) ??
        await DatabaseService.getFriendProfileById(userId) ??
        _buildFallbackProfile(userId);
  }

  FriendProfile? findCachedProfile(String userId) {
    for (final record in _friends) {
      if (record.profile.id == userId) return record.profile;
    }
    for (final record in _pendingRequests) {
      if (record.profile.id == userId) return record.profile;
    }
    for (final record in _sentRequests) {
      if (record.profile.id == userId) return record.profile;
    }
    for (final result in _searchResults) {
      if (result.profile.id == userId) return result.profile;
    }
    return null;
  }

  Friendship? getFriendshipWith(String userId) {
    for (final record in [..._friends, ..._pendingRequests, ..._sentRequests]) {
      if (record.profile.id == userId) return record.friendship;
    }
    final result = _searchResults
        .where((item) => item.profile.id == userId)
        .cast<FriendSearchResult?>()
        .firstWhere((item) => item != null, orElse: () => null);
    return result?.friendship;
  }

  FriendRelationType relationTypeFor(String userId) {
    if (userId == currentUserId) {
      return FriendRelationType.self;
    }
    if (_friends.any((record) => record.profile.id == userId)) {
      return FriendRelationType.friend;
    }
    final incoming = _pendingRequests.any(
      (record) => record.profile.id == userId,
    );
    if (incoming) {
      return FriendRelationType.incomingPending;
    }
    final outgoing = _sentRequests.any((record) => record.profile.id == userId);
    if (outgoing) {
      return FriendRelationType.outgoingPending;
    }
    final searchResult = _searchResults
        .where((item) => item.profile.id == userId)
        .cast<FriendSearchResult?>()
        .firstWhere((item) => item != null, orElse: () => null);
    return searchResult?.relationType ?? FriendRelationType.none;
  }

  Future<void> _syncSessionAndMaybeReload({bool force = false}) async {
    if (_syncingSession) return;
    _syncingSession = true;
    try {
      final previousUserId = _currentUserId;
      final nextUserId = await _ensureCurrentUserId();
      await _ensureSeedProfiles();
      if (force || previousUserId != nextUserId) {
        await _reloadState(refreshSearch: _searchQuery.isNotEmpty);
      } else if (_searchQuery.isNotEmpty) {
        await searchUsers(_searchQuery);
      }
    } finally {
      _syncingSession = false;
    }
  }

  Future<String> _ensureCurrentUserId() async {
    final authUserId = _authProvider?.user?.id.trim();
    if (authUserId != null && authUserId.isNotEmpty) {
      _currentUserId = authUserId;
      return authUserId;
    }

    final localId = await UserProfilePrefs.getLocalFriendUserId();
    _currentUserId = localId;
    return localId;
  }

  Future<void> _reloadState({bool refreshSearch = false}) async {
    final userId = _currentUserId ?? await _ensureCurrentUserId();
    final friendships = await DatabaseService.getFriendshipsForUser(userId);
    final cachedProfiles = await DatabaseService.getAllFriendProfiles();
    final profileMap = {
      for (final profile in cachedProfiles) profile.id: profile,
    };

    final nextFriends = <FriendRecord>[];
    final nextPending = <FriendRecord>[];
    final nextSent = <FriendRecord>[];

    for (final friendship in friendships) {
      final otherUserId = friendship.otherUserId(userId);
      final profile =
          profileMap[otherUserId] ?? _buildFallbackProfile(otherUserId);
      final record = FriendRecord(friendship: friendship, profile: profile);

      switch (friendship.status) {
        case FriendshipStatus.accepted:
          nextFriends.add(record);
          break;
        case FriendshipStatus.pending:
          if (friendship.friendId == userId) {
            nextPending.add(record);
          } else {
            nextSent.add(record);
          }
          break;
        case FriendshipStatus.blocked:
          break;
      }
    }

    nextFriends.sort(_friendComparator);
    nextPending.sort(
      (a, b) => b.friendship.createdAt.compareTo(a.friendship.createdAt),
    );
    nextSent.sort(
      (a, b) => b.friendship.createdAt.compareTo(a.friendship.createdAt),
    );

    _friends
      ..clear()
      ..addAll(nextFriends);
    _pendingRequests
      ..clear()
      ..addAll(nextPending);
    _sentRequests
      ..clear()
      ..addAll(nextSent);

    _rebuildActivityCache(nextFriends);

    if (refreshSearch && _searchQuery.isNotEmpty) {
      await searchUsers(_searchQuery);
      return;
    }

    notifyListeners();
  }

  int _friendComparator(FriendRecord a, FriendRecord b) {
    final activeCompare = _sortNullableDate(
      b.profile.lastActiveAt,
      a.profile.lastActiveAt,
    );
    if (activeCompare != 0) return activeCompare;

    final streakCompare = b.profile.currentStreak.compareTo(
      a.profile.currentStreak,
    );
    if (streakCompare != 0) return streakCompare;

    return a.profile.nickname.compareTo(b.profile.nickname);
  }

  int _sortNullableDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  Future<void> _ensureSeedProfiles() async {
    final existing = await DatabaseService.getAllFriendProfiles();
    if (existing.length >= _seedNames.length) {
      return;
    }

    await DatabaseService.upsertFriendProfiles(_buildSeedProfiles());
  }

  List<FriendProfile> _buildSeedProfiles() {
    return List.generate(_seedNames.length, (index) {
      final seed = _stableSeed('friend-profile-$index');
      final random = Random(seed);
      final avatarConfig = AvatarConfig.random(random).toJson();
      final lastActiveAt = DateTime.now().subtract(
        Duration(hours: random.nextInt(72), minutes: random.nextInt(60)),
      );
      return FriendProfile(
        id: 'mint_pal_${(index + 1).toString().padLeft(3, '0')}',
        nickname: _seedNames[index],
        avatarConfig: avatarConfig,
        totalCheckIns: 24 + random.nextInt(180),
        currentStreak: 1 + random.nextInt(36),
        activeGoals: 1 + random.nextInt(4),
        lastActiveAt: lastActiveAt,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  FriendSearchResult _buildSearchResultForProfile(FriendProfile profile) {
    if (profile.id == currentUserId) {
      return FriendSearchResult(
        profile: profile,
        relationType: FriendRelationType.self,
      );
    }

    final friendship = getFriendshipWith(profile.id);
    if (friendship == null) {
      return FriendSearchResult(
        profile: profile,
        relationType: FriendRelationType.none,
      );
    }

    final relationType = switch (friendship.status) {
      FriendshipStatus.accepted => FriendRelationType.friend,
      FriendshipStatus.blocked => FriendRelationType.blocked,
      FriendshipStatus.pending =>
        friendship.friendId == currentUserId
            ? FriendRelationType.incomingPending
            : FriendRelationType.outgoingPending,
    };

    return FriendSearchResult(
      profile: profile,
      relationType: relationType,
      friendship: friendship,
    );
  }

  FriendProfile? _buildCurrentUserSearchProfile() {
    final userId = _currentUserId;
    final profile = _userProfileProvider?.profile;
    if (userId == null || profile == null) return null;

    return FriendProfile(
      id: userId,
      nickname: profile.nickname,
      avatarAssetPath: profile.avatarAssetPath,
      avatarConfig: _avatarConfigMap(profile),
    );
  }

  FriendProfile _buildFallbackProfile(String userId) {
    final random = Random(_stableSeed('fallback-$userId'));
    final shortId = userId.length <= 6 ? userId : userId.substring(0, 6);
    return FriendProfile(
      id: userId,
      nickname: '用户 $shortId',
      avatarConfig: AvatarConfig.random(random).toJson(),
      totalCheckIns: 0,
      currentStreak: 0,
      activeGoals: 0,
    );
  }

  void _rebuildActivityCache(List<FriendRecord> records) {
    final nextCache = <String, List<SocialPost>>{};
    for (final record in records) {
      nextCache[record.profile.id] = _buildSyntheticActivity(record.profile);
    }
    _activityCache
      ..clear()
      ..addAll(nextCache);
  }

  List<SocialPost> _buildSyntheticActivity(FriendProfile profile) {
    final random = Random(_stableSeed('activity-${profile.id}'));
    final count = 4 + random.nextInt(4);

    return List.generate(count, (index) {
      final createdAt = DateTime.now().subtract(
        Duration(
          days: random.nextInt(6),
          hours: random.nextInt(23),
          minutes: random.nextInt(59) + index * 3,
        ),
      );
      return SocialPost(
        id: 'friend-post-${profile.id}-$index',
        userId: profile.id,
        userName: profile.nickname,
        userAvatar: profile.avatarAssetPath,
        avatarConfig: profile.parsedAvatarConfig,
        content: _activityContents[random.nextInt(_activityContents.length)],
        goalTitle: _activityGoals[random.nextInt(_activityGoals.length)],
        streak: max(1, profile.currentStreak - random.nextInt(3)),
        type: PostType.checkIn,
        likeCount: 3 + random.nextInt(48),
        commentCount: random.nextInt(9),
        isLikedByMe: false,
        createdAt: createdAt,
        isFriendActivity: true,
      );
    })..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int _stableSeed(String input) {
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  Map<String, dynamic>? _avatarConfigMap(UserProfileModel profile) {
    return profile.avatarConfig?.toJson();
  }
}
