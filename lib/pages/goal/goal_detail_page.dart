import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/journey_insights.dart';
import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../models/milestone_progress.dart';
import '../../models/nft_asset.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/nft_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/goal_twelve_week_heatmap.dart';
import '../../widgets/pixel_progress_bar.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/todo_checklist.dart';
import '../../widgets/nft/nft_collectible_card.dart';
import '../check_in/check_in_detail_page.dart';
import '../check_in/check_in_page.dart';
import '../wallet/nft_detail_page.dart';
import 'edit_goal_page.dart';

class GoalDetailPage extends StatelessWidget {
  final String goalId;

  const GoalDetailPage({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return Consumer4<GoalProvider, CheckInProvider, FocusProvider, NftProvider>(
      builder:
          (
            context,
            goalProvider,
            checkInProvider,
            focusProvider,
            nftProvider,
            _,
          ) {
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
            final focusMinutes = focusProvider.getTotalFocusMinutesForGoal(
              goalId,
            );
            final investedAmount = context
                .watch<TransactionProvider>()
                .getGoalRelatedExpense(goalId);
            final heatmapCounts = GoalDetailPage._heatmapCountsForGoal(
              checkIns,
            );

            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                title: Text(goal.title),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenu(context, value, goal),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('标记完成'),
                      ),
                      const PopupMenuItem(value: 'archive', child: Text('归档')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          '删除',
                          style: AppTextStyle.body.copyWith(
                            color: AppTheme.error,
                          ),
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
                    investedAmount: investedAmount,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _FocusSummaryStrip(focusMinutes: focusMinutes),
                  const SizedBox(height: AppTheme.spacingL),
                  _JourneySection(
                    goal: goal,
                    streak: streak,
                    totalCheckIns: checkIns.length,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _MilestoneMintSection(goal: goal),
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
                  const SizedBox(height: AppTheme.spacingL),
                  _TodoPlannerSection(goalId: goal.id),
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PixelIcon(
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
                              fadeSlideRoute(CheckInPage(goalId: goal.id)),
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
      case 'edit':
        Navigator.of(context).push(fadeSlideRoute(EditGoalPage(goal: goal)));
        break;
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
  final double investedAmount;

  const _HeroCard({
    required this.goal,
    required this.streak,
    required this.totalCheckIns,
    required this.investedAmount,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                const SizedBox(height: 8),
                _MetaLine(
                  icon: PixelIcons.diamond,
                  text:
                      '已投入 ${AppUtils.formatCurrency(investedAmount, absolute: true)}',
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

class _FocusSummaryStrip extends StatelessWidget {
  final int focusMinutes;

  const _FocusSummaryStrip({required this.focusMinutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          PixelIcon(icon: PixelIcons.bolt, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '累计专注时长: ${AppUtils.formatDuration(focusMinutes)}',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
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

class _MilestoneMintSection extends StatelessWidget {
  final Goal goal;

  const _MilestoneMintSection({required this.goal});

  @override
  Widget build(BuildContext context) {
    final nftProvider = context.watch<NftProvider>();

    return FutureBuilder<List<MilestoneProgress>>(
      future: DatabaseService.getMilestonesByGoal(goal.id),
      builder: (context, snapshot) {
        final milestones =
            (snapshot.data ?? const <MilestoneProgress>[])
                .where((milestone) => milestone.isUnlocked)
                .toList()
              ..sort((a, b) => b.targetValue.compareTo(a.targetValue));

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
              Row(
                children: [
                  Text('里程碑纪念卡', style: AppTextStyle.h3),
                  const Spacer(),
                  if (goal.isMintable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMuted,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        '可铸造',
                        style: AppTextStyle.caption.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                goal.reward ?? '解锁里程碑后，可以把这段进展铸造成像素风 NFT 纪念卡。',
                style: AppTextStyle.bodySmall,
              ),
              const SizedBox(height: AppTheme.spacingL),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  milestones.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (milestones.isEmpty)
                _MilestoneEmptyCard(goal: goal)
              else
                ...milestones.map((milestone) {
                  final asset = _findAssetForMilestone(nftProvider, milestone);
                  final status =
                      asset?.status ??
                      (milestone.isMinted
                          ? NftStatus.minted
                          : NftStatus.pending);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
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
                                    Text(
                                      milestone.title,
                                      style: AppTextStyle.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      milestone.description ??
                                          '来自目标「${goal.title}」的里程碑纪念卡',
                                      style: AppTextStyle.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              NftStatusChip(status: status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '进度 ${milestone.currentValue}/${milestone.targetValue}',
                                  style: AppTextStyle.caption,
                                ),
                              ),
                              if (milestone.unlockedAt != null)
                                Text(
                                  '解锁于 ${AppUtils.friendlyDate(milestone.unlockedAt!)}',
                                  style: AppTextStyle.caption,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _openOrCreateNft(context, milestone, asset),
                              child: Text(
                                asset == null
                                    ? '生成纪念卡'
                                    : (asset.status == NftStatus.minted
                                          ? '查看 NFT'
                                          : '继续铸造'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  NftAsset? _findAssetForMilestone(
    NftProvider provider,
    MilestoneProgress milestone,
  ) {
    final expectedCategory = _categoryForMilestone(milestone);
    try {
      return provider.getMyNfts().firstWhere(
        (asset) =>
            asset.sourceId == milestone.id &&
            asset.category == expectedCategory,
      );
    } catch (_) {
      return null;
    }
  }

  NftCategory _categoryForMilestone(MilestoneProgress milestone) {
    return milestone.type == MilestoneType.streak
        ? NftCategory.streak
        : NftCategory.milestone;
  }

  Future<void> _openOrCreateNft(
    BuildContext context,
    MilestoneProgress milestone,
    NftAsset? existingAsset,
  ) async {
    final asset =
        existingAsset ??
        await context.read<NftProvider>().generateNftCard(
          milestone.title,
          milestone.description?.isNotEmpty == true
              ? '${milestone.description!} · 来自目标「${goal.title}」'
              : '来自目标「${goal.title}」的里程碑纪念卡',
          _categoryForMilestone(milestone),
          milestone.id,
        );

    if (!context.mounted) return;
    if (asset == null) {
      AppUtils.showSnackBar(context, '生成纪念卡失败，请稍后重试', isError: true);
      return;
    }

    Navigator.of(
      context,
    ).push(sharedAxisRoute(NftDetailPage(assetId: asset.id)));
  }
}

class _MilestoneEmptyCard extends StatelessWidget {
  final Goal goal;

  const _MilestoneEmptyCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 124,
            child: NftCollectibleCard(
              title: '等待点亮',
              description: '解锁新的里程碑后，这里会出现可铸造的纪念卡入口。',
              category: goal.isMintable
                  ? NftCategory.milestone
                  : NftCategory.custom,
              createdAt: DateTime.now(),
              compact: true,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              '继续推进「${goal.title}」，完成阶段目标后就能把这段旅程铸造成 NFT 收藏卡。',
              style: AppTextStyle.bodySmall,
            ),
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

class _TodoPlannerSection extends StatefulWidget {
  const _TodoPlannerSection({required this.goalId});

  final String goalId;

  @override
  State<_TodoPlannerSection> createState() => _TodoPlannerSectionState();
}

class _TodoPlannerSectionState extends State<_TodoPlannerSection> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(DateTime.now());
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _normalize(_selectedDate.add(Duration(days: delta)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isToday = AppUtils.isSameDay(_selectedDate, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今日计划', style: AppTextStyle.h3),
                  const SizedBox(height: 6),
                  Text('把目标拆成今天能完成的小动作。', style: AppTextStyle.bodySmall),
                ],
              ),
            ),
            _DateArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => _changeDate(-1),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                AppUtils.fullFriendlyDate(_selectedDate),
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            _DateArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: isToday ? null : () => _changeDate(1),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          child: TodoChecklist(
            key: ValueKey(
              '${widget.goalId}-${_selectedDate.toIso8601String()}',
            ),
            goalId: widget.goalId,
            date: _selectedDate,
          ),
        ),
      ],
    );
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _DateArrowButton extends StatelessWidget {
  const _DateArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap == null ? AppTheme.surfaceVariant : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppTheme.textHint : AppTheme.textSecondary,
        ),
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
                index < goal.completedSteps.length &&
                goal.completedSteps[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: () => provider.toggleStep(goal.id, index),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primaryMuted
                        : AppTheme.surfaceVariant,
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
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
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

  const _CheckInHistory({required this.goal, required this.checkIns});

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
                    sharedAxisRoute(
                      CheckInDetailPage(
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
    if (checkIn.reflectionNext != null && checkIn.reflectionNext!.isNotEmpty) {
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

  const _MetaLine({required this.icon, required this.text});

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
      JourneyNodeStatus.complete => (
        AppTheme.accentLight,
        AppTheme.accentStrong,
      ),
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
            child: PixelIcon(icon: node.icon, size: 16, color: foreground),
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
