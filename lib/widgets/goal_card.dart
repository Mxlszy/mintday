import 'package:flutter/material.dart';
import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/utils.dart';
import '../models/goal.dart';
import '../pages/goal/goal_detail_page.dart';
import 'pixel_progress_bar.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final bool isCheckedToday;
  final int streakDays;

  const GoalCard({
    super.key,
    required this.goal,
    required this.isCheckedToday,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = goal.steps.length;
    final completedSteps = goal.completedStepCount;
    final metaText = totalSteps == 0
        ? '持续记录中'
        : '$completedSteps / $totalSteps 步';

    return NeuContainer(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      borderRadius: AppTheme.radiusL,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoalDetailPage(goalId: goal.id),
          ),
        );
      },
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
                    Text(
                      goal.title,
                      style: AppTextStyle.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(goal.category.label, style: AppTextStyle.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Center(
                  child: PixelIcon(
                    icon: PixelIcons.forCategory(goal.category.value),
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _MetaPill(label: metaText, icon: PixelIcons.chart),
              _MetaPill(
                label: AppUtils.streakText(streakDays),
                icon: PixelIcons.fire,
                color: streakDays > 0 ? AppTheme.accentStrong : null,
              ),
              _MetaPill(
                label: isCheckedToday ? '今日已记录' : '等待今日记录',
                icon: isCheckedToday ? PixelIcons.check : PixelIcons.clock,
                emphasis: isCheckedToday,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: PixelProgressBar(
                  progress: goal.progress,
                  height: 10,
                  blockCount: 12,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.surfaceDeep,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                AppUtils.progressText(goal.progress),
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final PixelIconData icon;
  final Color? color;
  final bool emphasis;

  const _MetaPill({
    required this.label,
    required this.icon,
    this.color,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        color ?? (emphasis ? AppTheme.primary : AppTheme.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: emphasis ? AppTheme.primaryMuted : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelIcon(
            icon: icon,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
