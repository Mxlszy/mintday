import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/neumorphic.dart';
import '../../core/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/friendship.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/friend_avatar.dart';
import '../../widgets/skeleton_loader.dart';
import 'friend_profile_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final provider = context.read<FriendProvider>();
      if (value.trim().isEmpty) {
        provider.clearSearch();
        return;
      }
      provider.searchUsers(value);
    });
  }

  Future<void> _copyMyId(BuildContext context, String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!context.mounted) return;
    AppUtils.showSnackBar(context, '你的好友 ID 已复制');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('好友')),
        body: SafeArea(
          top: false,
          child: Consumer<FriendProvider>(
            builder: (context, friendProvider, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingM,
                      AppTheme.spacingL,
                      AppTheme.spacingM,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            setState(() {});
                            _onSearchChanged(value);
                          },
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: '输入昵称或好友 ID 搜索',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      friendProvider.clearSearch();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingM),
                          _SearchResultsSection(
                            results: friendProvider.searchResults,
                            isSearching: friendProvider.isSearching,
                            onOpenProfile: _openProfile,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                    ),
                    child: NeuContainer(
                      padding: const EdgeInsets.all(6),
                      borderRadius: AppTheme.radiusXL,
                      isSubtle: true,
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: AppTheme.neuFlat,
                        ),
                        labelColor: AppTheme.textPrimary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        tabs: [
                          Tab(text: '好友 ${friendProvider.friends.length}'),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('待处理'),
                                if (friendProvider.pendingRequestCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                    ),
                                    height: 20,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${friendProvider.pendingRequestCount}',
                                        style: AppTextStyle.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _FriendsListTab(
                          provider: friendProvider,
                          onOpenProfile: _openProfile,
                          onInvite: () =>
                              _copyMyId(context, friendProvider.currentUserId),
                        ),
                        _RequestsTab(
                          provider: friendProvider,
                          onOpenProfile: _openProfile,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, FriendProfile profile) {
    Navigator.of(
      context,
    ).push(sharedAxisRoute(FriendProfilePage(profileId: profile.id)));
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.results,
    required this.isSearching,
    required this.onOpenProfile,
  });

  final List<FriendSearchResult> results;
  final bool isSearching;
  final void Function(BuildContext context, FriendProfile profile)
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const _SearchResultsSkeleton();
    }

    if (results.isEmpty) {
      return NeuContainer(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        borderRadius: AppTheme.radiusL,
        isSubtle: true,
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, color: AppTheme.textHint),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                '没有找到匹配的用户，试试完整昵称或好友 ID。',
                style: AppTextStyle.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final visibleCount = min(results.length, 4);
    final panelHeight = min(visibleCount * 92.0 + 12, 360.0);

    return SizedBox(
      height: panelHeight,
      child: ListView.separated(
        itemCount: visibleCount,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingS),
        itemBuilder: (context, index) {
          final item = results[index];
          return _SearchResultCard(
            result: item,
            onOpenProfile: () => onOpenProfile(context, item.profile),
          );
        },
      ),
    );
  }
}

class _FriendsListTab extends StatelessWidget {
  const _FriendsListTab({
    required this.provider,
    required this.onOpenProfile,
    required this.onInvite,
  });

  final FriendProvider provider;
  final void Function(BuildContext context, FriendProfile profile)
  onOpenProfile;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.friends.isEmpty) {
      return const _FriendsListSkeleton();
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppTheme.primary,
      child: provider.friends.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingXL,
                AppTheme.spacingL,
                140,
              ),
              children: [
                EmptyState(
                  title: '还没有好友',
                  subtitle: '搜索昵称或好友 ID，先把第一位一起坚持的小伙伴加进来。',
                  actionLabel: '邀请好友',
                  onAction: onInvite,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                0,
                AppTheme.spacingL,
                140,
              ),
              itemCount: provider.friends.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.spacingM),
              itemBuilder: (context, index) {
                final record = provider.friends[index];
                return _FriendCard(
                  profile: record.profile,
                  onTap: () => onOpenProfile(context, record.profile),
                );
              },
            ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.provider, required this.onOpenProfile});

  final FriendProvider provider;
  final void Function(BuildContext context, FriendProfile profile)
  onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading &&
        provider.pendingRequests.isEmpty &&
        provider.sentRequests.isEmpty) {
      return const _RequestsSkeleton();
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppTheme.primary,
      child: provider.pendingRequests.isEmpty && provider.sentRequests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingXL,
                AppTheme.spacingL,
                140,
              ),
              children: const [
                EmptyState(
                  title: '没有待处理请求',
                  subtitle: '新的好友申请会出现在这里，也可以在上面搜索主动发起请求。',
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                0,
                AppTheme.spacingL,
                140,
              ),
              children: [
                if (provider.pendingRequests.isNotEmpty) ...[
                  const _SectionLabel('收到的请求'),
                  const SizedBox(height: AppTheme.spacingM),
                  ...provider.pendingRequests.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: _IncomingRequestCard(
                        record: record,
                        onOpenProfile: () =>
                            onOpenProfile(context, record.profile),
                      ),
                    ),
                  ),
                ],
                if (provider.sentRequests.isNotEmpty) ...[
                  if (provider.pendingRequests.isNotEmpty)
                    const SizedBox(height: AppTheme.spacingM),
                  const _SectionLabel('我发出的请求'),
                  const SizedBox(height: AppTheme.spacingM),
                  ...provider.sentRequests.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: _OutgoingRequestCard(
                        record: record,
                        onOpenProfile: () =>
                            onOpenProfile(context, record.profile),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.profile, required this.onTap});

  final FriendProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      borderRadius: AppTheme.radiusL,
      onTap: onTap,
      child: Row(
        children: [
          FriendAvatar(
            label: profile.nickname,
            avatarAssetPath: profile.avatarAssetPath,
            avatarConfig: profile.parsedAvatarConfig,
            size: 64,
            borderRadius: 20,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    _StreakBadge(days: profile.currentStreak),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '最近活跃 ${_formatLastActive(profile.lastActiveAt)}',
                  style: AppTextStyle.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.track_changes_rounded,
                      label: '${profile.activeGoals} 个活跃目标',
                    ),
                    _MetaChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: '总打卡 ${profile.totalCheckIns}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
        ],
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.record,
    required this.onOpenProfile,
  });

  final FriendRecord record;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FriendProvider>();
    return Dismissible(
      key: ValueKey(record.friendship.id),
      direction: DismissDirection.horizontal,
      background: const _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.check_rounded,
        label: '接受',
        color: Color(0xFF4F67DB),
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        icon: Icons.close_rounded,
        label: '拒绝',
        color: AppTheme.error,
      ),
      confirmDismiss: (direction) async {
        final accepted = direction == DismissDirection.startToEnd;
        final success = accepted
            ? await provider.acceptRequest(record.friendship.id)
            : await provider.rejectRequest(record.friendship.id);
        if (!context.mounted) return false;
        if (success) {
          AppUtils.showSnackBar(context, accepted ? '已接受好友请求' : '已拒绝该请求');
        } else {
          AppUtils.showSnackBar(context, '操作失败，请稍后重试', isError: true);
        }
        return success;
      },
      child: NeuContainer(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        borderRadius: AppTheme.radiusL,
        child: Column(
          children: [
            Row(
              children: [
                FriendAvatar(
                  label: record.profile.nickname,
                  avatarAssetPath: record.profile.avatarAssetPath,
                  avatarConfig: record.profile.parsedAvatarConfig,
                  size: 58,
                  borderRadius: 18,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: InkWell(
                    onTap: onOpenProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.profile.nickname,
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '请求时间 ${_formatRequestTime(record.friendship.createdAt)}',
                          style: AppTextStyle.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final success = await provider.rejectRequest(
                        record.friendship.id,
                      );
                      if (!context.mounted) return;
                      AppUtils.showSnackBar(
                        context,
                        success ? '已拒绝该请求' : '操作失败，请稍后重试',
                        isError: !success,
                      );
                    },
                    child: const Text('拒绝'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await provider.acceptRequest(
                        record.friendship.id,
                      );
                      if (!context.mounted) return;
                      AppUtils.showSnackBar(
                        context,
                        success ? '已接受好友请求' : '操作失败，请稍后重试',
                        isError: !success,
                      );
                    },
                    child: const Text('接受'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingRequestCard extends StatelessWidget {
  const _OutgoingRequestCard({
    required this.record,
    required this.onOpenProfile,
  });

  final FriendRecord record;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      borderRadius: AppTheme.radiusL,
      child: Row(
        children: [
          FriendAvatar(
            label: record.profile.nickname,
            avatarAssetPath: record.profile.avatarAssetPath,
            avatarConfig: record.profile.parsedAvatarConfig,
            size: 56,
            borderRadius: 18,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: InkWell(
              onTap: onOpenProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.profile.nickname,
                    style: AppTextStyle.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('已发送，等待对方通过', style: AppTextStyle.bodySmall),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await context
                  .read<FriendProvider>()
                  .rejectRequest(record.friendship.id);
              if (!context.mounted) return;
              AppUtils.showSnackBar(
                context,
                success ? '已撤回请求' : '撤回失败，请稍后重试',
                isError: !success,
              );
            },
            child: const Text('撤回'),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.onOpenProfile});

  final FriendSearchResult result;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FriendProvider>();
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      borderRadius: AppTheme.radiusL,
      isSubtle: true,
      onTap: onOpenProfile,
      child: Row(
        children: [
          FriendAvatar(
            label: result.profile.nickname,
            avatarAssetPath: result.profile.avatarAssetPath,
            avatarConfig: result.profile.parsedAvatarConfig,
            size: 54,
            borderRadius: 16,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.profile.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_compactId(result.profile.id)}',
                  style: AppTextStyle.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          _SearchActionButton(result: result, provider: provider),
        ],
      ),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  const _SearchActionButton({required this.result, required this.provider});

  final FriendSearchResult result;
  final FriendProvider provider;

  @override
  Widget build(BuildContext context) {
    switch (result.relationType) {
      case FriendRelationType.none:
        return ElevatedButton(
          onPressed: () async {
            final success = await provider.sendFriendRequest(result.profile.id);
            if (!context.mounted) return;
            AppUtils.showSnackBar(
              context,
              success ? '好友请求已发送' : '暂时无法发送请求',
              isError: !success,
            );
          },
          child: const Text('添加'),
        );
      case FriendRelationType.incomingPending:
        return OutlinedButton(
          onPressed: result.friendship == null
              ? null
              : () async {
                  final success = await provider.acceptRequest(
                    result.friendship!.id,
                  );
                  if (!context.mounted) return;
                  AppUtils.showSnackBar(
                    context,
                    success ? '已接受好友请求' : '操作失败，请稍后重试',
                    isError: !success,
                  );
                },
          child: const Text('接受'),
        );
      case FriendRelationType.outgoingPending:
        return const _StatusPill(label: '已发送');
      case FriendRelationType.friend:
        return const _StatusPill(label: '好友');
      case FriendRelationType.self:
        return const _StatusPill(label: '我');
      case FriendRelationType.blocked:
        return const _StatusPill(label: '已屏蔽');
    }
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        '连续 $days 天',
        style: AppTextStyle.caption.copyWith(
          color: AppTheme.accentStrong,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyle.caption),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyle.label);
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeft ? AppTheme.spacingL : 0,
        right: isLeft ? 0 : AppTheme.spacingL,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Text(label, style: AppTextStyle.bodySmall.copyWith(color: color)),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: color),
          if (isLeft) ...[
            const SizedBox(width: 8),
            Text(label, style: AppTextStyle.bodySmall.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}

class _FriendsListSkeleton extends StatelessWidget {
  const _FriendsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          120,
        ),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingM),
        itemBuilder: (context, index) {
          return const SkeletonCard(
            child: Row(
              children: [
                SkeletonBlock(width: 64, height: 64, borderRadius: 20),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 120, height: 14),
                      SizedBox(height: 12),
                      SkeletonBlock(width: 160, height: 12),
                      SizedBox(height: 12),
                      SkeletonBlock(width: 190, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestsSkeleton extends StatelessWidget {
  const _RequestsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          120,
        ),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingM),
        itemBuilder: (context, index) {
          return const SkeletonCard(
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonBlock(width: 56, height: 56, borderRadius: 18),
                    SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBlock(width: 120, height: 14),
                          SizedBox(height: 10),
                          SkeletonBlock(width: 180, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(child: SkeletonBlock(height: 42)),
                    SizedBox(width: AppTheme.spacingM),
                    Expanded(child: SkeletonBlock(height: 42)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: const [
          SkeletonCard(
            padding: EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                SkeletonBlock(width: 52, height: 52, borderRadius: 16),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 110, height: 14),
                      SizedBox(height: 10),
                      SkeletonBlock(width: 160, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: AppTheme.spacingM),
                SkeletonBlock(width: 72, height: 36),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingS),
          SkeletonCard(
            padding: EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                SkeletonBlock(width: 52, height: 52, borderRadius: 16),
                SizedBox(width: AppTheme.spacingM),
                Expanded(child: SkeletonBlock(height: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatLastActive(DateTime? value) {
  if (value == null) return '近期待同步';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 30) return '刚刚在线';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return AppUtils.friendlyDate(value);
}

String _formatRequestTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  return AppUtils.friendlyDate(value);
}

String _compactId(String value) {
  if (value.length <= 14) return value;
  return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
}
