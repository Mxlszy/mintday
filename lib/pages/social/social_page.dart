import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../models/nft_asset.dart';
import '../../models/social_post.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/nft_provider.dart';
import '../../providers/social_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/friend_avatar.dart';
import '../../widgets/local_image_preview.dart';
import '../../widgets/skeleton_loader.dart';
import 'friends_page.dart';
import 'post_detail_page.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: SocialFeedTab.values.length,
    vsync: this,
  );
  late final AnimationController _fabPulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _fabScale = Tween<double>(begin: 0.96, end: 1.04)
      .animate(
        CurvedAnimation(parent: _fabPulseController, curve: Curves.easeInOut),
      );

  @override
  void dispose() {
    _tabController.dispose();
    _fabPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();
    final checkInProvider = context.watch<CheckInProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final friendProvider = context.watch<FriendProvider>();
    final nftProvider = context.watch<NftProvider>();

    final shareableCheckIns = _buildShareableCheckIns(
      checkInProvider: checkInProvider,
      goalProvider: goalProvider,
    );
    final shareableNfts = nftProvider.assets
        .where((asset) => asset.status == NftStatus.minted)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          heroTag: 'social-fab',
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => _openPublishHub(
            context,
            shareableCheckIns: shareableCheckIns,
            shareableNfts: shareableNfts,
          ),
          label: const Text('发布'),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingM,
              ),
              child: _SocialHeader(
                socialProvider: socialProvider,
                friendProvider: friendProvider,
                shareableCount: shareableCheckIns.length + shareableNfts.length,
                onFriendsTap: () => Navigator.of(
                  context,
                ).push(sharedAxisRoute(const FriendsPage())),
                onNotificationsTap: () => _showNotifications(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.accent,
                  indicatorWeight: 3,
                  labelColor: AppTheme.textPrimary,
                  unselectedLabelColor: AppTheme.textHint,
                  labelStyle: AppTextStyle.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: const [
                    Tab(text: '推荐'),
                    Tab(text: '好友'),
                    Tab(text: '我的'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FeedTabView(
                    tab: SocialFeedTab.recommended,
                    emptyTitle: '广场还比较安静',
                    emptySubtitle: '添加好友，看看大家在坚持什么，再把你的第一条成长动态发出来。',
                    emptyActionLabel: '去添加好友',
                    onEmptyAction: () => Navigator.of(
                      context,
                    ).push(sharedAxisRoute(const FriendsPage())),
                  ),
                  _FeedTabView(
                    tab: SocialFeedTab.friends,
                    emptyTitle: '好友动态还没有出现',
                    emptySubtitle: '等朋友们开始分享后，这里会优先看到他们最近在坚持什么。',
                    emptyActionLabel: '管理好友',
                    onEmptyAction: () => Navigator.of(
                      context,
                    ).push(sharedAxisRoute(const FriendsPage())),
                  ),
                  _FeedTabView(
                    tab: SocialFeedTab.mine,
                    emptyTitle: '还没有自己的动态',
                    emptySubtitle: '完成第一次打卡、分享一张 NFT，或者发布一条想法，让成长轨迹开始发光。',
                    emptyActionLabel: '立即发布',
                    onEmptyAction: () => _openPublishHub(
                      context,
                      shareableCheckIns: shareableCheckIns,
                      shareableNfts: shareableNfts,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ShareableCheckInEntry> _buildShareableCheckIns({
    required CheckInProvider checkInProvider,
    required GoalProvider goalProvider,
  }) {
    final entries = <_ShareableCheckInEntry>[];
    for (final checkIn in checkInProvider.checkIns) {
      final goal = goalProvider.getGoalById(checkIn.goalId);
      if (goal == null || !goal.isPublic) continue;
      entries.add(_ShareableCheckInEntry(checkIn: checkIn, goal: goal));
    }
    entries.sort((a, b) => b.checkIn.createdAt.compareTo(a.checkIn.createdAt));
    return entries;
  }

  Future<void> _showNotifications(BuildContext context) async {
    final socialProvider = context.read<SocialProvider>();
    await socialProvider.markNotificationsRead();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final notifications = socialProvider.notifications;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text('互动提醒', style: AppTextStyle.h3),
              const SizedBox(height: AppTheme.spacingM),
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: Text(
                    '暂时还没有新的互动，继续发你的成长动态吧。',
                    style: AppTextStyle.bodySmall,
                  ),
                )
              else
                ...notifications.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            switch (item.type) {
                              SocialNotificationType.comments =>
                                Icons.chat_bubble_outline_rounded,
                              SocialNotificationType.likes =>
                                Icons.favorite_border_rounded,
                              SocialNotificationType.friendRequests =>
                                Icons.people_alt_outlined,
                            },
                            color: AppTheme.accentStrong,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: AppTextStyle.body),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: AppTextStyle.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatRelativeTime(item.createdAt),
                                  style: AppTextStyle.caption,
                                ),
                              ],
                            ),
                          ),
                          if (item.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${item.unreadCount}',
                                style: AppTextStyle.caption.copyWith(
                                  color: AppTheme.accentStrong,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPublishHub(
    BuildContext context, {
    required List<_ShareableCheckInEntry> shareableCheckIns,
    required List<NftAsset> shareableNfts,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text('发布成长动态', style: AppTextStyle.h3),
              const SizedBox(height: AppTheme.spacingS),
              Text('你可以分享打卡、NFT，或者发一条带图片的想法。', style: AppTextStyle.bodySmall),
              const SizedBox(height: AppTheme.spacingL),
              _PublishOptionTile(
                icon: Icons.check_circle_outline_rounded,
                title: '分享打卡',
                subtitle: '从最近的公开目标打卡中选择一条发出去',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openCheckInShareSheet(context, shareableCheckIns);
                },
              ),
              const SizedBox(height: AppTheme.spacingS),
              _PublishOptionTile(
                icon: Icons.auto_awesome_outlined,
                title: '分享 NFT',
                subtitle: '展示一张已经铸造完成的 NFT 卡片',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openNftShareSheet(context, shareableNfts);
                },
              ),
              const SizedBox(height: AppTheme.spacingS),
              _PublishOptionTile(
                icon: Icons.edit_note_rounded,
                title: '发布想法',
                subtitle: '写一条最多 280 字的想法，可选附带 3 张图片',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openThoughtComposer(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCheckInShareSheet(
    BuildContext context,
    List<_ShareableCheckInEntry> entries,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckInShareSheet(entries: entries),
    );
  }

  Future<void> _openNftShareSheet(
    BuildContext context,
    List<NftAsset> assets,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NftShareSheet(assets: assets),
    );
  }

  Future<void> _openThoughtComposer(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ThoughtComposerSheet(),
    );
  }
}

class _SocialHeader extends StatelessWidget {
  const _SocialHeader({
    required this.socialProvider,
    required this.friendProvider,
    required this.shareableCount,
    required this.onFriendsTap,
    required this.onNotificationsTap,
  });

  final SocialProvider socialProvider;
  final FriendProvider friendProvider;
  final int shareableCount;
  final VoidCallback onFriendsTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('成长广场', style: AppTextStyle.h1),
                  const SizedBox(height: 8),
                  Text(
                    '推荐会优先看到好友近况，再混合高互动公开动态和少量官方推荐。',
                    style: AppTextStyle.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            _IconBadgeButton(
              icon: Icons.notifications_none_rounded,
              badgeCount: socialProvider.unreadInteractionCount,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: AppTheme.spacingS),
            _IconBadgeButton(
              icon: Icons.people_alt_outlined,
              badgeCount: friendProvider.pendingRequestCount,
              onTap: onFriendsTap,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.neuRaised,
          ),
          child: Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: '推荐动态',
                  value:
                      '${socialProvider.totalCountFor(SocialFeedTab.recommended)}',
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: '好友动态',
                  value:
                      '${socialProvider.totalCountFor(SocialFeedTab.friends)}',
                ),
              ),
              Expanded(
                child: _MetricTile(label: '可分享素材', value: '$shareableCount'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyle.h3),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyle.caption),
      ],
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  const _IconBadgeButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: BorderSide(color: AppTheme.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: AppTheme.textSecondary),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
              child: Center(
                child: Text(
                  '${min(badgeCount, 99)}',
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedTabView extends StatefulWidget {
  const _FeedTabView({
    required this.tab,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyActionLabel,
    required this.onEmptyAction,
  });

  final SocialFeedTab tab;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;

  @override
  State<_FeedTabView> createState() => _FeedTabViewState();
}

class _FeedTabViewState extends State<_FeedTabView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 420) {
      context.read<SocialProvider>().loadMore(widget.tab);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final socialProvider = context.watch<SocialProvider>();
    final posts = socialProvider.feedFor(widget.tab);
    final isLoading = socialProvider.isLoading;
    final isLoadingMore = socialProvider.isLoadingMoreFor(widget.tab);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<SocialProvider>().refresh(),
          context.read<FriendProvider>().refresh(),
        ]);
      },
      color: AppTheme.primary,
      child: isLoading && posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                0,
                AppTheme.spacingL,
                140,
              ),
              children: const [_FeedSkeletonList()],
            )
          : posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                0,
                AppTheme.spacingL,
                140,
              ),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.58,
                  child: _SocialEmptyState(
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                    actionLabel: widget.emptyActionLabel,
                    onAction: widget.onEmptyAction,
                  ),
                ),
              ],
            )
          : _MasonryFeedList(
              key: PageStorageKey('social-feed-${widget.tab.name}'),
              controller: _scrollController,
              posts: posts,
              isLoadingMore: isLoadingMore,
            ),
    );
  }
}

class _MasonryFeedList extends StatelessWidget {
  const _MasonryFeedList({
    super.key,
    required this.controller,
    required this.posts,
    required this.isLoadingMore,
  });

  final ScrollController controller;
  final List<SocialPost> posts;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(posts);
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        0,
        AppTheme.spacingL,
        140,
      ),
      itemCount: rows.length + 1,
      itemBuilder: (context, index) {
        if (index >= rows.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingM),
            child: Center(
              child: isLoadingMore
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppTheme.primary,
                      ),
                    )
                  : Text('继续上滑，看看大家最近的进展', style: AppTextStyle.caption),
            ),
          );
        }

        final row = rows[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    _SocialPostCard(post: row.left),
                    if (row.right != null) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      _SocialPostCard(post: row.right!),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SocialPostCard(post: row.left)),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: row.right == null
                        ? const SizedBox.shrink()
                        : _SocialPostCard(post: row.right!),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<_MasonryRow> _buildRows(List<SocialPost> source) {
    final columns = <List<SocialPost>>[<SocialPost>[], <SocialPost>[]];
    final heights = [0.0, 0.0];

    for (final post in source) {
      final target = heights[0] <= heights[1] ? 0 : 1;
      columns[target].add(post);
      heights[target] += _estimateHeight(post);
    }

    final maxLength = max(columns[0].length, columns[1].length);
    return List<_MasonryRow>.generate(maxLength, (index) {
      return _MasonryRow(
        left: columns[0][index],
        right: index < columns[1].length ? columns[1][index] : null,
      );
    });
  }

  double _estimateHeight(SocialPost post) {
    var height = 178 + post.content.length * 0.35;
    if (post.title != null) height += 26;
    if (post.subtitle != null) height += 24;
    if (post.goalTitle != null) height += 34;
    if (post.imagePaths.isNotEmpty) {
      height += post.type == PostType.nftMint ? 180 : 136;
    }
    if (post.type == PostType.checkIn) height += 54;
    if (post.type == PostType.goalComplete || post.type == PostType.milestone) {
      height += 56;
    }
    return height;
  }
}

class _MasonryRow {
  const _MasonryRow({required this.left, this.right});

  final SocialPost left;
  final SocialPost? right;
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();
    final resolvedPost = socialProvider.resolvePost(post);
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(sharedAxisRoute(PostDetailPage(post: resolvedPost))),
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.neuSubtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FriendAvatar(
                  label: resolvedPost.userName,
                  avatarAssetPath: resolvedPost.userAvatar,
                  avatarConfig: resolvedPost.avatarConfig,
                  size: 42,
                  borderRadius: 16,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              resolvedPost.userName,
                              style: AppTextStyle.body.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (resolvedPost.isOfficial) ...[
                            const SizedBox(width: 6),
                            _MiniChip(
                              label: '官方',
                              background: AppTheme.primaryMuted,
                              foreground: AppTheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeTime(resolvedPost.createdAt),
                        style: AppTextStyle.caption,
                      ),
                    ],
                  ),
                ),
                _PostTypeBadge(type: resolvedPost.type),
              ],
            ),
            if (resolvedPost.title != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              Text(resolvedPost.title!, style: AppTextStyle.h3),
            ],
            if (resolvedPost.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                resolvedPost.subtitle!,
                style: AppTextStyle.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppTheme.spacingM),
            _PostBody(post: resolvedPost),
            const SizedBox(height: AppTheme.spacingM),
            _PostActionBar(post: resolvedPost),
          ],
        ),
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final data = post.extraData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.content,
          style: AppTextStyle.body,
          maxLines: post.imagePaths.isNotEmpty ? 4 : 5,
          overflow: TextOverflow.ellipsis,
        ),
        if (post.goalTitle != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          _MiniInfoPill(
            icon: Icons.track_changes_rounded,
            label: post.goalTitle!,
            color: AppTheme.primary,
          ),
        ],
        if (post.type == PostType.checkIn) ...[
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _MiniInfoPill(
                icon: Icons.emoji_emotions_outlined,
                label: post.moodEmoji,
                color: AppTheme.accentStrong,
              ),
              if (post.streak != null)
                _MiniInfoPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '连续 ${post.streak} 天',
                  color: AppTheme.error,
                ),
            ],
          ),
        ],
        if (post.type == PostType.achievement) ...[
          const SizedBox(height: AppTheme.spacingS),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.94, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentLight, AppTheme.primaryMuted],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.goldAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.subtitle ?? '新的成长成就已解锁',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (post.type == PostType.goalComplete ||
            post.type == PostType.milestone) ...[
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              if (post.type == PostType.goalComplete) ...[
                _MiniInfoPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: '进度 100%',
                  color: AppTheme.bonusMint,
                ),
                if (data['daysSpent'] != null)
                  _MiniInfoPill(
                    icon: Icons.calendar_month_outlined,
                    label: '${data['daysSpent']} 天',
                    color: AppTheme.bonusBlue,
                  ),
              ] else ...[
                if (data['currentValue'] != null && data['targetValue'] != null)
                  _MiniInfoPill(
                    icon: Icons.flag_outlined,
                    label: '${data['currentValue']} / ${data['targetValue']}',
                    color: AppTheme.bonusBlue,
                  ),
                if (data['isMinted'] == true)
                  _MiniInfoPill(
                    icon: Icons.auto_awesome_rounded,
                    label: '已铸造',
                    color: AppTheme.goldAccent,
                  ),
              ],
            ],
          ),
        ],
        if (post.imagePaths.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingS),
          _InlineImageStrip(images: post.imagePaths),
        ],
      ],
    );
  }
}

class _PostActionBar extends StatelessWidget {
  const _PostActionBar({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.read<SocialProvider>();
    return Row(
      children: [
        _MiniActionButton(
          icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
          count: post.likeCount,
          color: AppTheme.error,
          onTap: () => socialProvider.toggleLike(post.id, fallbackPost: post),
        ),
        const SizedBox(width: AppTheme.spacingS),
        _MiniActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          count: post.commentCount,
          color: AppTheme.textSecondary,
          onTap: () => Navigator.of(
            context,
          ).push(sharedAxisRoute(PostDetailPage(post: post))),
        ),
        const SizedBox(width: AppTheme.spacingS),
        _MiniActionButton(
          icon: Icons.ios_share_rounded,
          count: post.shareCount,
          color: AppTheme.textSecondary,
          onTap: () async {
            await Share.share(_buildShareText(post));
            if (!context.mounted) return;
            await socialProvider.recordShare(post.id);
          },
        ),
      ],
    );
  }
}

class _InlineImageStrip extends StatelessWidget {
  const _InlineImageStrip({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final visibleImages = images.take(3).toList(growable: false);
    return SizedBox(
      height: 112,
      child: Row(
        children: List.generate(visibleImages.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == visibleImages.length - 1
                    ? 0
                    : AppTheme.spacingS,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: _PostImageView(imagePath: visibleImages[index]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SocialEmptyState extends StatelessWidget {
  const _SocialEmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryMuted, AppTheme.accentLight],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 26,
                  child: Icon(
                    Icons.cloud_outlined,
                    color: AppTheme.textHint,
                    size: 28,
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: const Center(
                    child: Icon(Icons.forum_outlined, size: 32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(title, style: AppTextStyle.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            subtitle,
            style: AppTextStyle.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _FeedSkeletonList extends StatelessWidget {
  const _FeedSkeletonList();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBlock(width: 120, height: 14),
                  SizedBox(height: 12),
                  SkeletonBlock(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 180, height: 12),
                  SizedBox(height: 16),
                  SkeletonBlock(width: double.infinity, height: 96),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PublishOptionTile extends StatelessWidget {
  const _PublishOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(icon, color: AppTheme.accentStrong),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyle.body),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyle.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _CheckInShareSheet extends StatefulWidget {
  const _CheckInShareSheet({required this.entries});

  final List<_ShareableCheckInEntry> entries;

  @override
  State<_CheckInShareSheet> createState() => _CheckInShareSheetState();
}

class _CheckInShareSheetState extends State<_CheckInShareSheet> {
  PostVisibility _visibility = PostVisibility.public;

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();
    return _SheetScaffold(
      title: '分享打卡',
      subtitle: '选择最近的公开目标打卡，并决定这条动态的可见范围。',
      child: widget.entries.isEmpty
          ? Center(child: Text('还没有可分享的公开打卡。', style: AppTextStyle.bodySmall))
          : Column(
              children: [
                _VisibilitySelector(
                  value: _visibility,
                  onChanged: (value) => setState(() => _visibility = value),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.spacingS),
                    itemBuilder: (context, index) {
                      final entry = widget.entries[index];
                      final alreadyShared = socialProvider.hasPublishedCheckIn(
                        entry.checkIn.id,
                      );
                      return _CheckInPublishTile(
                        entry: entry,
                        alreadyShared: alreadyShared,
                        onTap: alreadyShared
                            ? null
                            : () async {
                                final published = await socialProvider
                                    .publishCheckIn(
                                      entry.checkIn,
                                      entry.goal,
                                      visibility: _visibility,
                                    );
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                AppUtils.showSnackBar(
                                  context,
                                  published ? '打卡已发布到成长广场' : '这条打卡已经发布过了',
                                  isError: !published,
                                );
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _NftShareSheet extends StatefulWidget {
  const _NftShareSheet({required this.assets});

  final List<NftAsset> assets;

  @override
  State<_NftShareSheet> createState() => _NftShareSheetState();
}

class _NftShareSheetState extends State<_NftShareSheet> {
  PostVisibility _visibility = PostVisibility.public;

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();
    return _SheetScaffold(
      title: '分享 NFT',
      subtitle: '展示一张已经铸造完成的 NFT 卡片。',
      child: widget.assets.isEmpty
          ? Center(child: Text('还没有已铸造的 NFT。', style: AppTextStyle.bodySmall))
          : Column(
              children: [
                _VisibilitySelector(
                  value: _visibility,
                  onChanged: (value) => setState(() => _visibility = value),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.assets.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.spacingS),
                    itemBuilder: (context, index) {
                      final asset = widget.assets[index];
                      final alreadyShared = socialProvider.hasPublishedNft(
                        asset.id,
                      );
                      return _NftPublishTile(
                        asset: asset,
                        alreadyShared: alreadyShared,
                        onTap: alreadyShared
                            ? null
                            : () async {
                                final published = await socialProvider
                                    .publishNft(asset, visibility: _visibility);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                AppUtils.showSnackBar(
                                  context,
                                  published ? 'NFT 已发布到成长广场' : '这张 NFT 已经发布过了',
                                  isError: !published,
                                );
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ThoughtComposerSheet extends StatefulWidget {
  const _ThoughtComposerSheet();

  @override
  State<_ThoughtComposerSheet> createState() => _ThoughtComposerSheetState();
}

class _ThoughtComposerSheetState extends State<_ThoughtComposerSheet> {
  static const _maxImages = 3;

  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImagePaths = <String>[];

  PostVisibility _visibility = PostVisibility.public;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImagePaths.length;
    if (remaining <= 0) return;
    try {
      final files = await _picker.pickMultiImage(limit: remaining);
      if (files.isEmpty || !mounted) return;
      setState(() {
        _selectedImagePaths.addAll(files.map((file) => file.path));
      });
    } catch (_) {
      if (!mounted) return;
      AppUtils.showSnackBar(context, '选择图片失败，请稍后重试', isError: true);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 280 || _isSubmitting) return;

    final socialProvider = context.read<SocialProvider>();
    setState(() => _isSubmitting = true);
    final persistedImagePaths = _selectedImagePaths.isEmpty
        ? const <String>[]
        : await StorageService.saveImages(_selectedImagePaths);

    if (_selectedImagePaths.isNotEmpty &&
        persistedImagePaths.length != _selectedImagePaths.length) {
      for (final imagePath in persistedImagePaths) {
        await StorageService.deleteImage(imagePath);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppUtils.showSnackBar(context, '图片保存失败，请重试', isError: true);
      return;
    }

    final post = await socialProvider.publishThought(
      content: text,
      imagePaths: persistedImagePaths,
      visibility: _visibility,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (post == null) {
      for (final imagePath in persistedImagePaths) {
        await StorageService.deleteImage(imagePath);
      }
      if (!mounted) return;
      AppUtils.showSnackBar(context, '发布失败，请稍后重试', isError: true);
      return;
    }

    Navigator.of(context).pop();
    AppUtils.showSnackBar(context, '想法已发布');
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '发布想法',
      subtitle: '写下一条最多 280 字的想法，可以附带最多 3 张图片。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisibilitySelector(
            value: _visibility,
            onChanged: (value) => setState(() => _visibility = value),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _controller,
            maxLength: 280,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '今天最想分享的一点进展、一个念头，或者一段真实感受。',
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              ..._selectedImagePaths.asMap().entries.map(
                (entry) => Stack(
                  children: [
                    LocalImagePreview(
                      imagePath: entry.value,
                      width: 96,
                      height: 96,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => setState(
                          () => _selectedImagePaths.removeAt(entry.key),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (StorageService.supportsPersistentImages &&
                  _selectedImagePaths.length < _maxImages)
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined),
                        const SizedBox(height: 6),
                        Text('添加图片', style: AppTextStyle.caption),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('发布想法'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(title, style: AppTextStyle.h3),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyle.bodySmall),
          const SizedBox(height: AppTheme.spacingL),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({required this.value, required this.onChanged});

  final PostVisibility value;
  final ValueChanged<PostVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PostVisibility.values.map((item) {
        final selected = value == item;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == PostVisibility.public ? AppTheme.spacingS : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CheckInPublishTile extends StatelessWidget {
  const _CheckInPublishTile({
    required this.entry,
    required this.alreadyShared,
    required this.onTap,
  });

  final _ShareableCheckInEntry entry;
  final bool alreadyShared;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Center(
                child: Text(
                  entry.checkIn.moodEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.goal.title, style: AppTextStyle.body),
                  const SizedBox(height: 4),
                  Text(
                    _summaryFromCheckIn(entry.checkIn),
                    style: AppTextStyle.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              alreadyShared ? '已发布' : '发布',
              style: AppTextStyle.caption.copyWith(
                color: alreadyShared
                    ? AppTheme.textHint
                    : AppTheme.accentStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NftPublishTile extends StatelessWidget {
  const _NftPublishTile({
    required this.asset,
    required this.alreadyShared,
    required this.onTap,
  });

  final NftAsset asset;
  final bool alreadyShared;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: SizedBox(
                width: 58,
                height: 72,
                child: _PostImageView(imagePath: asset.imagePath),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.title, style: AppTextStyle.body),
                  const SizedBox(height: 4),
                  Text(
                    asset.description,
                    style: AppTextStyle.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.effectiveRarity.label,
                    style: AppTextStyle.caption.copyWith(
                      color: AppTheme.goldAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              alreadyShared ? '已发布' : '发布',
              style: AppTextStyle.caption.copyWith(
                color: alreadyShared
                    ? AppTheme.textHint
                    : AppTheme.accentStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyle.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text('$count', style: AppTextStyle.caption),
          ],
        ),
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (type) {
      PostType.checkIn => ('打卡', AppTheme.primaryMuted, AppTheme.primary),
      PostType.achievement => (
        '成就',
        AppTheme.accentLight,
        AppTheme.accentStrong,
      ),
      PostType.milestone => (
        '里程碑',
        AppTheme.surfaceVariant,
        AppTheme.bonusBlue,
      ),
      PostType.nftMint => ('NFT', AppTheme.accentLight, AppTheme.bonusBlue),
      PostType.goalComplete => (
        '完成',
        AppTheme.primaryMuted,
        AppTheme.bonusMint,
      ),
      PostType.thought => (
        '想法',
        AppTheme.surfaceVariant,
        AppTheme.textSecondary,
      ),
    };
    return _MiniChip(
      label: label,
      background: background,
      foreground: foreground,
    );
  }
}

class _PostImageView extends StatelessWidget {
  const _PostImageView({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            _ImageFallback(imagePath: imagePath),
      );
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            _ImageFallback(imagePath: imagePath),
      );
    }
    return LocalImagePreview(
      imagePath: imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: AppTheme.textHint),
    );
  }
}

class _ShareableCheckInEntry {
  const _ShareableCheckInEntry({required this.checkIn, required this.goal});

  final CheckIn checkIn;
  final Goal goal;
}

String _summaryFromCheckIn(CheckIn checkIn) {
  final text =
      [
        checkIn.note,
        checkIn.reflectionProgress,
        checkIn.reflectionNext,
        checkIn.reflectionBlocker,
      ].firstWhere(
        (value) => value != null && value.trim().isNotEmpty,
        orElse: () => null,
      );
  return text?.trim() ?? '把这次打卡分享出去';
}

String _buildShareText(SocialPost post) {
  final title = post.title ?? post.goalTitle ?? 'MintDay 动态';
  return '$title\n${post.content}';
}

String _formatRelativeTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays == 1) return '昨天';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return AppUtils.friendlyDate(value);
}
