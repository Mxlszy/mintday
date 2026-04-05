import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/journey_insights.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/goal_twelve_week_heatmap.dart';
import '../../widgets/pixel_progress_bar.dart';
import '../../widgets/progress_ring.dart';
import '../check_in/check_in_detail_page.dart';
import '../check_in/check_in_page.dart';

class GoalDetailPage extends StatelessWidget {
  final String goalId;

  const GoalDetailPage({
    super.key,
    required this.goalId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalProvider, CheckInProvider>(
      builder: (context, goalProvider, checkInProvider, _) {
        final goal = goalProvider.getGoalById(goalId);
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('目标不存在')),
          );
        }

        final isCheckedToday = checkInProvider.isTodayChecked(goalId);
        final streak = checkInProvider.getStreak(goalId);
        final checkIns = checkInProvider.getCheckInsForGoal(goalId);
        final heatmapCounts = GoalDetailPage._heatmapCountsForGoal(checkIns);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(goal.title),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenu(context, value, goal),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'complete', child: Text('标记完成')),
                  const PopupMenuItem(value: 'archive', child: Text('归档')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      '删除',
                      style: AppTextStyle.body.copyWith(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              140,
            ),
            children: [
              _HeroCard(
                goal: goal,
                streak: streak,
                totalCheckIns: checkIns.length,
              ),
              const SizedBox(height: AppTheme.spacingL),
              _JourneySection(
                goal: goal,
                streak: streak,
                totalCheckIns: checkIns.length,
              ),
              const SizedBox(height: AppTheme.spacingL),
              GoalTwelveWeekHeatmap(
                countByDate: heatmapCounts,
                onDayTap: (date) {
                  final key =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final n = heatmapCounts[key] ?? 0;
                  final msg = n == 0
                      ? '${AppUtils.friendlyDate(date)} · 这一天还没有记录'
                      : '${AppUtils.friendlyDate(date)} · $n 次打卡';
                  AppUtils.showSnackBar(context, msg);
                },
              ),
              if (goal.reason != null || goal.vision != null) ...[
                const SizedBox(height: AppTheme.spacingL),
                _NarrativeSection(goal: goal),
              ],
              if (goal.steps.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingL),
                _StepsSection(goal: goal),
              ],
              if (checkIns.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingL),
                _CheckInHistory(goal: goal, checkIns: checkIns),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                0,
                AppTheme.spacingL,
                AppTheme.spacingL,
              ),
              child: isCheckedToday
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMuted,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PixelIcon(
                            icon: PixelIcons.check,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '今天已经记录过了',
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckInPage(goalId: goal.id),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('去打卡'),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  /// 单目标、非跳过打卡，按日历日聚合（与热力图 key 一致）。
  static Map<String, int> _heatmapCountsForGoal(List<CheckIn> checkIns) {
    final map = <String, int>{};
    for (final c in checkIns) {
      if (c.status == CheckInStatus.skipped) continue;
      map[c.dateString] = (map[c.dateString] ?? 0) + 1;
    }
    return map;
  }

  void _handleMenu(BuildContext context, String value, Goal goal) {
    final provider = context.read<GoalProvider>();
    switch (value) {
      case 'complete':
        provider.completeGoal(goal.id);
        Navigator.of(context).pop();
        break;
      case 'archive':
        provider.archiveGoal(goal.id);
        Navigator.of(context).pop();
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('删除目标'),
            content: const Text('删除后无法恢复，确认继续吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  provider.deleteGoal(goal.id);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  '删除',
                  style: AppTextStyle.body.copyWith(color: AppTheme.error),
                ),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class _HeroCard extends StatelessWidget {
  final Goal goal;
  final int streak;
  final int totalCheckIns;

  const _HeroCard({
    required this.goal,
    required this.streak,
    required this.totalCheckIns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressRing(
            progress: goal.progress,
            size: 82,
            strokeWidth: 7,
            showLabel: true,
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    goal.category.label,
                    style: AppTextStyle.caption.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _MetaLine(
                  icon: PixelIcons.fire,
                  text: AppUtils.streakText(streak),
                ),
                const SizedBox(height: 8),
                _MetaLine(
                  icon: PixelIcons.check,
                  text: '累计记录 $totalCheckIns 次',
                ),
                if (goal.deadline != null) ...[
                  const SizedBox(height: 8),
                  _MetaLine(
                    icon: PixelIcons.clock,
                    text: '截止 ${AppUtils.friendlyDate(goal.deadline!)}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneySection extends StatelessWidget {
  final Goal goal;
  final int streak;
  final int totalCheckIns;

  const _JourneySection({
    required this.goal,
    required this.streak,
    required this.totalCheckIns,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = buildJourneyNodes(
      goal: goal,
      streakDays: streak,
      totalCheckIns: totalCheckIns,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('旅程地图', style: AppTextStyle.h3),
          const SizedBox(height: 6),
          Text('现在正走到哪里，一眼就能看到。', style: AppTextStyle.bodySmall),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < nodes.length; index++) ...[
                Expanded(child: _JourneyNodeView(node: nodes[index])),
                if (index < nodes.length - 1)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 18),
                      height: 2,
                      color: nodes[index].status == JourneyNodeStatus.locked
                          ? AppTheme.surfaceDeep
                          : AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          PixelProgressBar(
            progress: goal.progress,
            height: 10,
            blockCount: 14,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceDeep,
          ),
        ],
      ),
    );
  }
}

class _NarrativeSection extends StatelessWidget {
  final Goal goal;

  const _NarrativeSection({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('这段旅程为什么重要', style: AppTextStyle.h3),
          if (goal.reason != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text('开始原因', style: AppTextStyle.label),
            const SizedBox(height: 6),
            Text(goal.reason!, style: AppTextStyle.body),
          ],
          if (goal.vision != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            Text('未来想成为谁', style: AppTextStyle.label),
            const SizedBox(height: 6),
            Text(goal.vision!, style: AppTextStyle.body),
          ],
        ],
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  final Goal goal;

  const _StepsSection({required this.goal});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GoalProvider>();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目标步骤', style: AppTextStyle.h3),
          const SizedBox(height: AppTheme.spacingM),
          ...goal.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isDone =
                index < goal.completedSteps.length && goal.completedSteps[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: () => provider.toggleStep(goal.id, index),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color:
                        isDone ? AppTheme.primaryMuted : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.primary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: isDone
                            ? const Center(
                                child: PixelIcon(
                                  icon: PixelIcons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          step,
                          style: AppTextStyle.body.copyWith(
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CheckInHistory extends StatelessWidget {
  final Goal goal;
  final List<CheckIn> checkIns;

  const _CheckInHistory({
    required this.goal,
    required this.checkIns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近记录', style: AppTextStyle.h3),
          const SizedBox(height: AppTheme.spacingM),
          ...checkIns.take(10).map((checkIn) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckInDetailPage(
                        checkIn: checkIn,
                        goalTitle: goal.title,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Row(
                    children: [
                      Text(
                        checkIn.moodEmoji,
                        style: AppTextStyle.body.copyWith(fontSize: 18),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppUtils.friendlyDate(checkIn.date),
                              style: AppTextStyle.bodySmall,
                            ),
                            if (_summaryText(checkIn) != null)
                              Text(
                                _summaryText(checkIn)!,
                                style: AppTextStyle.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        checkIn.status.label,
                        style: AppTextStyle.caption.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (checkIns.length > 10)
            Center(
              child: Text(
                '还有 ${checkIns.length - 10} 条记录',
                style: AppTextStyle.caption,
              ),
            ),
        ],
      ),
    );
  }

  String? _summaryText(CheckIn checkIn) {
    if (checkIn.note != null && checkIn.note!.isNotEmpty) {
      return checkIn.note!;
    }
    if (checkIn.reflectionProgress != null &&
        checkIn.reflectionProgress!.isNotEmpty) {
      return checkIn.reflectionProgress!;
    }
    if (checkIn.reflectionNext != null &&
        checkIn.reflectionNext!.isNotEmpty) {
      return checkIn.reflectionNext!;
    }
    if (checkIn.imagePaths.isNotEmpty) {
      return '附加了 ${checkIn.imagePaths.length} 张图片';
    }
    return null;
  }
}

class _MetaLine extends StatelessWidget {
  final PixelIconData icon;
  final String text;

  const _MetaLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PixelIcon(icon: icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyle.bodySmall),
      ],
    );
  }
}

class _JourneyNodeView extends StatelessWidget {
  final JourneyNode node;

  const _JourneyNodeView({required this.node});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (node.status) {
      JourneyNodeStatus.complete => (AppTheme.accentLight, AppTheme.accentStrong),
      JourneyNodeStatus.current => (AppTheme.primary, Colors.white),
      JourneyNodeStatus.locked => (AppTheme.surfaceVariant, AppTheme.textHint),
    };

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: PixelIcon(
              icon: node.icon,
              size: 16,
              color: foreground,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          node.label,
          style: AppTextStyle.caption.copyWith(
            color: node.status == JourneyNodeStatus.locked
                ? AppTheme.textHint
                : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          node.caption,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
