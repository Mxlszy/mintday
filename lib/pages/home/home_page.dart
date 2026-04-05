import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/journey_insights.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../pages/check_in/check_in_page.dart';
import '../../pages/goal/create_goal_page.dart';
import '../../pages/goal/goal_detail_page.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/user_profile_header.dart';
import '../../services/notification_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/pixel_progress_bar.dart';
import '../../widgets/reflection_guide_card.dart';
import '../../widgets/share/share_sheets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer2<GoalProvider, CheckInProvider>(
          builder: (context, goalProvider, checkInProvider, _) {
            if (goalProvider.isLoading || checkInProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final activeGoals = goalProvider.activeGoals;
            final allGoals = goalProvider.goals;
            final checkedToday = activeGoals
                .where((goal) => checkInProvider.isTodayChecked(goal.id))
                .length;
            final maxStreak = _maxStreak(checkInProvider, allGoals);
            final checkIns = checkInProvider.checkIns;
            final isStreakBroken = maxStreak == 0 && checkIns.isNotEmpty;
            final isTodayChecked = activeGoals.isNotEmpty &&
                activeGoals.every(
                  (goal) => checkInProvider.isTodayChecked(goal.id),
                );
            final headlineGreeting = AppUtils.dynamicGreeting(
              streak: maxStreak,
              isTodayChecked: isTodayChecked,
              isStreakBroken: isStreakBroken,
            );
            final badges = buildCollectibleBadges(
              goals: allGoals,
              checkIns: checkInProvider.checkIns,
              maxStreak: maxStreak,
            );

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<UserProfileProvider>(
                          builder: (context, userProfile, _) {
                            return UserProfileHeader(
                              profile: userProfile.profile,
                              dateLabel:
                                  AppUtils.fullFriendlyDate(DateTime.now()),
                              headlineGreeting: headlineGreeting,
                              onNotificationTap: !kIsWeb
                                  ? () => _showNotificationSettings(context)
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _OverviewCard(
                          checkedToday: checkedToday,
                          activeCount: activeGoals.length,
                          maxStreak: maxStreak,
                          totalRecords: checkInProvider.checkIns.length,
                          onShareTap: () => showStatusShareSheet(context),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _ActionRow(
                          canCheckIn: activeGoals.isNotEmpty,
                          onCreateGoal: () => _openCreateGoal(context),
                          onQuickCheckIn: () => _openQuickCheckIn(
                            context,
                            activeGoals,
                            checkInProvider,
                          ),
                          onOpenJourney: () =>
                              _openJourney(context, activeGoals),
                        ),
                        if (checkInProvider.shouldShowReflectionGuide) ...[
                          const SizedBox(height: AppTheme.spacingM),
                          ReflectionGuideCard(
                            onTryReflection: () => _openReflectionCheckIn(
                              context,
                              activeGoals,
                            ),
                            onDismiss: () {},
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingXL),
                        _SectionTitle(
                          eyebrow: AppStrings.homeEyebrowBadges,
                          title: AppStrings.homeTitleBadges,
                          titleTrailing: _BadgeUnlockCaption(badges: badges),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _BadgeStrip(badges: badges),
                        const SizedBox(height: AppTheme.spacingXL),
                        const _SectionTitle(
                          eyebrow: AppStrings.homeEyebrowJourney,
                          title: AppStrings.homeTitleJourney,
                        ),
                        if (activeGoals.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.homeJourneyHint,
                            style: AppTextStyle.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingM),
                      ],
                    ),
                  ),
                ),
                if (activeGoals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        0,
                        AppTheme.spacingL,
                        120,
                      ),
                      child: EmptyState(
                        title: AppConstants.emptyGoalTitle,
                        subtitle: AppConstants.emptyGoalSubtitle,
                        actionLabel: '创建目标',
                        onAction: () => _openCreateGoal(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      0,
                      AppTheme.spacingL,
                      140,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = activeGoals[index];
                          return GoalCard(
                            goal: goal,
                            isCheckedToday:
                                checkInProvider.isTodayChecked(goal.id),
                            streakDays: checkInProvider.getStreak(goal.id),
                          );
                        },
                        childCount: activeGoals.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _maxStreak(CheckInProvider checkInProvider, List<Goal> goals) {
    var maxStreak = 0;
    for (final goal in goals) {
      final streak = checkInProvider.getStreak(goal.id);
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }
    return maxStreak;
  }

  void _openCreateGoal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGoalPage()),
    );
  }

  void _openQuickCheckIn(
    BuildContext context,
    List<Goal> activeGoals,
    CheckInProvider checkInProvider,
  ) {
    if (activeGoals.isEmpty) {
      AppUtils.showSnackBar(context, '先创建一个目标，再开始记录。');
      return;
    }

    final target = activeGoals.firstWhere(
      (goal) => !checkInProvider.isTodayChecked(goal.id),
      orElse: () => activeGoals.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckInPage(goalId: target.id)),
    );
  }

  void _openJourney(BuildContext context, List<Goal> activeGoals) {
    if (activeGoals.isEmpty) {
      AppUtils.showSnackBar(context, '还没有可查看的旅程。');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalDetailPage(goalId: activeGoals.first.id),
      ),
    );
  }

  void _openReflectionCheckIn(BuildContext context, List<Goal> activeGoals) {
    if (activeGoals.isEmpty) return;
    final target = activeGoals.firstWhere(
      (goal) =>
          !context.read<CheckInProvider>().isTodayChecked(goal.id),
      orElse: () => activeGoals.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckInPage(
          goalId: target.id,
          initialMode: CheckInMode.reflection,
        ),
      ),
    );
  }
}

void _showNotificationSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _NotificationSettingsSheet(),
  );
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = NotificationService.instance;
    final enabled = await svc.isEnabled();
    final time = await svc.getSavedTime();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _time = time;
        _loading = false;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    final svc = NotificationService.instance;
    if (value) {
      await svc.requestPermission();
      await svc.enableReminder(_time);
    } else {
      await svc.disableReminder();
    }
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null) return;
    setState(() => _time = picked);
    if (_enabled) {
      await NotificationService.instance.enableReminder(_time);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        AppTheme.spacingL + MediaQuery.of(context).padding.bottom,
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text('每日打卡提醒', style: AppTextStyle.h3),
          const SizedBox(height: 6),
          Text(
            '在指定时间发送系统通知，避免忘记打卡而断掉连续记录。',
            style: AppTextStyle.bodySmall,
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('开启提醒', style: AppTextStyle.body),
                Switch(
                  value: _enabled,
                  onChanged: _toggleEnabled,
                  activeThumbColor: AppTheme.surface,
                  activeTrackColor: AppTheme.primary,
                ),
              ],
            ),
            if (_enabled) ...[
              const SizedBox(height: AppTheme.spacingM),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('提醒时间', style: AppTextStyle.body),
                      Text(
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyle.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int checkedToday;
  final int activeCount;
  final int maxStreak;
  final int totalRecords;
  final VoidCallback onShareTap;

  const _OverviewCard({
    required this.checkedToday,
    required this.activeCount,
    required this.maxStreak,
    required this.totalRecords,
    required this.onShareTap,
  });

  static Color _streakBadgeBackground(int streak) {
    if (streak <= 2) return AppTheme.bonusMint;
    if (streak <= 6) return AppTheme.accent;
    if (streak <= 13) return AppTheme.bonusBlue;
    return AppTheme.goldAccent;
  }

  static PixelIconData _streakBadgeIcon(int streak) {
    if (streak <= 2) return PixelIcons.sprout;
    if (streak <= 6) return PixelIcons.bolt;
    if (streak <= 13) return PixelIcons.medal;
    return PixelIcons.trophy;
  }

  @override
  Widget build(BuildContext context) {
    final nextMilestone = AppConstants.streakMilestones.firstWhere(
      (milestone) => milestone > maxStreak,
      orElse: () => AppConstants.streakMilestones.last,
    );
    final remainingDays =
        maxStreak >= nextMilestone ? 0 : nextMilestone - maxStreak;
    final progressBase = nextMilestone == 0 ? 1.0 : (maxStreak / nextMilestone);
    final badgeBg = _streakBadgeBackground(maxStreak);
    final badgeIcon = _streakBadgeIcon(maxStreak);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('下一枚连续徽章', style: AppTextStyle.label),
                    const SizedBox(height: 10),
                    Text(
                      remainingDays == 0 ? '已点亮' : '还差 $remainingDays 天',
                      style: AppTextStyle.h2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '目标 $nextMilestone 天连续记录',
                      style: AppTextStyle.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: PixelIcon(
                    icon: badgeIcon,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          PixelProgressBar(
            progress: progressBase.clamp(0.0, 1.0),
            height: 10,
            blockCount: 14,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceDeep,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: '今日推进',
                  value: '$checkedToday/$activeCount',
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: '最长连续',
                  value: maxStreak == 0 ? '-' : '$maxStreak 天',
                ),
              ),
              Expanded(
                child: _MetricColumn(label: '累计记录', value: '$totalRecords'),
              ),
            ],
          ),
        ],
      ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onShareTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(
                  Icons.ios_share,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.caption),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyle.h3),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool canCheckIn;
  final VoidCallback onCreateGoal;
  final VoidCallback onQuickCheckIn;
  final VoidCallback onOpenJourney;

  const _ActionRow({
    required this.canCheckIn,
    required this.onCreateGoal,
    required this.onQuickCheckIn,
    required this.onOpenJourney,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onCreateGoal,
            child: const Text('创建目标'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: OutlinedButton(
            onPressed: canCheckIn ? onQuickCheckIn : null,
            child: const Text('快速打卡'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: OutlinedButton(
            onPressed: canCheckIn ? onOpenJourney : null,
            child: const Text('查看旅程'),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? titleTrailing;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTextStyle.label),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(title, style: AppTextStyle.h2)),
            if (titleTrailing != null) titleTrailing!,
          ],
        ),
      ],
    );
  }
}

/// 「成长徽章」标题右侧：已解锁数 / 总数。
class _BadgeUnlockCaption extends StatelessWidget {
  final List<CollectibleBadge> badges;

  const _BadgeUnlockCaption({required this.badges});

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.unlocked).length;
    final total = badges.length;
    final hintStyle = AppTextStyle.caption.copyWith(color: AppTheme.textHint);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Text.rich(
        TextSpan(
          style: AppTextStyle.caption,
          children: [
            const TextSpan(text: '已解锁 '),
            TextSpan(
              text: '$unlocked',
              style: AppTextStyle.caption.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: ' / 共 ', style: hintStyle),
            TextSpan(text: '$total', style: hintStyle),
            TextSpan(text: ' 枚', style: hintStyle),
          ],
        ),
      ),
    );
  }
}

class _BadgeStrip extends StatefulWidget {
  final List<CollectibleBadge> badges;

  const _BadgeStrip({required this.badges});

  @override
  State<_BadgeStrip> createState() => _BadgeStripState();
}

class _BadgeStripState extends State<_BadgeStrip> {
  static const double _pageHeight = 150;
  static const double _dotAreaHeight = 20;

  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BadgeStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLen = widget.badges.length;
    if (newLen == 0) return;
    final maxPage = ((newLen + 1) ~/ 2) - 1;
    if (_pageIndex > maxPage) {
      final i = maxPage;
      setState(() => _pageIndex = i);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(i);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordered = [
      ...widget.badges.where((b) => b.unlocked),
      ...widget.badges.where((b) => !b.unlocked),
    ];
    if (ordered.isEmpty) {
      return const SizedBox.shrink();
    }

    final pageCount = (ordered.length + 1) ~/ 2;
    final dotIndex = _pageIndex.clamp(0, pageCount - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _pageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, pageIndex) {
              final i0 = pageIndex * 2;
              final i1 = i0 + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _BadgePageTile(badge: ordered[i0])),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: i1 < ordered.length
                          ? _BadgePageTile(badge: ordered[i1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (pageCount > 1)
          SizedBox(
            height: _dotAreaHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final selected = i == dotIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _BadgePageTile extends StatelessWidget {
  final CollectibleBadge badge;

  const _BadgePageTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    if (badge.unlocked) {
      final accent = AppTheme.rewardPalette[
          badge.colorIndex % AppTheme.rewardPalette.length];
      return Container(
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Center(
                child: PixelIcon(icon: badge.icon, size: 20),
              ),
            ),
            const Spacer(),
            Text(
              badge.title,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              badge.subtitle,
              style: AppTextStyle.caption.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Opacity(
      opacity: 0.4,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDeep,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Center(
                child: PixelIcon(
                  icon: badge.icon,
                  size: 20,
                ),
              ),
            ),
            const Spacer(),
            Text(
              badge.title,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              badge.subtitle,
              style: AppTextStyle.caption.copyWith(color: AppTheme.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
