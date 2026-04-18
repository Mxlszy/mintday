import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/neumorphic.dart';
import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/goal.dart';
import '../../pages/goal/create_goal_page.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/skeleton_loader.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  bool _isBreathing = false;
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalProvider, FocusProvider>(
      builder: (context, goalProvider, focusProvider, _) {
        _syncBreathing(focusProvider.isRunning);

        final isInitialLoading =
            (goalProvider.isLoading && goalProvider.goals.isEmpty) ||
            (focusProvider.isLoading && focusProvider.sessions.isEmpty);

        if (isInitialLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('专注计时')),
            body: const _FocusSkeletonView(),
          );
        }

        final currentGoal = focusProvider.currentGoalId == null
            ? null
            : goalProvider.getGoalById(focusProvider.currentGoalId!);
        final goals = _buildSelectorGoals(
          goalProvider.activeGoals,
          currentGoal,
        );
        final selectedGoalId =
            focusProvider.currentGoalId ??
            _selectedGoalId ??
            _firstGoalId(goals);
        final selectedGoal = _findGoalById(goals, selectedGoalId);

        if (goals.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('专注计时')),
            body: Stack(
              children: [
                _FocusBackground(animation: _breathController, isActive: false),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: NeuContainer(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelIcon(
                            icon: PixelIcons.bolt,
                            size: 40,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text('先选一个目标，再开始专注', style: AppTextStyle.h2),
                          const SizedBox(height: 8),
                          Text(
                            '创建目标后，就能为它启动专注计时并累计投入时长。',
                            textAlign: TextAlign.center,
                            style: AppTextStyle.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).push(fadeSlideRoute(const CreateGoalPage()));
                              },
                              child: const Text('去创建目标'),
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
        }

        final liveTotalMinutes = selectedGoal == null
            ? 0
            : focusProvider.getTotalFocusMinutesForGoal(selectedGoal.id) +
                  (focusProvider.currentGoalId == selectedGoal.id
                      ? focusProvider.elapsedSeconds ~/ 60
                      : 0);
        final todayFocusMinutes = focusProvider.getTodayFocusMinutes();
        final weekFocusMinutes = focusProvider.getWeekFocusMinutes();
        final targetSeconds = FocusProvider.defaultTargetDurationSeconds;
        final extraSeconds = (focusProvider.elapsedSeconds - targetSeconds)
            .clamp(0, 1 << 30)
            .toInt();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('专注计时')),
          body: Stack(
            children: [
              _FocusBackground(
                animation: _breathController,
                isActive: focusProvider.isRunning,
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  140,
                ),
                children: [
                  _FocusOverviewCard(
                    todayFocusMinutes: todayFocusMinutes,
                    weekFocusMinutes: weekFocusMinutes,
                    statusText: focusProvider.isRunning
                        ? '正在专注'
                        : (focusProvider.isPaused ? '已暂停' : '准备开始'),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text('选择本轮要投入的目标', style: AppTextStyle.label),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 152,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: goals.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppTheme.spacingM),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final isSelected = goal.id == selectedGoalId;
                        return _FocusGoalTile(
                          goal: goal,
                          isSelected: isSelected,
                          isLocked: focusProvider.hasActiveSession,
                          onTap: () {
                            if (focusProvider.hasActiveSession) return;
                            setState(() => _selectedGoalId = goal.id);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  _FocusTimerCard(
                    goalTitle: selectedGoal?.title ?? '请选择目标',
                    elapsedSeconds: focusProvider.elapsedSeconds,
                    progress: focusProvider.progressToTarget,
                    isRunning: focusProvider.isRunning,
                    isPaused: focusProvider.isPaused,
                    totalMinutes: liveTotalMinutes,
                    extraSeconds: extraSeconds,
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  _FocusControls(
                    isIdle: !focusProvider.hasActiveSession,
                    isRunning: focusProvider.isRunning,
                    isPaused: focusProvider.isPaused,
                    canStart: selectedGoalId != null,
                    onStart: () =>
                        _handleStart(context, focusProvider, selectedGoalId),
                    onPause: focusProvider.pause,
                    onResume: focusProvider.resume,
                    onComplete: selectedGoal == null
                        ? null
                        : () => _handleComplete(context, selectedGoal),
                    onCancel: () => _handleCancel(context, focusProvider),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncBreathing(bool shouldAnimate) {
    if (shouldAnimate == _isBreathing) return;
    _isBreathing = shouldAnimate;
    if (shouldAnimate) {
      _breathController.repeat(reverse: true);
    } else {
      _breathController.stop();
      _breathController.value = 0;
    }
  }

  List<Goal> _buildSelectorGoals(List<Goal> activeGoals, Goal? currentGoal) {
    if (currentGoal == null) return activeGoals;
    if (activeGoals.any((goal) => goal.id == currentGoal.id)) {
      return activeGoals;
    }
    return [currentGoal, ...activeGoals];
  }

  String? _firstGoalId(List<Goal> goals) {
    if (goals.isEmpty) return null;
    return goals.first.id;
  }

  Goal? _findGoalById(List<Goal> goals, String? goalId) {
    if (goalId == null) return null;
    for (final goal in goals) {
      if (goal.id == goalId) return goal;
    }
    return null;
  }

  void _handleStart(
    BuildContext context,
    FocusProvider focusProvider,
    String? goalId,
  ) {
    if (goalId == null) {
      AppUtils.showSnackBar(context, '请先选择一个目标', isError: true);
      return;
    }
    final started = focusProvider.start(goalId);
    if (!started) {
      AppUtils.showSnackBar(context, '当前已有进行中的专注', isError: true);
    }
  }

  Future<void> _handleComplete(BuildContext context, Goal goal) async {
    final focusProvider = context.read<FocusProvider>();
    if (focusProvider.elapsedSeconds <= 0) {
      AppUtils.showSnackBar(context, '至少开始一次专注后再完成记录', isError: true);
      return;
    }

    final checkInProvider = context.read<CheckInProvider>();
    final currentStreak = checkInProvider.getStreak(goal.id);
    final predictedStreak = checkInProvider.isTodayChecked(goal.id)
        ? currentStreak
        : currentStreak + 1;

    final saved =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _FocusCompleteSheet(
            goalTitle: goal.title,
            durationSeconds: focusProvider.elapsedSeconds,
            predictedStreak: predictedStreak,
          ),
        ) ??
        false;

    if (!context.mounted || !saved) return;
    AppUtils.showSnackBar(context, '本次专注已记录');
  }

  Future<void> _handleCancel(
    BuildContext context,
    FocusProvider focusProvider,
  ) async {
    await focusProvider.cancel();
    if (!context.mounted) return;
    AppUtils.showSnackBar(context, '本次专注已放弃');
  }
}

class _FocusSkeletonView extends StatelessWidget {
  const _FocusSkeletonView();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          140,
        ),
        children: const [
          SkeletonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 164, height: 22, borderRadius: 10),
                SizedBox(height: 10),
                SkeletonBlock(height: 14, borderRadius: 7),
                SizedBox(height: AppTheme.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: SkeletonBlock(height: 72, borderRadius: 18),
                    ),
                    SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: SkeletonBlock(height: 72, borderRadius: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingL),
          SkeletonBlock(width: 138, height: 14, borderRadius: 7),
          SizedBox(height: 10),
          SizedBox(
            height: 152,
            child: Row(
              children: [
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
          SizedBox(height: AppTheme.spacingXL),
          SkeletonCard(
            child: Column(
              children: [
                SkeletonBlock(width: 168, height: 24, borderRadius: 10),
                SizedBox(height: 12),
                SkeletonBlock(width: 132, height: 14, borderRadius: 7),
                SizedBox(height: AppTheme.spacingXL),
                SkeletonBlock(width: 288, height: 288, borderRadius: 144),
                SizedBox(height: AppTheme.spacingL),
                SkeletonBlock(width: 172, height: 14, borderRadius: 7),
                SizedBox(height: 12),
                SkeletonBlock(width: 196, height: 16, borderRadius: 8),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),
          Row(
            children: [
              Expanded(child: SkeletonBlock(height: 54, borderRadius: 20)),
              SizedBox(width: AppTheme.spacingM),
              Expanded(child: SkeletonBlock(height: 54, borderRadius: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusBackground extends StatelessWidget {
  final Animation<double> animation;
  final bool isActive;

  const _FocusBackground({required this.animation, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final pulse = isActive ? animation.value : 0.0;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.background,
                    AppTheme.primaryMuted.withValues(alpha: 0.88),
                    AppTheme.accentLight.withValues(
                      alpha: isActive ? 0.55 + pulse * 0.2 : 0.35,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -60,
              child: _GlowOrb(
                size: 220 + pulse * 36,
                color: AppTheme.accent.withValues(
                  alpha: isActive ? 0.16 + pulse * 0.08 : 0.08,
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 120,
              child: _GlowOrb(
                size: 180 + pulse * 24,
                color: AppTheme.bonusMint.withValues(
                  alpha: isActive ? 0.16 + pulse * 0.08 : 0.08,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}

class _FocusOverviewCard extends StatelessWidget {
  final int todayFocusMinutes;
  final int weekFocusMinutes;
  final String statusText;

  const _FocusOverviewCard({
    required this.todayFocusMinutes,
    required this.weekFocusMinutes,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Center(
                  child: PixelIcon(
                    icon: PixelIcons.bolt,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('把注意力留给此刻最重要的事', style: AppTextStyle.h3),
                    const SizedBox(height: 4),
                    Text(statusText, style: AppTextStyle.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: '今日专注',
                  value: _compactDuration(todayFocusMinutes),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _OverviewMetric(
                  label: '本周专注',
                  value: _compactDuration(weekFocusMinutes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _compactDuration(int minutes) {
    if (minutes <= 0) return '0 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (hours == 0) return '$minutes 分钟';
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分';
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyle.caption),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyle.h3),
        ],
      ),
    );
  }
}

class _FocusGoalTile extends StatelessWidget {
  final Goal goal;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _FocusGoalTile({
    required this.goal,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 176,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingM,
          AppTheme.spacingM,
          AppTheme.spacingM,
          AppTheme.spacingL,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
          boxShadow: isSelected ? AppTheme.neuRaised : AppTheme.neuSubtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Center(
                    child: PixelIcon(
                      icon: PixelIcons.forCategory(goal.category.value),
                      size: 18,
                      color: isSelected ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (isLocked && isSelected)
                  const PixelIcon(
                    icon: PixelIcons.lock,
                    size: 16,
                    color: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    goal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.body.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.caption.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.72)
                          : AppTheme.textHint,
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

class _FocusTimerCard extends StatelessWidget {
  final String goalTitle;
  final int elapsedSeconds;
  final double progress;
  final bool isRunning;
  final bool isPaused;
  final int totalMinutes;
  final int extraSeconds;

  const _FocusTimerCard({
    required this.goalTitle,
    required this.elapsedSeconds,
    required this.progress,
    required this.isRunning,
    required this.isPaused,
    required this.totalMinutes,
    required this.extraSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isRunning
        ? AppTheme.accentStrong
        : (isPaused ? AppTheme.bonusRose : AppTheme.primary);

    return NeuContainer(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingXL,
        AppTheme.spacingL,
        AppTheme.spacingXL,
      ),
      child: Column(
        children: [
          Text(goalTitle, textAlign: TextAlign.center, style: AppTextStyle.h3),
          const SizedBox(height: 10),
          Text(
            isRunning
                ? '保持节奏，让这一段时间只属于它'
                : (isPaused ? '暂停一下，也是在为下一次进入状态做准备' : '默认目标 25 分钟'),
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 288,
                height: 288,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceVariant,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.04),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress,
                size: 288,
                strokeWidth: 14,
                color: ringColor,
                backgroundColor: AppTheme.surfaceDeep,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatClock(elapsedSeconds),
                    style: AppTextStyle.h1.copyWith(
                      fontSize: 44,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRunning ? '专注进行中' : (isPaused ? '专注已暂停' : '等待开始'),
                    style: AppTextStyle.label.copyWith(
                      color: ringColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (extraSeconds > 0)
            Text(
              '已超出默认目标 ${_formatBriefDuration(extraSeconds)}',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppTheme.accentStrong,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              '已完成 ${(progress * 100).toInt()}% 的默认目标',
              style: AppTextStyle.bodySmall,
            ),
          const SizedBox(height: 12),
          Text(
            '累计已为此目标专注 ${AppUtils.formatDuration(totalMinutes)}',
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  static String _formatClock(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainSeconds.toString().padLeft(2, '0')}';
  }

  static String _formatBriefDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    if (minutes <= 0) return '$remainSeconds 秒';
    if (remainSeconds == 0) return '$minutes 分钟';
    return '$minutes 分 $remainSeconds 秒';
  }
}

class _FocusControls extends StatelessWidget {
  final bool isIdle;
  final bool isRunning;
  final bool isPaused;
  final bool canStart;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onComplete;
  final VoidCallback onCancel;

  const _FocusControls({
    required this.isIdle,
    required this.isRunning,
    required this.isPaused,
    required this.canStart,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isIdle) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canStart ? onStart : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('开始专注'),
          ),
        ),
      );
    }

    if (isRunning) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onPause,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('暂停'),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: onComplete,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('完成'),
              ),
            ),
          ),
        ],
      );
    }

    if (isPaused) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onResume,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('继续'),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.bonusRose,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('放弃'),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _FocusCompleteSheet extends StatefulWidget {
  final String goalTitle;
  final int durationSeconds;
  final int predictedStreak;

  const _FocusCompleteSheet({
    required this.goalTitle,
    required this.durationSeconds,
    required this.predictedStreak,
  });

  @override
  State<_FocusCompleteSheet> createState() => _FocusCompleteSheetState();
}

class _FocusCompleteSheetState extends State<_FocusCompleteSheet> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingM,
        AppTheme.spacingL,
        AppTheme.spacingL + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.neuRaised,
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Center(
                  child: PixelIcon(
                    icon: PixelIcons.trophy,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('完成这段专注', style: AppTextStyle.h2),
                    const SizedBox(height: 4),
                    Text(
                      widget.goalTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _SummaryRow(
            label: '本次专注',
            value: _formatFocusDuration(widget.durationSeconds),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: '连续天数',
            value: widget.predictedStreak <= 0
                ? '今天重新开始'
                : '${widget.predictedStreak} 天',
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text('结束备注', style: AppTextStyle.label),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: '写下一句总结，稍后会一起保存'),
            maxLines: 3,
            maxLength: 80,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('稍后再说'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('确认记录'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final session = await context.read<FocusProvider>().complete(
      _noteController.text,
    );
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (session == null) {
      AppUtils.showSnackBar(context, '保存失败，请稍后重试', isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  static String _formatFocusDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainSeconds = seconds % 60;

    if (hours > 0) {
      if (minutes == 0 && remainSeconds == 0) return '$hours 小时';
      if (remainSeconds == 0) return '$hours 小时 $minutes 分钟';
      return '$hours 小时 $minutes 分钟 $remainSeconds 秒';
    }
    if (minutes > 0) {
      if (remainSeconds == 0) return '$minutes 分钟';
      return '$minutes 分钟 $remainSeconds 秒';
    }
    return '$remainSeconds 秒';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyle.bodySmall),
          Text(
            value,
            style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
