import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';
import '../models/goal.dart';
import '../models/todo_item.dart';
import '../providers/goal_provider.dart';
import '../providers/todo_provider.dart';

class TodayTodoOverview extends StatefulWidget {
  const TodayTodoOverview({super.key});

  @override
  State<TodayTodoOverview> createState() => _TodayTodoOverviewState();
}

class _TodayTodoOverviewState extends State<TodayTodoOverview> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TodoProvider>().loadTodosForDate(DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalProvider, TodoProvider>(
      builder: (context, goalProvider, todoProvider, _) {
        final activeGoals = goalProvider.activeGoals;
        final goalMap = <String, Goal>{
          for (final goal in activeGoals) goal.id: goal,
        };
        final todayTodos = todoProvider
            .getTodosForDate(DateTime.now())
            .where((todo) => goalMap.containsKey(todo.goalId))
            .toList();

        final completedCount = todayTodos
            .where((todo) => todo.isCompleted)
            .length;
        final incompleteCount = todayTodos.length - completedCount;
        final allDone = todayTodos.isNotEmpty && incompleteCount == 0;
        final grouped = <Goal, List<TodoItem>>{};

        for (final goal in activeGoals) {
          final items = todayTodos
              .where((todo) => todo.goalId == goal.id)
              .toList();
          if (items.isNotEmpty) {
            grouped[goal] = items;
          }
        }
        final groupedEntries = grouped.entries.toList();

        final summaryText = switch (todayTodos.length) {
          0 => '今天还没有安排待办，给重要目标列个小清单吧。',
          _ when allDone => '今日待办全部完成，节奏很稳。',
          _ => '今日还有 $incompleteCount 项待完成',
        };

        return NeuContainer(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          borderRadius: AppTheme.radiusXL,
          isSubtle: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('今日待办概览', style: AppTextStyle.h3),
                        const SizedBox(height: 6),
                        Text(summaryText, style: AppTextStyle.bodySmall),
                      ],
                    ),
                  ),
                  if (grouped.isNotEmpty)
                    IconButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              if (todayTodos.isEmpty)
                _EmptyOverviewState(isLoading: todoProvider.isLoadingToday)
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBadge(
                        icon: PixelIcons.check,
                        label: '$completedCount/${todayTodos.length} 已完成',
                        color: allDone ? AppTheme.bonusMint : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _SummaryBadge(
                        icon: PixelIcons.flag,
                        label: '涉及 ${grouped.length} 个目标',
                        color: AppTheme.accentStrong,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                _OverviewProgressBar(
                  progress: todayTodos.isEmpty
                      ? 0
                      : completedCount / todayTodos.length,
                  isCompleted: allDone,
                ),
                if (allDone) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  _CelebrationBanner(totalCount: todayTodos.length),
                ],
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 260),
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingM),
                    child: Column(
                      children: [
                        for (final entry in groupedEntries)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: identical(entry, groupedEntries.last)
                                  ? 0
                                  : AppTheme.spacingS,
                            ),
                            child: _GoalTodoGroup(
                              goal: entry.key,
                              todos: entry.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final PixelIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          PixelIcon(icon: icon, size: 14, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyle.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewProgressBar extends StatelessWidget {
  const _OverviewProgressBar({
    required this.progress,
    required this.isCompleted,
  });

  final double progress;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppTheme.bonusMint : AppTheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: AppTheme.surfaceDeep,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.68)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoalTodoGroup extends StatelessWidget {
  const _GoalTodoGroup({required this.goal, required this.todos});

  final Goal goal;
  final List<TodoItem> todos;

  @override
  Widget build(BuildContext context) {
    final progress = TodoProgress.fromItems(todos);
    final previewItems = todos.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: PixelIcon(
                    icon: PixelIcons.forCategory(goal.category.value),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                progress.label,
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          for (final item in previewItems)
            Padding(
              padding: EdgeInsets.only(
                top: identical(item, previewItems.first) ? 0 : 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? AppTheme.primary
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: item.isCompleted
                        ? const Center(
                            child: PixelIcon(
                              icon: PixelIcons.check,
                              size: 8,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      item.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: item.isCompleted
                            ? AppTheme.textSecondary.withValues(alpha: 0.6)
                            : AppTheme.textPrimary,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (todos.length > previewItems.length) ...[
            const SizedBox(height: 8),
            Text(
              '还有 ${todos.length - previewItems.length} 项待查看',
              style: AppTextStyle.caption.copyWith(
                color: AppTheme.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldAccent.withValues(
                    alpha: AppTheme.isDarkMode ? 0.28 : 0.18,
                  ),
                  AppTheme.bonusMint.withValues(
                    alpha: AppTheme.isDarkMode ? 0.22 : 0.16,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: AppTheme.goldAccent.withValues(alpha: 0.24),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -8,
                  right: 14,
                  child: Transform.rotate(
                    angle: pi / 12,
                    child: const PixelIcon(
                      icon: PixelIcons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  left: 8,
                  child: Transform.rotate(
                    angle: -pi / 10,
                    child: const PixelIcon(icon: PixelIcons.diamond, size: 14),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: PixelIcon(
                          icon: PixelIcons.trophy,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        '今天的 $totalCount 项待办都完成了，继续保持这个节奏。',
                        style: AppTextStyle.body.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyOverviewState extends StatelessWidget {
  const _EmptyOverviewState({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : PixelIcon(
                      icon: PixelIcons.calendar,
                      size: 18,
                      color: AppTheme.primary,
                    ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              isLoading ? '正在整理今天的待办...' : '还没有今日待办，去目标详情里补充一个可执行的小动作。',
              style: AppTextStyle.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
