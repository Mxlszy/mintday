import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/journey_insights.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/share_export_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pixel_mood_line_chart.dart';
import '../../widgets/pixel_progress_bar.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer2<GoalProvider, CheckInProvider>(
          builder: (context, goalProvider, checkInProvider, _) {
            final goals = goalProvider.goals;
            final maxStreak = _maxStreak(checkInProvider, goals);
            final badges = buildCollectibleBadges(
              goals: goals,
              checkIns: checkInProvider.checkIns,
              maxStreak: maxStreak,
            );
            final orderedBadges = [
              ...badges.where((b) => b.unlocked),
              ...badges.where((b) => !b.unlocked),
            ];
            final unlockedCount =
                badges.where((badge) => badge.unlocked).length;
            final completedCount = goals
                .where((goal) => goal.status == GoalStatus.completed)
                .length;

            // 统一用 CustomScrollView，整页一体滚动
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── 顶部固定内容区（随页面一起上滑）──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.progressPageTitle, style: AppTextStyle.h1),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.progressPageSubtitle,
                          style: AppTextStyle.bodySmall,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _OverviewBoard(
                          unlockedCount: unlockedCount,
                          activeCount: goalProvider.activeGoals.length,
                          completedCount: completedCount,
                          maxStreak: maxStreak,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _ViewSwitch(
                          selectedView: _selectedView,
                          onChanged: (v) =>
                              setState(() => _selectedView = v),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        PixelMoodLineChart(
                          checkIns: checkInProvider.checkIns,
                        ),
                        if (checkInProvider.checkIns.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingM),
                          Consumer<ShareExportProvider>(
                            builder: (context, share, _) =>
                                _AnnualReportSection(
                              checkIns: checkInProvider.checkIns,
                              maxStreak: maxStreak,
                              shareBusy: share.isBusy,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingM),
                      ],
                    ),
                  ),
                ),

                // ── 空状态 ──
                if (goals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        0,
                        AppTheme.spacingL,
                        120,
                      ),
                      child: const EmptyState(
                        title: AppStrings.progressEmptyBadgesTitle,
                        subtitle: AppStrings.progressEmptyBadgesSubtitle,
                      ),
                    ),
                  ),

                // ── 旅程地图（SliverList）──
                if (goals.isNotEmpty && _selectedView == 0)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      0,
                      AppTheme.spacingL,
                      140,
                    ),
                    sliver: SliverList.separated(
                      itemCount: goals.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacingM),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final streak =
                            checkInProvider.getStreak(goal.id);
                        final totalCheckIns = checkInProvider
                            .getCheckInsForGoal(goal.id)
                            .length;
                        return _JourneyCard(
                          goal: goal,
                          streakDays: streak,
                          totalCheckIns: totalCheckIns,
                        );
                      },
                    ),
                  ),

                // ── 徽章墙（SliverGrid）──
                if (goals.isNotEmpty && _selectedView == 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      0,
                      AppTheme.spacingL,
                      140,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppTheme.spacingM,
                        crossAxisSpacing: AppTheme.spacingM,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: orderedBadges.length,
                      itemBuilder: (context, index) {
                        final badge = orderedBadges[index];
                        final accent = AppTheme.rewardPalette[
                            badge.colorIndex %
                                AppTheme.rewardPalette.length];
                        return _BadgeCard(
                          badge: badge,
                          accent: accent,
                        );
                      },
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
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }
}

class _AnnualReportSection extends StatelessWidget {
  final List<CheckIn> checkIns;
  final int maxStreak;
  final bool shareBusy;

  const _AnnualReportSection({
    required this.checkIns,
    required this.maxStreak,
    required this.shareBusy,
  });

  /// 1.0–1.4 😣 · 1.5–2.4 😐 · 2.5–3.4 🙂 · 3.5–4.4 😊 · 4.5–5.0 🤩
  static String _emojiForMoodAverage(double avg) {
    if (avg < 1.5) return '😣';
    if (avg < 2.5) return '😐';
    if (avg < 3.5) return '🙂';
    if (avg < 4.5) return '😊';
    return '🤩';
  }

  String _avgMoodDisplay() {
    final list =
        checkIns.where((c) => c.mood != null).map((c) => c.mood!).toList();
    if (list.isEmpty) return '暂无';
    final sum = list.fold<int>(0, (a, b) => a + b);
    final avg = sum / list.length;
    final one = (avg * 10).round() / 10;
    final em = _emojiForMoodAverage(avg);
    return '${one.toStringAsFixed(1)} $em';
  }

  void _showReportPlaceholderSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingL,
          AppTheme.spacingL + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              AppStrings.annualReportComingSoon,
              textAlign: TextAlign.center,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spacingL),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(AppStrings.annualReportComingSoonButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelIcon(
                icon: PixelIcons.calendar,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text('年度报告', style: AppTextStyle.h3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _ReportStatCell(
                  label: '累计记录',
                  value: '${checkIns.length}',
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppTheme.border,
              ),
              Expanded(
                child: _ReportStatCell(
                  label: '最长连续',
                  value: maxStreak == 0 ? '—' : '$maxStreak 天',
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppTheme.border,
              ),
              Expanded(
                child: _ReportStatCell(
                  label: '平均心情',
                  value: _avgMoodDisplay(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: shareBusy
                      ? null
                      : () => _showReportPlaceholderSheet(context),
                  child: const Text('生成报告'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton(
                  onPressed: shareBusy
                      ? null
                      : () => context
                          .read<ShareExportProvider>()
                          .shareAllCheckInsCsv(context),
                  child: shareBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('导出 CSV'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportStatCell extends StatelessWidget {
  final String label;
  final String value;

  const _ReportStatCell({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyle.caption),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.h3,
          ),
        ],
      ),
    );
  }
}

class _OverviewBoard extends StatelessWidget {
  final int unlockedCount;
  final int activeCount;
  final int completedCount;
  final int maxStreak;

  const _OverviewBoard({
    required this.unlockedCount,
    required this.activeCount,
    required this.completedCount,
    required this.maxStreak,
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
        children: [
          Expanded(
            child: _OverviewMetric(
              label: '已点亮',
              value: '$unlockedCount',
              icon: PixelIcons.medal,
            ),
          ),
          Expanded(
            child: _OverviewMetric(
              label: '进行中',
              value: '$activeCount',
              icon: PixelIcons.flag,
            ),
          ),
          Expanded(
            child: _OverviewMetric(
              label: '已完成',
              value: '$completedCount',
              icon: PixelIcons.trophy,
            ),
          ),
          Expanded(
            child: _OverviewMetric(
              label: '最长连续',
              value: maxStreak == 0 ? '-' : '$maxStreak',
              icon: PixelIcons.fire,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final PixelIconData icon;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PixelIcon(icon: icon, size: 18),
        const SizedBox(height: 10),
        Text(value, style: AppTextStyle.h3),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyle.caption),
      ],
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  final int selectedView;
  final ValueChanged<int> onChanged;

  const _ViewSwitch({
    required this.selectedView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              selected: selectedView == 0,
              label: AppStrings.progressViewJourney,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SwitchButton(
              selected: selectedView == 1,
              label: AppStrings.progressViewBadges,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.primaryMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


class _JourneyCard extends StatelessWidget {
  final Goal goal;
  final int streakDays;
  final int totalCheckIns;

  const _JourneyCard({
    required this.goal,
    required this.streakDays,
    required this.totalCheckIns,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = buildJourneyNodes(
      goal: goal,
      streakDays: streakDays,
      totalCheckIns: totalCheckIns,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
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
                    Text(goal.title, style: AppTextStyle.h3),
                    const SizedBox(height: 6),
                    Text(goal.category.label, style: AppTextStyle.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  AppUtils.progressText(goal.progress),
                  style: AppTextStyle.caption.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              _MiniJourneyStat(label: '记录', value: '$totalCheckIns 次'),
              const SizedBox(width: AppTheme.spacingM),
              _MiniJourneyStat(
                label: '连续',
                value: streakDays == 0 ? '尚未开始' : '$streakDays 天',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _JourneyNodeRow(nodes: nodes),
          const SizedBox(height: AppTheme.spacingL),
          PixelProgressBar(
            progress: goal.progress,
            height: 10,
            blockCount: 16,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceDeep,
          ),
        ],
      ),
    );
  }
}

class _MiniJourneyStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniJourneyStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        '$label · $value',
        style: AppTextStyle.caption.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JourneyNodeRow extends StatelessWidget {
  final List<JourneyNode> nodes;

  const _JourneyNodeRow({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < nodes.length; index++) ...[
          Expanded(child: _JourneyNodeView(node: nodes[index])),
          if (index < nodes.length - 1)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 18),
                height: 2,
                color: _connectorColor(
                  left: nodes[index].status,
                  right: nodes[index + 1].status,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Color _connectorColor({
    required JourneyNodeStatus left,
    required JourneyNodeStatus right,
  }) {
    if (left == JourneyNodeStatus.complete &&
        right != JourneyNodeStatus.locked) {
      return AppTheme.primary;
    }
    if (left == JourneyNodeStatus.complete) {
      return AppTheme.primary.withValues(alpha: 0.25);
    }
    return AppTheme.surfaceDeep;
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
        const SizedBox(height: 10),
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

class _BadgeCard extends StatelessWidget {
  final CollectibleBadge badge;
  final Color accent;

  const _BadgeCard({required this.badge, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: badge.unlocked ? AppTheme.surface : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: badge.unlocked ? AppTheme.neuSubtle : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badge.unlocked
                    ? accent.withValues(alpha: 0.18)
                    : AppTheme.surfaceDeep,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                badge.unlocked ? '已解锁' : '待解锁',
                style: AppTextStyle.caption.copyWith(
                  color: badge.unlocked ? accent : AppTheme.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? accent.withValues(alpha: 0.14)
                  : AppTheme.surfaceDeep,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Opacity(
                opacity: badge.unlocked ? 1 : 0.38,
                child: PixelIcon(
                  icon: badge.icon,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(badge.title, style: AppTextStyle.h3),
          const SizedBox(height: 8),
          Text(
            badge.subtitle,
            style: AppTextStyle.bodySmall.copyWith(
              color: badge.unlocked
                  ? AppTheme.textSecondary
                  : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
