import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/user_profile_model.dart';
import '../models/achievement.dart';
import '../models/check_in.dart';
import '../models/comment.dart';
import '../models/friendship.dart';
import '../models/goal.dart';
import '../models/nft_asset.dart';
import '../models/social_post.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_profile_prefs.dart';
import 'check_in_provider.dart';
import 'goal_provider.dart';
import 'user_profile_provider.dart';

enum SocialFeedTab { recommended, friends, mine }

enum SocialNotificationType { comments, likes, friendRequests }

class SocialNotificationItem {
  const SocialNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.unreadCount,
  });

  final String id;
  final SocialNotificationType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final int unreadCount;
}

class SocialProvider extends ChangeNotifier {
  SocialProvider({
    required CheckInProvider checkInProvider,
    required GoalProvider goalProvider,
    required UserProfileProvider userProfileProvider,
  }) : _checkInProvider = checkInProvider,
       _goalProvider = goalProvider,
       _userProfileProvider = userProfileProvider;

  static const _feedPageSize = 20;
  static const _commentsPageSize = 20;

  final AuthService _authService = const AuthService();
  final Uuid _uuid = const Uuid();

  CheckInProvider _checkInProvider;
  GoalProvider _goalProvider;
  UserProfileProvider _userProfileProvider;

  final Map<String, SocialPost> _postStateById = <String, SocialPost>{};
  final List<String> _allPostIds = <String>[];
  final Map<SocialFeedTab, List<String>> _feedIds =
      <SocialFeedTab, List<String>>{
        SocialFeedTab.recommended: <String>[],
        SocialFeedTab.friends: <String>[],
        SocialFeedTab.mine: <String>[],
      };
  final Map<SocialFeedTab, int> _visibleCounts = <SocialFeedTab, int>{
    SocialFeedTab.recommended: _feedPageSize,
    SocialFeedTab.friends: _feedPageSize,
    SocialFeedTab.mine: _feedPageSize,
  };
  final Map<SocialFeedTab, bool> _loadingMoreByTab = <SocialFeedTab, bool>{
    SocialFeedTab.recommended: false,
    SocialFeedTab.friends: false,
    SocialFeedTab.mine: false,
  };
  final Set<String> _publishedCheckInIds = <String>{};
  final Set<String> _publishedNftIds = <String>{};
  final Map<String, List<Comment>> _commentsByPostId =
      <String, List<Comment>>{};
  final Map<String, int> _commentOffsets = <String, int>{};
  final Map<String, bool> _hasMoreComments = <String, bool>{};
  final Map<String, bool> _isLoadingComments = <String, bool>{};
  final Map<String, bool> _isLoadingMoreComments = <String, bool>{};
  final Set<String> _preparingPostIds = <String>{};
  final List<SocialNotificationItem> _notifications =
      <SocialNotificationItem>[];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _didInit = false;
  bool _dependencyRefreshQueued = false;
  String _dependencySignature = '';
  String? _currentUserId;
  DateTime? _lastNotificationSeenAt;
  int _unreadInteractionCount = 0;
  Set<String> _friendIds = <String>{};
  int _incomingFriendRequestCount = 0;
  DateTime? _latestIncomingFriendRequestAt;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String get currentUserId => _currentUserId ?? '';
  int get unreadInteractionCount => _unreadInteractionCount;
  int get incomingFriendRequestCount => _incomingFriendRequestCount;
  List<SocialNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  void updateDependencies({
    required CheckInProvider checkInProvider,
    required GoalProvider goalProvider,
    required UserProfileProvider userProfileProvider,
  }) {
    _checkInProvider = checkInProvider;
    _goalProvider = goalProvider;
    _userProfileProvider = userProfileProvider;

    final nextSignature = _buildDependencySignature();
    if (!_didInit || nextSignature == _dependencySignature) {
      _dependencySignature = nextSignature;
      return;
    }

    _dependencySignature = nextSignature;
    if (_dependencyRefreshQueued) return;

    _dependencyRefreshQueued = true;
    Future<void>.microtask(() async {
      _dependencyRefreshQueued = false;
      await refresh(silent: true);
    });
  }

  Future<void> init() async {
    if (_didInit) return;
    _didInit = true;
    _dependencySignature = _buildDependencySignature();
    _isLoading = true;
    notifyListeners();

    try {
      await _reloadAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SocialPost> feedFor(SocialFeedTab tab) {
    final ids = _feedIds[tab] ?? const <String>[];
    final visibleCount = _visibleCounts[tab] ?? _feedPageSize;
    return ids
        .take(visibleCount)
        .map((id) => _postForFeed(id, tab))
        .whereType<SocialPost>()
        .toList(growable: false);
  }

  int totalCountFor(SocialFeedTab tab) {
    return _feedIds[tab]?.length ?? 0;
  }

  bool hasMoreFor(SocialFeedTab tab) {
    return (_visibleCounts[tab] ?? _feedPageSize) < totalCountFor(tab);
  }

  bool isLoadingMoreFor(SocialFeedTab tab) {
    return _loadingMoreByTab[tab] ?? false;
  }

  bool hasPublishedCheckIn(String checkInId) {
    return _publishedCheckInIds.contains(checkInId);
  }

  bool hasPublishedNft(String nftId) {
    return _publishedNftIds.contains(nftId);
  }

  SocialPost resolvePost(SocialPost post) {
    final stored = _postStateById[post.id];
    if (stored == null) return post;
    return stored.copyWith(isFriendActivity: post.isFriendActivity);
  }

  List<Comment> commentsForPost(String postId) {
    return List.unmodifiable(_commentsByPostId[postId] ?? const <Comment>[]);
  }

  bool isLoadingCommentsFor(String postId) {
    return _isLoadingComments[postId] ?? false;
  }

  bool isLoadingMoreCommentsFor(String postId) {
    return _isLoadingMoreComments[postId] ?? false;
  }

  bool hasMoreCommentsFor(String postId) {
    return _hasMoreComments[postId] ?? false;
  }

  Future<void> loadMore(SocialFeedTab tab) async {
    if ((_loadingMoreByTab[tab] ?? false) || !hasMoreFor(tab)) return;

    _loadingMoreByTab[tab] = true;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      _visibleCounts[tab] =
          (_visibleCounts[tab] ?? _feedPageSize) + _feedPageSize;
    } finally {
      _loadingMoreByTab[tab] = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    if (!silent) notifyListeners();

    try {
      await _reloadAll();
    } finally {
      _isRefreshing = false;
    }

    notifyListeners();
  }

  Future<void> preparePost(SocialPost post) async {
    if (_preparingPostIds.contains(post.id)) return;
    _preparingPostIds.add(post.id);

    try {
      await _ensureCurrentUserId();
      await DatabaseService.ensureSocialPost(
        post.copyWith(
          likeCount: _postStateById[post.id]?.likeCount ?? post.likeCount,
          commentCount:
              _postStateById[post.id]?.commentCount ?? post.commentCount,
          shareCount: _postStateById[post.id]?.shareCount ?? post.shareCount,
        ),
      );
      final stored = await DatabaseService.getSocialPostById(
        post.id,
        currentUserId: _currentUserId,
      );
      _postStateById[post.id] = stored ?? post;
    } finally {
      _preparingPostIds.remove(post.id);
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId, {SocialPost? fallbackPost}) async {
    await _ensureCurrentUserId();
    if (_currentUserId == null) return;

    if (!_postStateById.containsKey(postId) && fallbackPost != null) {
      await preparePost(fallbackPost);
    }
    if (!_postStateById.containsKey(postId)) return;

    await DatabaseService.togglePostLike(postId, _currentUserId!);
    final stored = await DatabaseService.getSocialPostById(
      postId,
      currentUserId: _currentUserId,
    );
    if (stored == null) return;

    _postStateById[postId] = stored;
    notifyListeners();
  }

  Future<void> recordShare(String postId) async {
    final nextCount = await DatabaseService.incrementPostShareCount(postId);
    final current = _postStateById[postId];
    if (current != null) {
      _postStateById[postId] = current.copyWith(shareCount: nextCount);
      notifyListeners();
    }
  }

  Future<bool> publishCheckIn(
    CheckIn checkIn,
    Goal goal, {
    PostVisibility visibility = PostVisibility.public,
  }) async {
    if (_publishedCheckInIds.contains(checkIn.id)) {
      return false;
    }

    await _ensureCurrentUserId();
    final profile = _resolvedProfile;
    final post = SocialPost(
      id: _uuid.v4(),
      userId: _currentUserId ?? 'me',
      userName: profile.nickname,
      userAvatar: profile.avatarAssetPath,
      avatarConfig: profile.avatarConfig,
      content: _buildPublishedCheckInContent(checkIn),
      type: PostType.checkIn,
      visibility: visibility,
      title: goal.title,
      subtitle: '分享了一次打卡',
      goalId: goal.id,
      goalTitle: goal.title,
      mood: checkIn.mood,
      streak: _checkInProvider.getStreak(goal.id),
      imagePaths: checkIn.imagePaths.take(3).toList(growable: false),
      metadata: <String, dynamic>{
        'status': checkIn.status.value,
        'mode': checkIn.mode.value,
        'date': checkIn.date.toIso8601String(),
      },
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      isLikedByMe: false,
      createdAt: DateTime.now(),
      sourceCheckInId: checkIn.id,
      sourceGoalId: goal.id,
    );

    await DatabaseService.upsertSocialPost(post);
    _savePostState(post);
    _publishedCheckInIds.add(checkIn.id);
    _rebuildFeedIds();
    notifyListeners();
    return true;
  }

  Future<bool> publishNft(
    NftAsset asset, {
    PostVisibility visibility = PostVisibility.public,
  }) async {
    if (_publishedNftIds.contains(asset.id) ||
        asset.status != NftStatus.minted) {
      return false;
    }

    await _ensureCurrentUserId();
    final profile = _resolvedProfile;
    final mintedAt = asset.mintedAt ?? DateTime.now();
    final post = SocialPost(
      id: _uuid.v4(),
      userId: _currentUserId ?? 'me',
      userName: profile.nickname,
      userAvatar: profile.avatarAssetPath,
      avatarConfig: profile.avatarConfig,
      content: asset.description,
      type: PostType.nftMint,
      visibility: visibility,
      title: asset.title,
      subtitle: '刚刚展示了一张新铸造的 NFT',
      imagePaths: <String>[asset.imagePath],
      metadata: <String, dynamic>{
        'category': asset.category.value,
        'rarity': asset.effectiveRarity.value,
        'rarityLabel': asset.effectiveRarity.label,
        'tokenId': asset.tokenId,
        'txHash': asset.txHash,
        'mintedAt': mintedAt.toIso8601String(),
      },
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      isLikedByMe: false,
      createdAt: mintedAt,
      sourceNftId: asset.id,
      sourceCheckInId: asset.checkInId,
    );

    await DatabaseService.upsertSocialPost(post);
    _savePostState(post);
    _publishedNftIds.add(asset.id);
    _rebuildFeedIds();
    notifyListeners();
    return true;
  }

  Future<SocialPost?> publishThought({
    required String content,
    List<String> imagePaths = const <String>[],
    PostVisibility visibility = PostVisibility.public,
  }) async {
    final normalized = _normalize(content);
    if (normalized == null) return null;

    await _ensureCurrentUserId();
    final profile = _resolvedProfile;
    final post = SocialPost(
      id: _uuid.v4(),
      userId: _currentUserId ?? 'me',
      userName: profile.nickname,
      userAvatar: profile.avatarAssetPath,
      avatarConfig: profile.avatarConfig,
      content: normalized,
      type: PostType.thought,
      visibility: visibility,
      title: '发布了一个想法',
      subtitle: imagePaths.isEmpty ? '文字动态' : '文字 + 图片动态',
      imagePaths: imagePaths.take(3).toList(growable: false),
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      isLikedByMe: false,
      createdAt: DateTime.now(),
    );

    await DatabaseService.upsertSocialPost(post);
    _savePostState(post);
    _rebuildFeedIds();
    notifyListeners();
    return post;
  }

  Future<void> loadComments(String postId, {bool refresh = false}) async {
    await _ensureCurrentUserId();
    if (_isLoadingComments[postId] == true) return;
    if (!refresh && _commentsByPostId.containsKey(postId)) return;

    _isLoadingComments[postId] = true;
    if (refresh) {
      _commentsByPostId.remove(postId);
      _commentOffsets[postId] = 0;
      _hasMoreComments[postId] = true;
    }
    notifyListeners();

    try {
      final comments = await DatabaseService.getCommentsByPost(
        postId,
        limit: _commentsPageSize,
        offset: 0,
        currentUserId: _currentUserId,
      );
      _commentsByPostId[postId] = comments;
      _commentOffsets[postId] = comments.length;
      _hasMoreComments[postId] = comments.length == _commentsPageSize;

      final count = await DatabaseService.syncSocialPostCommentCount(postId);
      _updatePostCommentCount(postId, count);
    } finally {
      _isLoadingComments[postId] = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreComments(String postId) async {
    await _ensureCurrentUserId();
    if (_isLoadingMoreComments[postId] == true) return;
    if (!(_hasMoreComments[postId] ?? true)) return;

    _isLoadingMoreComments[postId] = true;
    notifyListeners();

    try {
      final offset = _commentOffsets[postId] ?? 0;
      final more = await DatabaseService.getCommentsByPost(
        postId,
        limit: _commentsPageSize,
        offset: offset,
        currentUserId: _currentUserId,
      );

      final current = List<Comment>.from(
        _commentsByPostId[postId] ?? const <Comment>[],
      );
      current.addAll(more);
      _commentsByPostId[postId] = current;
      _commentOffsets[postId] = current.length;
      _hasMoreComments[postId] = more.length == _commentsPageSize;
    } finally {
      _isLoadingMoreComments[postId] = false;
      notifyListeners();
    }
  }

  Future<Comment?> addComment(
    String postId,
    String content, {
    String? parentId,
    String? replyToName,
  }) async {
    final normalized = _normalize(content);
    if (normalized == null) return null;

    await _ensureCurrentUserId();
    final profile = _resolvedProfile;
    final comment = Comment(
      id: _uuid.v4(),
      postId: postId,
      authorId: _currentUserId ?? 'me',
      authorName: profile.nickname,
      authorAvatar: profile.avatarAssetPath,
      authorAvatarConfig: _avatarConfigMap(profile),
      content: normalized,
      parentId: parentId,
      replyToName: replyToName,
      createdAt: DateTime.now(),
      likeCount: 0,
      isLiked: false,
    );

    await DatabaseService.insertComment(comment);
    final current = List<Comment>.from(
      _commentsByPostId[postId] ?? const <Comment>[],
    );
    current.insert(0, comment);
    _commentsByPostId[postId] = current;
    _commentOffsets[postId] = current.length;

    final count = await DatabaseService.syncSocialPostCommentCount(postId);
    _updatePostCommentCount(postId, count);
    await _loadNotifications();
    notifyListeners();
    return comment;
  }

  Future<bool> deleteComment(String commentId) async {
    await _ensureCurrentUserId();
    final cached = _findCachedComment(commentId);
    final comment =
        cached?.comment ??
        await DatabaseService.getCommentById(
          commentId,
          currentUserId: _currentUserId,
        );
    if (comment == null || comment.authorId != _currentUserId) {
      return false;
    }

    final deletedCount = await DatabaseService.deleteComment(commentId);
    if (deletedCount <= 0) {
      return false;
    }

    await loadComments(comment.postId, refresh: true);
    await _loadNotifications();
    return true;
  }

  Future<void> toggleCommentLike(String commentId) async {
    await _ensureCurrentUserId();
    if (_currentUserId == null) return;

    final cached = _findCachedComment(commentId);
    final postId =
        cached?.postId ??
        (await DatabaseService.getCommentById(
          commentId,
          currentUserId: _currentUserId,
        ))?.postId;
    if (postId == null) return;

    final nextLiked = await DatabaseService.toggleCommentLike(
      commentId,
      _currentUserId!,
    );

    final comments = List<Comment>.from(
      _commentsByPostId[postId] ?? const <Comment>[],
    );
    final commentIndex = comments.indexWhere((item) => item.id == commentId);
    if (commentIndex != -1) {
      final current = comments[commentIndex];
      comments[commentIndex] = current.copyWith(
        isLiked: nextLiked,
        likeCount: max(0, current.likeCount + (nextLiked ? 1 : -1)),
      );
      _commentsByPostId[postId] = comments;
    }

    notifyListeners();
  }

  Future<void> markNotificationsRead() async {
    if (_currentUserId == null) return;
    final now = DateTime.now();
    _lastNotificationSeenAt = now;
    _unreadInteractionCount = 0;
    await UserProfilePrefs.setSocialNotificationLastSeen(_currentUserId!, now);
    notifyListeners();
  }

  Future<void> _reloadAll() async {
    await _ensureCurrentUserId();
    if (_currentUserId == null) return;

    await DatabaseService.deleteLegacyMockSocialPosts();
    await _loadNotificationSeenAt();
    await _syncRelationshipContext();
    await _ensureOfficialPosts();
    await _syncDerivedPosts();
    await _reloadStoredPosts();
    _rebuildFeedIds();
    await _loadNotifications();
    _resetPagination();
  }

  Future<void> _syncRelationshipContext() async {
    if (_currentUserId == null) return;

    final accepted = await DatabaseService.getFriendshipsForUser(
      _currentUserId!,
      status: FriendshipStatus.accepted,
    );
    _friendIds = accepted
        .map((item) => item.otherUserId(_currentUserId!))
        .where((item) => item.trim().isNotEmpty)
        .toSet();

    final pending = await DatabaseService.getFriendshipsForUser(
      _currentUserId!,
      status: FriendshipStatus.pending,
    );
    final incoming =
        pending.where((item) => item.friendId == _currentUserId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _incomingFriendRequestCount = incoming.length;
    _latestIncomingFriendRequestAt = incoming.isEmpty
        ? null
        : incoming.first.createdAt;
  }

  Future<void> _ensureOfficialPosts() async {
    final posts = <SocialPost>[
      SocialPost(
        id: 'official-social-welcome',
        userId: 'official_mintday',
        userName: 'MintDay 官方',
        content: '这里不只是晒结果，也欢迎你分享过程里的犹豫、坚持和小突破。',
        type: PostType.thought,
        visibility: PostVisibility.public,
        title: '欢迎来到成长广场',
        subtitle: '把真实进展发出来，社区才会慢慢热起来',
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLikedByMe: false,
        createdAt: DateTime(2026, 4, 1, 9, 30),
        isOfficial: true,
      ),
      SocialPost(
        id: 'official-social-friends',
        userId: 'official_mintday',
        userName: 'MintDay 官方',
        content: '先去加几个一起打卡的朋友吧。好友页里的动态会优先出现在推荐里，也能只看好友最近在坚持什么。',
        type: PostType.thought,
        visibility: PostVisibility.public,
        title: '好友动态会优先出现',
        subtitle: '关系越真实，广场越有温度',
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLikedByMe: false,
        createdAt: DateTime(2026, 4, 2, 19, 0),
        isOfficial: true,
      ),
      SocialPost(
        id: 'official-social-share',
        userId: 'official_mintday',
        userName: 'MintDay 官方',
        content: '公开打卡、分享 NFT、发一条想法，都能让你的成长轨迹更完整，也更容易遇到同路人。',
        type: PostType.thought,
        visibility: PostVisibility.public,
        title: '试试发出第一条动态',
        subtitle: '从一条打卡开始建立社区感',
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLikedByMe: false,
        createdAt: DateTime(2026, 4, 4, 12, 0),
        isOfficial: true,
      ),
    ];

    for (final post in posts) {
      await _upsertGeneratedPost(post);
    }
  }

  Future<void> _syncDerivedPosts() async {
    final profile = _resolvedProfile;
    final goalsById = <String, Goal>{
      for (final goal in _goalProvider.goals) goal.id: goal,
    };

    await _syncAchievementPosts(profile);
    await _syncMilestonePosts(profile, goalsById);
    await _syncGoalCompletionPosts(profile);
  }

  Future<void> _syncAchievementPosts(UserProfileModel profile) async {
    final unlocks = await DatabaseService.getAllAchievementUnlocks();
    for (final unlock in unlocks) {
      final matched = AchievementId.values.where(
        (item) => item.name == unlock.achievementId,
      );
      if (matched.isEmpty) continue;
      final definition = AchievementCatalog.byId[matched.first];
      if (definition == null) continue;

      final post = SocialPost(
        id: 'achievement-${unlock.achievementId}',
        userId: currentUserId,
        userName: profile.nickname,
        userAvatar: profile.avatarAssetPath,
        avatarConfig: profile.avatarConfig,
        content: '解锁了一个新的成长成就，继续把这股劲头保持下去。',
        type: PostType.achievement,
        visibility: PostVisibility.public,
        title: definition.title,
        subtitle: definition.subtitle,
        metadata: <String, dynamic>{
          'dimension': definition.dimension.value,
          'achievementId': unlock.achievementId,
        },
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLikedByMe: false,
        createdAt: unlock.unlockedAt,
        sourceAchievementId: unlock.achievementId,
      );

      await _upsertGeneratedPost(post);
    }
  }

  Future<void> _syncMilestonePosts(
    UserProfileModel profile,
    Map<String, Goal> goalsById,
  ) async {
    for (final goal in _goalProvider.goals) {
      final milestones = await DatabaseService.getMilestonesByGoal(goal.id);
      for (final milestone in milestones.where((item) => item.isUnlocked)) {
        final post = SocialPost(
          id: 'milestone-${milestone.id}',
          userId: currentUserId,
          userName: profile.nickname,
          userAvatar: profile.avatarAssetPath,
          avatarConfig: profile.avatarConfig,
          content: milestone.description ?? '完成了一个阶段里程碑，继续向前。',
          type: PostType.milestone,
          visibility: goal.isPublic
              ? PostVisibility.public
              : PostVisibility.friends,
          title: milestone.title,
          subtitle:
              '在 ${goalsById[milestone.goalId]?.title ?? goal.title} 上点亮了新节点',
          goalId: goal.id,
          goalTitle: goal.title,
          metadata: <String, dynamic>{
            'milestoneType': milestone.type.value,
            'targetValue': milestone.targetValue,
            'currentValue': milestone.currentValue,
            'isMinted': milestone.isMinted,
            'mintTxHash': milestone.mintTxHash,
            'cardImagePath': milestone.cardImagePath,
          },
          likeCount: 0,
          commentCount: 0,
          shareCount: 0,
          isLikedByMe: false,
          createdAt: milestone.unlockedAt ?? goal.updatedAt,
          sourceGoalId: goal.id,
          sourceMilestoneId: milestone.id,
        );

        await _upsertGeneratedPost(post);
      }
    }
  }

  Future<void> _syncGoalCompletionPosts(UserProfileModel profile) async {
    for (final goal in _goalProvider.goals.where(
      (item) => item.status == GoalStatus.completed,
    )) {
      final checkIns = _checkInProvider
          .getCheckInsForGoal(goal.id)
          .where((item) => item.status != CheckInStatus.skipped)
          .toList(growable: false);
      final finishedAt = checkIns.isNotEmpty
          ? checkIns
                .map((item) => item.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
          : goal.updatedAt;
      final daysSpent = max(
        1,
        finishedAt.difference(goal.createdAt).inDays + 1,
      );
      final stepsCount = max(1, goal.steps.length);
      final post = SocialPost(
        id: 'goal-complete-${goal.id}',
        userId: currentUserId,
        userName: profile.nickname,
        userAvatar: profile.avatarAssetPath,
        avatarConfig: profile.avatarConfig,
        content: goal.reward ?? '这段坚持已经抵达终点，也会成为下一段成长的起点。',
        type: PostType.goalComplete,
        visibility: goal.isPublic
            ? PostVisibility.public
            : PostVisibility.friends,
        title: goal.title,
        subtitle: '目标完成，100% 抵达',
        goalId: goal.id,
        goalTitle: goal.title,
        metadata: <String, dynamic>{
          'daysSpent': daysSpent,
          'checkInCount': checkIns.length,
          'completedSteps': goal.completedStepCount,
          'totalSteps': stepsCount,
          'progress': 1.0,
        },
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLikedByMe: false,
        createdAt: finishedAt,
        sourceGoalId: goal.id,
      );

      await _upsertGeneratedPost(post);
    }
  }

  Future<void> _upsertGeneratedPost(SocialPost post) async {
    final existing =
        _postStateById[post.id] ??
        await DatabaseService.getSocialPostById(
          post.id,
          currentUserId: _currentUserId,
        );
    final merged = post.copyWith(
      likeCount: existing?.likeCount ?? post.likeCount,
      commentCount: existing?.commentCount ?? post.commentCount,
      shareCount: existing?.shareCount ?? post.shareCount,
      isLikedByMe: existing?.isLikedByMe ?? post.isLikedByMe,
    );
    await DatabaseService.upsertSocialPost(merged);
  }

  Future<void> _reloadStoredPosts() async {
    final stored = await DatabaseService.getSocialPosts(
      currentUserId: _currentUserId,
    );
    _postStateById
      ..clear()
      ..addEntries(stored.map((post) => MapEntry(post.id, post)));
    _allPostIds
      ..clear()
      ..addAll(
        stored
            .where((post) => !post.userId.startsWith('mock-'))
            .map((post) => post.id),
      );
    _publishedCheckInIds
      ..clear()
      ..addAll(
        stored
            .where(
              (post) =>
                  post.userId == _currentUserId && post.sourceCheckInId != null,
            )
            .map((post) => post.sourceCheckInId!)
            .toSet(),
      );
    _publishedNftIds
      ..clear()
      ..addAll(
        stored
            .where(
              (post) =>
                  post.userId == _currentUserId && post.sourceNftId != null,
            )
            .map((post) => post.sourceNftId!)
            .toSet(),
      );
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;

    final unreadLikeSummary = await DatabaseService.getLikeSummaryForUserPosts(
      _currentUserId!,
      since: _lastNotificationSeenAt,
    );
    final unreadCommentSummary =
        await DatabaseService.getCommentSummaryForUserPosts(
          _currentUserId!,
          since: _lastNotificationSeenAt,
        );
    final latestLikeSummary = await DatabaseService.getLikeSummaryForUserPosts(
      _currentUserId!,
    );
    final latestCommentSummary =
        await DatabaseService.getCommentSummaryForUserPosts(_currentUserId!);

    final unreadLikeCount = unreadLikeSummary['count'] as int? ?? 0;
    final unreadCommentCount = unreadCommentSummary['count'] as int? ?? 0;
    final unreadFriendRequestCount = _incomingFriendRequestCount;

    _unreadInteractionCount =
        unreadLikeCount + unreadCommentCount + unreadFriendRequestCount;

    final items = <SocialNotificationItem>[];
    final latestCommentCount = latestCommentSummary['count'] as int? ?? 0;
    final latestCommentAt = _parseDateTime(latestCommentSummary['latest_at']);
    if (latestCommentCount > 0 && latestCommentAt != null) {
      items.add(
        SocialNotificationItem(
          id: 'comments',
          type: SocialNotificationType.comments,
          title: '你的动态收到了 $latestCommentCount 条评论',
          subtitle: '打开帖子详情，继续把对话聊下去。',
          createdAt: latestCommentAt,
          unreadCount: unreadCommentCount,
        ),
      );
    }

    final latestLikeCount = latestLikeSummary['count'] as int? ?? 0;
    final latestLikeAt = _parseDateTime(latestLikeSummary['latest_at']);
    if (latestLikeCount > 0 && latestLikeAt != null) {
      items.add(
        SocialNotificationItem(
          id: 'likes',
          type: SocialNotificationType.likes,
          title: '你的动态新增了 $latestLikeCount 个赞',
          subtitle: '有人正在为你的坚持鼓掌。',
          createdAt: latestLikeAt,
          unreadCount: unreadLikeCount,
        ),
      );
    }

    if (_incomingFriendRequestCount > 0 &&
        _latestIncomingFriendRequestAt != null) {
      items.add(
        SocialNotificationItem(
          id: 'friend-requests',
          type: SocialNotificationType.friendRequests,
          title: '有 $_incomingFriendRequestCount 个新的好友请求',
          subtitle: '去好友页看看是谁想和你一起坚持。',
          createdAt: _latestIncomingFriendRequestAt!,
          unreadCount: unreadFriendRequestCount,
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notifications
      ..clear()
      ..addAll(items);
  }

  Future<void> _loadNotificationSeenAt() async {
    if (_currentUserId == null) return;
    final saved = await UserProfilePrefs.getSocialNotificationLastSeen(
      _currentUserId!,
    );
    if (saved != null) {
      _lastNotificationSeenAt = saved;
      return;
    }

    final now = DateTime.now();
    _lastNotificationSeenAt = now;
    await UserProfilePrefs.setSocialNotificationLastSeen(_currentUserId!, now);
  }

  void _rebuildFeedIds() {
    final allPosts = _allPostIds
        .map((id) => _postStateById[id])
        .whereType<SocialPost>()
        .toList(growable: false);

    final minePosts =
        allPosts
            .where((post) => post.userId == _currentUserId)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _feedIds[SocialFeedTab.mine] = minePosts
        .map((post) => post.id)
        .toList(growable: false);

    final friendPosts =
        allPosts
            .where(
              (post) =>
                  _friendIds.contains(post.userId) &&
                  post.userId != _currentUserId &&
                  (post.visibility == PostVisibility.public ||
                      post.visibility == PostVisibility.friends),
            )
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _feedIds[SocialFeedTab.friends] = friendPosts
        .map((post) => post.id)
        .toList(growable: false);

    _feedIds[SocialFeedTab.recommended] = _buildRecommendedIds(allPosts);
  }

  List<String> _buildRecommendedIds(List<SocialPost> allPosts) {
    final friendPool =
        allPosts
            .where(
              (post) =>
                  _friendIds.contains(post.userId) &&
                  post.userId != _currentUserId &&
                  !post.isOfficial,
            )
            .toList()
          ..sort((a, b) => _engagementScore(b).compareTo(_engagementScore(a)));

    final communityPool =
        allPosts
            .where(
              (post) =>
                  !post.isOfficial &&
                  !_friendIds.contains(post.userId) &&
                  post.userId != _currentUserId &&
                  post.visibility == PostVisibility.public,
            )
            .toList()
          ..sort((a, b) => _engagementScore(b).compareTo(_engagementScore(a)));

    final myPool =
        allPosts
            .where(
              (post) =>
                  post.userId == _currentUserId &&
                  post.visibility == PostVisibility.public,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final officialPool =
        allPosts
            .where(
              (post) =>
                  post.isOfficial && post.visibility == PostVisibility.public,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final result = <String>[];
    final seen = <String>{};
    var officialInserted = 0;

    void takeNext(List<SocialPost> pool) {
      while (pool.isNotEmpty) {
        final next = pool.removeAt(0);
        if (seen.add(next.id)) {
          result.add(next.id);
          break;
        }
      }
    }

    while (friendPool.isNotEmpty ||
        communityPool.isNotEmpty ||
        myPool.isNotEmpty ||
        officialPool.isNotEmpty) {
      if (friendPool.isNotEmpty &&
          (result.length < 4 || result.length.isEven)) {
        takeNext(friendPool);
      }
      if (communityPool.isNotEmpty) {
        takeNext(communityPool);
      }
      if (myPool.isNotEmpty && result.length >= 2 && result.length % 4 == 2) {
        takeNext(myPool);
      }
      if (officialPool.isNotEmpty &&
          officialInserted < 2 &&
          result.length >= 3 &&
          result.length % 5 == 3) {
        takeNext(officialPool);
        officialInserted++;
      }

      if (friendPool.isEmpty &&
          communityPool.isEmpty &&
          myPool.isEmpty &&
          officialPool.isNotEmpty &&
          officialInserted < 2) {
        takeNext(officialPool);
        officialInserted++;
      }

      if (friendPool.isEmpty && communityPool.isEmpty && myPool.isNotEmpty) {
        takeNext(myPool);
      }

      if (friendPool.isEmpty && communityPool.isNotEmpty && myPool.isEmpty) {
        takeNext(communityPool);
      }
    }

    return result;
  }

  double _engagementScore(SocialPost post) {
    final ageHours = DateTime.now().difference(post.createdAt).inHours;
    final recencyBoost = max(0, 96 - ageHours).toDouble();
    return post.likeCount * 3 +
        post.commentCount * 5 +
        post.shareCount * 4 +
        recencyBoost;
  }

  SocialPost? _postForFeed(String id, SocialFeedTab tab) {
    final post = _postStateById[id];
    if (post == null) return null;
    final isFriend =
        _friendIds.contains(post.userId) && post.userId != _currentUserId;
    return resolvePost(
      post.copyWith(
        isFriendActivity:
            tab != SocialFeedTab.mine && !post.isOfficial && isFriend,
      ),
    );
  }

  void _savePostState(SocialPost post) {
    _postStateById[post.id] = post;
    _allPostIds.remove(post.id);
    _allPostIds.insert(0, post.id);
  }

  void _updatePostCommentCount(String postId, int count) {
    final current = _postStateById[postId];
    if (current != null) {
      _postStateById[postId] = current.copyWith(commentCount: count);
      _rebuildFeedIds();
    }
  }

  void _resetPagination() {
    for (final tab in SocialFeedTab.values) {
      _visibleCounts[tab] = _feedPageSize;
      _loadingMoreByTab[tab] = false;
    }
  }

  _CachedCommentRef? _findCachedComment(String commentId) {
    for (final entry in _commentsByPostId.entries) {
      final index = entry.value.indexWhere((item) => item.id == commentId);
      if (index == -1) continue;
      return _CachedCommentRef(postId: entry.key, comment: entry.value[index]);
    }
    return null;
  }

  Future<String> _ensureCurrentUserId() async {
    final authUserId = _authService.currentUser?.id.trim();
    if (authUserId != null && authUserId.isNotEmpty) {
      _currentUserId = authUserId;
      return authUserId;
    }

    final localId = await UserProfilePrefs.getLocalFriendUserId();
    _currentUserId = localId;
    return localId;
  }

  UserProfileModel get _resolvedProfile => _userProfileProvider.profile;

  String _buildDependencySignature() {
    final checkInSig = _checkInProvider.checkIns
        .map((item) => '${item.id}:${item.createdAt.toIso8601String()}')
        .join('|');
    final goalSig = _goalProvider.goals
        .map(
          (item) =>
              '${item.id}:${item.status.value}:${item.updatedAt.toIso8601String()}:${item.isPublic ? 1 : 0}',
        )
        .join('|');
    final profile = _resolvedProfile;
    return [
      _checkInProvider.checkIns.length,
      checkInSig,
      _goalProvider.goals.length,
      goalSig,
      profile.nickname,
      profile.avatarAssetPath ?? '',
      profile.avatarConfig?.toJson().toString() ?? '',
    ].join('#');
  }

  String _buildPublishedCheckInContent(CheckIn checkIn) {
    final note = _normalize(checkIn.note);
    final progress = _normalize(checkIn.reflectionProgress);
    final blocker = _normalize(checkIn.reflectionBlocker);
    final next = _normalize(checkIn.reflectionNext);

    if (note != null) return note;
    if (progress != null && next != null) {
      return '$progress 接下来想继续推进：$next';
    }
    if (progress != null) return progress;
    if (next != null) return '今天先推进到这里，下一步准备：$next';
    if (blocker != null) return '虽然遇到了一点卡点：$blocker，但还是决定继续记录今天。';

    return switch (checkIn.status) {
      CheckInStatus.done => '今天完成打卡，继续把节奏稳稳接住。',
      CheckInStatus.partial => '今天先完成了一部分，先保持不断线。',
      CheckInStatus.skipped => '今天没有完成原计划，但我还是认真记下了这一天。',
    };
  }

  String? _normalize(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll(RegExp(r'\s+'), ' ');
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, dynamic>? _avatarConfigMap(UserProfileModel profile) {
    return profile.avatarConfig?.toJson();
  }
}

class _CachedCommentRef {
  const _CachedCommentRef({required this.postId, required this.comment});

  final String postId;
  final Comment comment;
}
