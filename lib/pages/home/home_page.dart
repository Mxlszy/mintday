import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/journey_insights.dart';
import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/user_profile_model.dart';
import '../../core/utils.dart';
import '../../models/avatar_config.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../pages/ai/ai_chat_page.dart';
import '../../pages/check_in/check_in_page.dart';
import '../../pages/goal/create_goal_page.dart';
import '../../pages/goal/goal_detail_page.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/avatar/pixel_avatar_painter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/notification_settings_sheet.dart';
import '../../widgets/pixel_progress_bar.dart';
import '../../widgets/reflection_guide_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/today_todo_overview.dart';
import '../../widgets/touch_scale_wrapper.dart';
import '../../widgets/share/share_sheets.dart';
import '../avatar/avatar_editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _heroPulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _staggerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  int _entranceFingerprint = -1;

  @override
  void dispose() {
    _heroPulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _syncEntranceAnimation(int fingerprint) {
    if (_entranceFingerprint == fingerprint) return;
    _entranceFingerprint = fingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _staggerController.forward(from: 0);
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait<void>([
      context.read<GoalProvider>().loadGoals(),
      context.read<CheckInProvider>().loadCheckIns(),
      context.read<FocusProvider>().loadSessions(),
      context.read<TodoProvider>().loadTodosForDate(
        DateTime.now(),
        force: true,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final heroPulse = CurvedAnimation(
      parent: _heroPulseController,
      curve: Curves.easeInOut,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer3<GoalProvider, CheckInProvider, FocusProvider>(
          builder: (context, goalProvider, checkInProvider, focusProvider, _) {
            final isInitialLoading =
                (goalProvider.isLoading && goalProvider.goals.isEmpty) ||
                (checkInProvider.isLoading &&
                    checkInProvider.checkIns.isEmpty) ||
                (focusProvider.isLoading && focusProvider.sessions.isEmpty);

            if (isInitialLoading) {
              return const _HomeSkeletonView();
            }

            final activeGoals = goalProvider.activeGoals;
            final allGoals = goalProvider.goals;
            final checkIns = checkInProvider.checkIns;
            final checkedToday = activeGoals
                .where((goal) => checkInProvider.isTodayChecked(goal.id))
                .length;
            final maxStreak = _maxStreak(checkInProvider, allGoals);
            final isStreakBroken = maxStreak == 0 && checkIns.isNotEmpty;
            final isTodayChecked =
                activeGoals.isNotEmpty &&
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
              checkIns: checkIns,
              maxStreak: maxStreak,
            );
            final todayFocusMinutes = focusProvider.getTodayFocusMinutes();
            final growthStats = _HeroGrowthStats.fromSnapshot(
              checkedToday: checkedToday,
              maxStreak: maxStreak,
              totalRecords: checkIns.length,
              focusMinutes: todayFocusMinutes,
            );

            _syncEntranceAnimation(
              Object.hash(
                activeGoals.length,
                checkIns.length,
                maxStreak,
                badges.where((badge) => badge.unlocked).length,
              ),
            );

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
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
                        children: <Widget>[
                          Consumer<UserProfileProvider>(
                            builder: (context, userProfile, _) => _HeroCard(
                              profile: userProfile.profile,
                              dateLabel: AppUtils.fullFriendlyDate(
                                DateTime.now(),
                              ),
                              headlineGreeting: headlineGreeting,
                              growthStats: growthStats,
                              pulseAnimation: heroPulse,
                              onAvatarTap: () => _openAvatarEditor(context),
                              onAiTap: () => _openAiCompanion(context),
                              onNotificationTap: !kIsWeb
                                  ? () => _showNotificationSettings(context)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          _TodayDashboard(
                            checkedToday: checkedToday,
                            activeCount: activeGoals.length,
                            maxStreak: maxStreak,
                            totalRecords: checkIns.length,
                            todayFocusMinutes: todayFocusMinutes,
                            onShareTap: () => showStatusShareSheet(context),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          const TodayTodoOverview(),
                          const SizedBox(height: AppTheme.spacingL),
                          _QuickActionStrip(
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
                              onTryReflection: () =>
                                  _openReflectionCheckIn(context, activeGoals),
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
                          _BadgeStrip(
                            badges: badges,
                            controller: _staggerController,
                          ),
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
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final goal = activeGoals[index];
                          return _StaggeredReveal(
                            controller: _staggerController,
                            index: index,
                            baseDelayMs: 280,
                            child: GoalCard(
                              goal: goal,
                              isCheckedToday: checkInProvider.isTodayChecked(
                                goal.id,
                              ),
                              streakDays: checkInProvider.getStreak(goal.id),
                            ),
                          );
                        }, childCount: activeGoals.length),
                      ),
                    ),
                ],
              ),
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
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }

  void _openAvatarEditor(BuildContext context) {
    Navigator.of(context).push(fadeSlideRoute(const AvatarEditorPage()));
  }

  void _openCreateGoal(BuildContext context) {
    Navigator.of(context).push(fadeSlideRoute(const CreateGoalPage()));
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

    Navigator.of(context).push(fadeSlideRoute(CheckInPage(goalId: target.id)));
  }

  void _openJourney(BuildContext context, List<Goal> activeGoals) {
    if (activeGoals.isEmpty) {
      AppUtils.showSnackBar(context, '还没有可查看的旅程。');
      return;
    }

    Navigator.of(
      context,
    ).push(sharedAxisRoute(GoalDetailPage(goalId: activeGoals.first.id)));
  }

  void _openReflectionCheckIn(BuildContext context, List<Goal> activeGoals) {
    if (activeGoals.isEmpty) return;

    final target = activeGoals.firstWhere(
      (goal) => !context.read<CheckInProvider>().isTodayChecked(goal.id),
      orElse: () => activeGoals.first,
    );
    Navigator.of(context).push(
      fadeSlideRoute(
        CheckInPage(goalId: target.id, initialMode: CheckInMode.reflection),
      ),
    );
  }

  void _openAiCompanion(BuildContext context) {
    Navigator.of(context).push(fadeSlideRoute(const AiChatPage()));
  }
}

void _showNotificationSettings(BuildContext context) {
  showNotificationSettingsSheet(context);
}

class _HomeSkeletonView extends StatelessWidget {
  const _HomeSkeletonView();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            140,
          ),
          children: [
            SkeletonCard(
              child: Row(
                children: [
                  const SkeletonBlock(
                    width: 112,
                    height: 136,
                    borderRadius: 18,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBlock(width: 96, height: 12, borderRadius: 6),
                        SizedBox(height: 10),
                        SkeletonBlock(width: 124, height: 24, borderRadius: 10),
                        SizedBox(height: 10),
                        SkeletonBlock(height: 14, borderRadius: 7),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 168, height: 14, borderRadius: 7),
                        SizedBox(height: 18),
                        SkeletonBlock(height: 54, borderRadius: 16),
                        SizedBox(height: 12),
                        SkeletonBlock(height: 54, borderRadius: 999),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBlock(width: 112, height: 20, borderRadius: 10),
                  const SizedBox(height: 8),
                  const SkeletonBlock(height: 14, borderRadius: 7),
                  const SizedBox(height: AppTheme.spacingL),
                  Row(
                    children: const [
                      SkeletonBlock(width: 144, height: 144, borderRadius: 28),
                      SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          children: [
                            SkeletonBlock(height: 56, borderRadius: 18),
                            SizedBox(height: 10),
                            SkeletonBlock(height: 56, borderRadius: 18),
                            SizedBox(height: 10),
                            SkeletonBlock(height: 56, borderRadius: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  const SkeletonBlock(height: 10, borderRadius: 5),
                  const SizedBox(height: 10),
                  const SkeletonBlock(height: 14, borderRadius: 7),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  SkeletonBlock(width: 132, height: 46, borderRadius: 999),
                  SizedBox(width: 12),
                  SkeletonBlock(width: 132, height: 46, borderRadius: 999),
                  SizedBox(width: 12),
                  SkeletonBlock(width: 132, height: 46, borderRadius: 999),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            const SkeletonBlock(width: 88, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            const SkeletonBlock(width: 146, height: 24, borderRadius: 10),
            const SizedBox(height: AppTheme.spacingM),
            SizedBox(
              height: 168,
              child: Row(
                children: const [
                  Expanded(
                    child: SkeletonCard(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      borderRadius: AppTheme.radiusL,
                      child: SizedBox.expand(),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: SkeletonCard(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      borderRadius: AppTheme.radiusL,
                      child: SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            const SkeletonBlock(width: 104, height: 12, borderRadius: 6),
            const SizedBox(height: 8),
            const SkeletonBlock(width: 172, height: 24, borderRadius: 10),
            const SizedBox(height: AppTheme.spacingM),
            const SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 136, height: 22, borderRadius: 10),
                  SizedBox(height: 12),
                  SkeletonBlock(width: 92, height: 14, borderRadius: 7),
                  SizedBox(height: 18),
                  SkeletonBlock(height: 12, borderRadius: 6),
                  SizedBox(height: 18),
                  SkeletonBlock(height: 12, borderRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            const SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 148, height: 22, borderRadius: 10),
                  SizedBox(height: 12),
                  SkeletonBlock(width: 102, height: 14, borderRadius: 7),
                  SizedBox(height: 18),
                  SkeletonBlock(height: 12, borderRadius: 6),
                  SizedBox(height: 18),
                  SkeletonBlock(height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGrowthStats {
  const _HeroGrowthStats({
    required this.level,
    required this.currentXp,
    required this.xpMax,
  });

  final int level;
  final int currentXp;
  final int xpMax;

  double get progress => xpMax == 0 ? 0 : currentXp / xpMax;

  factory _HeroGrowthStats.fromSnapshot({
    required int checkedToday,
    required int maxStreak,
    required int totalRecords,
    required int focusMinutes,
  }) {
    final totalXp =
        totalRecords * 18 +
        checkedToday * 12 +
        min(maxStreak, 30) * 6 +
        (min(focusMinutes, 120) ~/ 3);
    return _HeroGrowthStats(
      level: max(1, (totalXp ~/ 100) + 1),
      currentXp: totalXp % 100,
      xpMax: 100,
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.dateLabel,
    required this.headlineGreeting,
    required this.growthStats,
    required this.pulseAnimation,
    required this.onAvatarTap,
    required this.onAiTap,
    this.onNotificationTap,
  });

  final UserProfileModel profile;
  final String dateLabel;
  final String headlineGreeting;
  final _HeroGrowthStats growthStats;
  final Animation<double> pulseAnimation;
  final VoidCallback onAvatarTap;
  final VoidCallback onAiTap;
  final VoidCallback? onNotificationTap;

  Widget _buildAvatarArt() {
    final fallback = PixelAvatar(
      config: profile.avatarConfig ?? AvatarConfig.defaultConfig,
      size: 112,
    );
    if (profile.avatarConfig != null) return fallback;
    if (profile.avatarAssetPath == null) return fallback;
    return Image.asset(
      profile.avatarAssetPath!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.surface,
            AppTheme.surfaceVariant.withValues(alpha: isDark ? 0.96 : 1),
            AppTheme.primaryMuted.withValues(alpha: isDark ? 0.48 : 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -34,
              right: -22,
              child: _AuraBlob(
                size: 116,
                color: AppTheme.accent.withValues(alpha: isDark ? 0.16 : 0.12),
              ),
            ),
            Positioned(
              bottom: -36,
              left: 68,
              child: _AuraBlob(
                size: 140,
                color: AppTheme.bonusMint.withValues(
                  alpha: isDark ? 0.14 : 0.1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _HeroAvatarFrame(
                    onTap: onAvatarTap,
                    child: _buildAvatarArt(),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    dateLabel,
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppTheme.textHint,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.h2.copyWith(
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    headlineGreeting,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onNotificationTap != null) ...<Widget>[
                              const SizedBox(width: AppTheme.spacingS),
                              _SoftIconButton(
                                icon: Icons.notifications_none_rounded,
                                onTap: onNotificationTap!,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        _HeroXpPanel(growthStats: growthStats),
                        const SizedBox(height: 12),
                        _HeroAiPill(
                          pulseAnimation: pulseAnimation,
                          onTap: onAiTap,
                        ),
                      ],
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
}

class _AuraBlob extends StatelessWidget {
  const _AuraBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _HeroAvatarFrame extends StatelessWidget {
  const _HeroAvatarFrame({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 112,
          height: 136,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: isDark ? 0.9 : 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.neuFlat,
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppTheme.surface,
                        AppTheme.surfaceVariant,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: const Offset(0, 8),
                  child: child,
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(
                      alpha: isDark ? 0.88 : 0.92,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PixelIcon(
                        icon: PixelIcons.pencil,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '编辑',
                        style: AppTextStyle.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroXpPanel extends StatelessWidget {
  const _HeroXpPanel({required this.growthStats});

  final _HeroGrowthStats growthStats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(
          alpha: AppTheme.isDarkMode ? 0.56 : 0.82,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Lv.${growthStats.level}',
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'XP ${growthStats.currentXp}/${growthStats.xpMax}',
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PixelProgressBar(
            progress: growthStats.progress,
            height: 8,
            blockCount: 16,
            activeColor: AppTheme.accentStrong,
            inactiveColor: AppTheme.surfaceDeep,
          ),
        ],
      ),
    );
  }
}

class _HeroAiPill extends StatelessWidget {
  const _HeroAiPill({required this.pulseAnimation, required this.onTap});

  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final pulse = pulseAnimation.value;
        final borderColor = Color.lerp(
          AppTheme.border,
          AppTheme.accent.withValues(alpha: AppTheme.isDarkMode ? 1 : 0.92),
          0.3 + pulse * 0.48,
        )!;
        final glowColor = AppTheme.accent.withValues(
          alpha: AppTheme.isDarkMode ? 0.12 + pulse * 0.14 : 0.08 + pulse * 0.1,
        );

        return TouchScaleWrapper(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(
                alpha: AppTheme.isDarkMode ? 0.58 : 0.8,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1.35),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: glowColor,
                  offset: const Offset(0, 6),
                  blurRadius: 16 + pulse * 8,
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: PixelIcon(
                      icon: PixelIcons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '和 AI 聊聊',
                    style: AppTextStyle.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppTheme.textHint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayDashboard extends StatelessWidget {
  const _TodayDashboard({
    required this.checkedToday,
    required this.activeCount,
    required this.maxStreak,
    required this.totalRecords,
    required this.todayFocusMinutes,
    required this.onShareTap,
  });

  final int checkedToday;
  final int activeCount;
  final int maxStreak;
  final int totalRecords;
  final int todayFocusMinutes;
  final VoidCallback onShareTap;

  static String _compactFocusMetric(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (hours == 0) return '${minutes}m';
    if (remain == 0) return '${hours}h';
    return '${hours}h ${remain}m';
  }

  @override
  Widget build(BuildContext context) {
    final completionRatio = activeCount == 0 ? 0.0 : checkedToday / activeCount;
    final nextMilestone = AppConstants.streakMilestones.firstWhere(
      (milestone) => milestone > maxStreak,
      orElse: () => AppConstants.streakMilestones.last,
    );
    final remainingDays = max(0, nextMilestone - maxStreak);
    final streakProgress = nextMilestone == 0 ? 1.0 : maxStreak / nextMilestone;
    final milestoneLine = remainingDays == 0
        ? '已点亮 $nextMilestone 天连续徽章，继续把记录线拉长。'
        : '连续 $maxStreak 天，离 $nextMilestone 天连续徽章还差 $remainingDays 天。';

    return TouchScaleWrapper(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.neuSubtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('今日看板', style: AppTextStyle.h3),
                      const SizedBox(height: 4),
                      Text(
                        '把今天先推进一格，整条旅程就会继续向前。',
                        style: AppTextStyle.bodySmall,
                      ),
                    ],
                  ),
                ),
                _SoftIconButton(
                  icon: Icons.ios_share_outlined,
                  onTap: onShareTap,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _PixelCompletionRing(
                  progress: completionRatio,
                  label: '$checkedToday/$activeCount',
                  subtitle: activeCount == 0 ? '今日无目标' : '今日完成',
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _MiniMetricCard(
                        icon: PixelIcons.fire,
                        accent: AppTheme.bonusRose,
                        value: '$maxStreak',
                        label: '连续天数',
                      ),
                      const SizedBox(height: 10),
                      _MiniMetricCard(
                        icon: PixelIcons.bolt,
                        accent: AppTheme.accent,
                        value: _compactFocusMetric(todayFocusMinutes),
                        label: '今日专注',
                      ),
                      const SizedBox(height: 10),
                      _MiniMetricCard(
                        icon: PixelIcons.chart,
                        accent: AppTheme.bonusMint,
                        value: '$totalRecords',
                        label: '累计记录',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            PixelProgressBar(
              progress: streakProgress.clamp(0.0, 1.0),
              height: 10,
              blockCount: 14,
              activeColor: AppTheme.primary,
              inactiveColor: AppTheme.surfaceDeep,
            ),
            const SizedBox(height: 8),
            Text(
              milestoneLine,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelCompletionRing extends StatelessWidget {
  const _PixelCompletionRing({
    required this.progress,
    required this.label,
    required this.subtitle,
  });

  final double progress;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      height: 152,
      child: CustomPaint(
        painter: _PixelRingPainter(
          progress: progress.clamp(0.0, 1.0),
          trackColor: AppTheme.surfaceDeep,
          activeColor: AppTheme.primary,
          highlightColor: Colors.white.withValues(
            alpha: AppTheme.isDarkMode ? 0.26 : 0.18,
          ),
          innerColor: AppTheme.surface,
          borderColor: AppTheme.border,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: AppTextStyle.h2.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelRingPainter extends CustomPainter {
  const _PixelRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.highlightColor,
    required this.innerColor,
    required this.borderColor,
  });

  final double progress;
  final Color trackColor;
  final Color activeColor;
  final Color highlightColor;
  final Color innerColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    const segmentCount = 28;
    final activeSegments = (segmentCount * progress).round().clamp(
      0,
      segmentCount,
    );
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.36;
    final blockSize = min(size.width, size.height) * 0.09;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var index = 0; index < segmentCount; index++) {
      final angle = (-pi / 2) + (2 * pi * index / segmentCount);
      final position =
          center + Offset(cos(angle) * radius, sin(angle) * radius);
      final rect = Rect.fromCenter(
        center: position,
        width: blockSize,
        height: blockSize,
      );
      final isActive = index < activeSegments;

      paint.color = isActive ? activeColor : trackColor;
      canvas.drawRect(rect, paint);
      if (isActive) {
        paint.color = highlightColor;
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.24),
          paint,
        );
      }
    }

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.55,
        height: size.height * 0.55,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(innerRect, Paint()..color = innerColor);
    canvas.drawRRect(
      innerRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.innerColor != innerColor ||
        oldDelegate.borderColor != borderColor;
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
  });

  final PixelIconData icon;
  final Color accent;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tint = accent.withValues(alpha: AppTheme.isDarkMode ? 0.2 : 0.12);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: AppTheme.isDarkMode ? 0.26 : 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: PixelIcon(icon: icon, size: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.h3.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyle.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  const _SoftIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(
              alpha: AppTheme.isDarkMode ? 0.56 : 0.86,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  const _QuickActionStrip({
    required this.canCheckIn,
    required this.onCreateGoal,
    required this.onQuickCheckIn,
    required this.onOpenJourney,
  });

  final bool canCheckIn;
  final VoidCallback onCreateGoal;
  final VoidCallback onQuickCheckIn;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('快捷操作', style: AppTextStyle.label.copyWith(letterSpacing: 0.35)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: <Widget>[
              _QuickActionPill(
                icon: PixelIcons.plus,
                label: '创建目标',
                backgroundColor: AppTheme.bonusMint.withValues(
                  alpha: AppTheme.isDarkMode ? 0.22 : 0.16,
                ),
                borderColor: AppTheme.bonusMint.withValues(alpha: 0.28),
                onTap: onCreateGoal,
              ),
              const SizedBox(width: 12),
              _QuickActionPill(
                icon: canCheckIn ? PixelIcons.check : PixelIcons.clock,
                label: '快速打卡',
                backgroundColor: AppTheme.accent.withValues(
                  alpha: AppTheme.isDarkMode ? 0.22 : 0.14,
                ),
                borderColor: AppTheme.accent.withValues(alpha: 0.3),
                onTap: onQuickCheckIn,
                enabled: canCheckIn,
              ),
              const SizedBox(width: 12),
              _QuickActionPill(
                icon: PixelIcons.flag,
                label: '查看旅程',
                backgroundColor: AppTheme.goldAccent.withValues(
                  alpha: AppTheme.isDarkMode ? 0.18 : 0.16,
                ),
                borderColor: AppTheme.goldAccent.withValues(alpha: 0.3),
                onTap: onOpenJourney,
                enabled: canCheckIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionPill extends StatefulWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    this.enabled = true,
  });

  final PixelIconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_QuickActionPill> createState() => _QuickActionPillState();
}

class _QuickActionPillState extends State<_QuickActionPill> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.enabled && _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.46,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: widget.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PixelIcon(icon: widget.icon, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    this.titleTrailing,
  });

  final String eyebrow;
  final String title;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(eyebrow, style: AppTextStyle.label),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: Text(title, style: AppTextStyle.h2)),
            if (titleTrailing != null) ...<Widget>[titleTrailing!],
          ],
        ),
      ],
    );
  }
}

class _BadgeUnlockCaption extends StatelessWidget {
  const _BadgeUnlockCaption({required this.badges});

  final List<CollectibleBadge> badges;

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((badge) => badge.unlocked).length;
    final total = badges.length;
    final hintStyle = AppTextStyle.caption.copyWith(color: AppTheme.textHint);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Text.rich(
        TextSpan(
          style: AppTextStyle.caption,
          children: <InlineSpan>[
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

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.badges, required this.controller});

  final List<CollectibleBadge> badges;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final ordered = <CollectibleBadge>[
      ...badges.where((badge) => badge.unlocked),
      ...badges.where((badge) => !badge.unlocked),
    ];

    if (ordered.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 168,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List<Widget>.generate(ordered.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == ordered.length - 1 ? 0 : AppTheme.spacingM,
              ),
              child: _StaggeredReveal(
                controller: controller,
                index: index,
                baseDelayMs: 40,
                child: SizedBox(
                  width: 160,
                  child: _BadgeTile(badge: ordered[index]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final CollectibleBadge badge;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme
        .rewardPalette[badge.colorIndex % AppTheme.rewardPalette.length];
    final unlocked = badge.unlocked;

    return TouchScaleWrapper(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: unlocked ? AppTheme.surface : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: unlocked ? accent.withValues(alpha: 0.26) : AppTheme.border,
          ),
          boxShadow: unlocked ? AppTheme.neuSubtle : const <BoxShadow>[],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: unlocked
                    ? accent.withValues(
                        alpha: AppTheme.isDarkMode ? 0.24 : 0.18,
                      )
                    : AppTheme.surfaceDeep,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Center(
                child: Opacity(
                  opacity: unlocked ? 1 : 0.48,
                  child: PixelIcon(icon: badge.icon, size: 18),
                ),
              ),
            ),
            const Spacer(),
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.w700,
                color: unlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(
                color: unlocked ? AppTheme.textSecondary : AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: unlocked
                    ? accent.withValues(alpha: AppTheme.isDarkMode ? 0.2 : 0.14)
                    : AppTheme.surfaceDeep,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unlocked ? '已解锁' : '待点亮',
                style: AppTextStyle.caption.copyWith(
                  color: unlocked ? accent : AppTheme.textHint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredReveal extends StatelessWidget {
  const _StaggeredReveal({
    required this.controller,
    required this.index,
    required this.child,
    this.baseDelayMs = 0,
  });

  final AnimationController controller;
  final int index;
  final int baseDelayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const stepDelayMs = 60;
    const enterDurationMs = 360;
    final totalMs = max(controller.duration?.inMilliseconds ?? 1, 1).toDouble();
    final startMs = baseDelayMs + index * stepDelayMs;
    final start = (startMs / totalMs).clamp(0.0, 0.94);
    final end = ((startMs + enterDurationMs) / totalMs).clamp(
      start + 0.001,
      1.0,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
