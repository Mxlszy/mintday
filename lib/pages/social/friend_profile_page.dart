import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/neumorphic.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/friendship.dart';
import '../../models/social_post.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/friend_avatar.dart';
import '../../widgets/skeleton_loader.dart';

class FriendProfilePage extends StatefulWidget {
  const FriendProfilePage({super.key, required this.profileId});

  final String profileId;

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  FriendProfile? _profile;
  List<SocialPost> _activity = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider = context.read<FriendProvider>();
    final profile = await provider.getResolvedProfile(widget.profileId);
    final activity = await provider.getFriendActivity(widget.profileId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _activity = activity;
      _isLoading = false;
    });
  }

  Future<void> _sendEncouragement(FriendProfile profile) async {
    const messages = [
      '今天也很稳，继续把节奏守住。',
      '你已经走得很远了，别小看每一次打卡。',
      '先做一点也很了不起，继续保持。',
      '看见你的坚持了，给你加一格能量。',
    ];

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingM,
            AppTheme.spacingL,
            AppTheme.spacingL + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text('发送鼓励', style: AppTextStyle.h3),
              const SizedBox(height: 6),
              Text(
                '挑一句预设文案，给 ${profile.nickname} 一点继续坚持的能量。',
                style: AppTextStyle.bodySmall,
              ),
              const SizedBox(height: AppTheme.spacingL),
              ...messages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: NeuContainer(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    borderRadius: AppTheme.radiusL,
                    isSubtle: true,
                    onTap: () => Navigator.of(sheetContext).pop(message),
                    child: Text(message, style: AppTextStyle.bodySmall),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    AppUtils.showSnackBar(context, '已向 ${profile.nickname} 发送鼓励');
  }

  Future<void> _removeFriend(FriendProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('取消好友'),
          content: Text(
            '确认要将 ${profile.nickname} 从好友列表中移除吗？',
            style: AppTextStyle.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('保留'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<FriendProvider>().removeFriend(
      profile.id,
    );
    if (!mounted) return;
    AppUtils.showSnackBar(
      context,
      success ? '已取消好友关系' : '操作失败，请稍后重试',
      isError: !success,
    );
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('好友主页')),
      body: _isLoading
          ? const _FriendProfileSkeleton()
          : _profile == null
          ? const Center(child: Text('好友资料加载失败'))
          : Consumer<FriendProvider>(
              builder: (context, provider, _) {
                final profile = _profile!;
                final relation = provider.relationTypeFor(profile.id);
                final friendship = provider.getFriendshipWith(profile.id);

                return RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppTheme.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      140,
                    ),
                    children: [
                      _HeroCard(profile: profile, relation: relation),
                      const SizedBox(height: AppTheme.spacingL),
                      _ActionBar(
                        profile: profile,
                        relation: relation,
                        friendship: friendship,
                        onEncourage: () => _sendEncouragement(profile),
                        onRemove: () => _removeFriend(profile),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      const _SectionTitle('数据概览'),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: '${profile.totalCheckIns}',
                              label: '总打卡',
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _StatCard(
                              value: '${profile.currentStreak}',
                              label: '连续天数',
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _StatCard(
                              value: '${profile.activeGoals}',
                              label: '活跃目标',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      const _SectionTitle('公开动态'),
                      const SizedBox(height: AppTheme.spacingM),
                      if (_activity.isEmpty)
                        const EmptyState(
                          title: '暂无公开动态',
                          subtitle: '等对方公开新的打卡后，这里会第一时间出现。',
                        )
                      else
                        ..._activity.map(
                          (post) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingM,
                            ),
                            child: _ActivityCard(post: post),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.relation});

  final FriendProfile profile;
  final FriendRelationType relation;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      borderRadius: AppTheme.radiusXL,
      child: Column(
        children: [
          FriendAvatar(
            label: profile.nickname,
            avatarAssetPath: profile.avatarAssetPath,
            avatarConfig: profile.parsedAvatarConfig,
            size: 104,
            borderRadius: 28,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            profile.nickname,
            textAlign: TextAlign.center,
            style: AppTextStyle.h2,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Text(
              _relationLabel(relation),
              style: AppTextStyle.caption.copyWith(
                color: AppTheme.accentStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            '最近活跃 ${_formatLastActive(profile.lastActiveAt)}',
            style: AppTextStyle.bodySmall,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '好友 ID：${profile.id}',
            textAlign: TextAlign.center,
            style: AppTextStyle.caption,
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.profile,
    required this.relation,
    required this.friendship,
    required this.onEncourage,
    required this.onRemove,
  });

  final FriendProfile profile;
  final FriendRelationType relation;
  final Friendship? friendship;
  final VoidCallback onEncourage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FriendProvider>();

    switch (relation) {
      case FriendRelationType.friend:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onEncourage,
                child: const Text('发送鼓励'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: OutlinedButton(
                onPressed: onRemove,
                child: const Text('取消好友'),
              ),
            ),
          ],
        );
      case FriendRelationType.none:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final success = await provider.sendFriendRequest(profile.id);
                  if (!context.mounted) return;
                  AppUtils.showSnackBar(
                    context,
                    success ? '好友请求已发送' : '暂时无法发送请求',
                    isError: !success,
                  );
                },
                child: const Text('加为好友'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final success = await provider.blockUser(profile.id);
                  if (!context.mounted) return;
                  AppUtils.showSnackBar(
                    context,
                    success ? '已屏蔽该用户' : '操作失败，请稍后重试',
                    isError: !success,
                  );
                },
                child: const Text('屏蔽'),
              ),
            ),
          ],
        );
      case FriendRelationType.incomingPending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: friendship == null
                    ? null
                    : () async {
                        final success = await provider.rejectRequest(
                          friendship!.id,
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
                onPressed: friendship == null
                    ? null
                    : () async {
                        final success = await provider.acceptRequest(
                          friendship!.id,
                        );
                        if (!context.mounted) return;
                        AppUtils.showSnackBar(
                          context,
                          success ? '已成为好友' : '操作失败，请稍后重试',
                          isError: !success,
                        );
                      },
                child: const Text('接受请求'),
              ),
            ),
          ],
        );
      case FriendRelationType.outgoingPending:
        return OutlinedButton(
          onPressed: friendship == null
              ? null
              : () async {
                  final success = await provider.rejectRequest(friendship!.id);
                  if (!context.mounted) return;
                  AppUtils.showSnackBar(
                    context,
                    success ? '已撤回请求' : '操作失败，请稍后重试',
                    isError: !success,
                  );
                },
          child: const Text('撤回请求'),
        );
      case FriendRelationType.blocked:
        return NeuContainer(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          borderRadius: AppTheme.radiusL,
          isSubtle: true,
          child: Text(
            '你已屏蔽该用户',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall,
          ),
        );
      case FriendRelationType.self:
        return NeuContainer(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          borderRadius: AppTheme.radiusL,
          isSubtle: true,
          child: Text(
            '这是你自己的社交身份页',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall,
          ),
        );
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingL,
      ),
      borderRadius: AppTheme.radiusL,
      isSubtle: true,
      child: Column(
        children: [
          Text(value, style: AppTextStyle.h2),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyle.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      borderRadius: AppTheme.radiusL,
      isSubtle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.goalTitle ?? '公开打卡',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatActivityTime(post.createdAt),
                style: AppTextStyle.caption,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(post.content, style: AppTextStyle.body),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  '公开打卡',
                  style: AppTextStyle.caption.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (post.streak != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    '连续 ${post.streak} 天',
                    style: AppTextStyle.caption.copyWith(
                      color: AppTheme.accentStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyle.h3);
  }
}

class _FriendProfileSkeleton extends StatelessWidget {
  const _FriendProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          120,
        ),
        children: const [
          SkeletonCard(
            child: Column(
              children: [
                SkeletonBlock(width: 104, height: 104, borderRadius: 28),
                SizedBox(height: AppTheme.spacingM),
                SkeletonBlock(width: 150, height: 18),
                SizedBox(height: 12),
                SkeletonBlock(width: 120, height: 12),
                SizedBox(height: 12),
                SkeletonBlock(width: 220, height: 12),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingL),
          SkeletonCard(
            child: Row(
              children: [
                Expanded(child: SkeletonBlock(height: 44)),
                SizedBox(width: AppTheme.spacingM),
                Expanded(child: SkeletonBlock(height: 44)),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(child: SkeletonCard(child: SkeletonBlock(height: 72))),
              SizedBox(width: AppTheme.spacingM),
              Expanded(child: SkeletonCard(child: SkeletonBlock(height: 72))),
              SizedBox(width: AppTheme.spacingM),
              Expanded(child: SkeletonCard(child: SkeletonBlock(height: 72))),
            ],
          ),
        ],
      ),
    );
  }
}

String _relationLabel(FriendRelationType relation) {
  return switch (relation) {
    FriendRelationType.friend => '已是好友',
    FriendRelationType.incomingPending => '等待你处理',
    FriendRelationType.outgoingPending => '已发送请求',
    FriendRelationType.blocked => '已屏蔽',
    FriendRelationType.self => '这是你',
    FriendRelationType.none => '还不是好友',
  };
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

String _formatActivityTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  return AppUtils.friendlyDate(value);
}
