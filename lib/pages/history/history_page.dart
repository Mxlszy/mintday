import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/checkin_heatmap.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/github_heatmap.dart';
import '../check_in/check_in_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final TextEditingController _searchController;
  String _keyword = '';
  final Set<String> _selectedGoalIds = <String>{};
  final Set<CheckInMode> _selectedModes = <CheckInMode>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleGoal(String goalId) {
    setState(() {
      if (_selectedGoalIds.contains(goalId)) {
        _selectedGoalIds.remove(goalId);
      } else {
        _selectedGoalIds.add(goalId);
      }
    });
  }

  void _toggleMode(CheckInMode mode) {
    setState(() {
      if (_selectedModes.contains(mode)) {
        _selectedModes.remove(mode);
      } else {
        _selectedModes.add(mode);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _keyword = '';
      _selectedGoalIds.clear();
      _selectedModes.clear();
      _searchController.clear();
    });
  }

  List<CheckIn> _visibleCheckIns(CheckInProvider provider) {
    var result = provider.filterByGoalIds(_selectedGoalIds.toList());

    if (_keyword.trim().isNotEmpty) {
      final matchedIds = provider
          .searchCheckIns(_keyword)
          .map((item) => item.id)
          .toSet();
      result = result.where((item) => matchedIds.contains(item.id)).toList();
    }

    if (_selectedModes.isNotEmpty) {
      result = result
          .where((item) => _selectedModes.contains(item.mode))
          .toList();
    }

    return result;
  }

  List<Goal> _availableGoals(List<Goal> goals, List<CheckIn> checkIns) {
    final goalIds = checkIns.map((item) => item.goalId).toSet();
    return goals.where((goal) => goalIds.contains(goal.id)).toList();
  }

  static Map<String, List<CheckIn>> _groupByDate(List<CheckIn> checkIns) {
    final result = <String, List<CheckIn>>{};
    for (final checkIn in checkIns) {
      result.putIfAbsent(checkIn.dateString, () => []).add(checkIn);
    }
    return result;
  }

  static Map<String, int> _countByDate(List<CheckIn> checkIns) {
    final result = <String, int>{};
    for (final checkIn in checkIns) {
      if (checkIn.status == CheckInStatus.skipped) continue;
      result[checkIn.dateString] = (result[checkIn.dateString] ?? 0) + 1;
    }
    return result;
  }

  static Map<String, CheckInStatus> _dateStatusMap(List<CheckIn> checkIns) {
    final grouped = _groupByDate(checkIns);
    final result = <String, CheckInStatus>{};

    for (final entry in grouped.entries) {
      final statuses = entry.value.map((item) => item.status).toSet();
      if (statuses.contains(CheckInStatus.done)) {
        result[entry.key] = CheckInStatus.done;
      } else if (statuses.contains(CheckInStatus.partial)) {
        result[entry.key] = CheckInStatus.partial;
      } else {
        result[entry.key] = CheckInStatus.skipped;
      }
    }

    return result;
  }

  bool get _hasActiveFilters =>
      _keyword.trim().isNotEmpty ||
      _selectedGoalIds.isNotEmpty ||
      _selectedModes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.showAppBar ? AppBar(title: const Text('历史卷轴')) : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Consumer2<CheckInProvider, GoalProvider>(
          builder: (context, checkInProvider, goalProvider, _) {
            if (checkInProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final allCheckIns = checkInProvider.checkIns;
            final visibleCheckIns = _visibleCheckIns(checkInProvider);
            final grouped = _groupByDate(visibleCheckIns);
            final sortedKeys = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));
            final availableGoals = _availableGoals(
              goalProvider.goals,
              allCheckIns,
            );
            final withReflection = visibleCheckIns.where(_hasReflection).length;
            final withImages = visibleCheckIns
                .where((checkIn) => checkIn.imagePaths.isNotEmpty)
                .length;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
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
                        Text('成长卷轴', style: AppTextStyle.h1),
                        const SizedBox(height: 10),
                        Text(
                          '按日期回看你的推进、情绪和留下的证据。',
                          style: AppTextStyle.bodySmall,
                        ),
                        if (allCheckIns.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingL),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _keyword = value),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: '搜索打卡内容',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          _HistoryFilters(
                            goals: availableGoals,
                            selectedGoalIds: _selectedGoalIds,
                            selectedModes: _selectedModes,
                            resultCount: visibleCheckIns.length,
                            hasActiveFilters: _hasActiveFilters,
                            onGoalTap: _toggleGoal,
                            onModeTap: _toggleMode,
                            onClear: _clearFilters,
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          _HistorySummary(
                            totalRecords: visibleCheckIns.length,
                            activeDays: grouped.length,
                            reflections: withReflection,
                            evidenceCount: withImages,
                          ),
                          if (visibleCheckIns.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingL),
                            CheckInHeatmap(
                              dateStatusMap: _dateStatusMap(visibleCheckIns),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text('近 16 周轨迹', style: AppTextStyle.h3),
                            const SizedBox(height: AppTheme.spacingS),
                            GithubHeatmap(
                              countByDate: _countByDate(visibleCheckIns),
                              weeksToShow: 16,
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (visibleCheckIns.isEmpty)
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
                        title: allCheckIns.isEmpty ? '还没有成长记录' : '没有找到匹配记录',
                        subtitle: allCheckIns.isEmpty
                            ? '完成一次打卡后，这里会按日期为你整理所有进展。'
                            : '试试更换关键词或筛选条件，看看别的成长片段。',
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
                        final dateKey = sortedKeys[index];
                        final date = DateTime.parse(dateKey);
                        final dayCheckIns = grouped[dateKey]!;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingL,
                          ),
                          child: _ScrollSection(
                            date: date,
                            checkIns: dayCheckIns,
                            goalProvider: goalProvider,
                          ),
                        );
                      }, childCount: sortedKeys.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _hasReflection(CheckIn checkIn) {
    return (checkIn.note?.isNotEmpty ?? false) ||
        (checkIn.reflectionProgress?.isNotEmpty ?? false) ||
        (checkIn.reflectionNext?.isNotEmpty ?? false) ||
        (checkIn.reflectionBlocker?.isNotEmpty ?? false);
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.goals,
    required this.selectedGoalIds,
    required this.selectedModes,
    required this.resultCount,
    required this.hasActiveFilters,
    required this.onGoalTap,
    required this.onModeTap,
    required this.onClear,
  });

  final List<Goal> goals;
  final Set<String> selectedGoalIds;
  final Set<CheckInMode> selectedModes;
  final int resultCount;
  final bool hasActiveFilters;
  final ValueChanged<String> onGoalTap;
  final ValueChanged<CheckInMode> onModeTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
            children: [
              Text('筛选记录', style: AppTextStyle.h3),
              const Spacer(),
              Text(
                '共 $resultCount 条',
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: AppTheme.spacingS),
                TextButton(onPressed: onClear, child: const Text('清空')),
              ],
            ],
          ),
          if (goals.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text('目标', style: AppTextStyle.label),
            const SizedBox(height: AppTheme.spacingS),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: goals.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppTheme.spacingS),
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final isSelected = selectedGoalIds.contains(goal.id);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(goal.title),
                    onSelected: (_) => onGoalTap(goal.id),
                    showCheckmark: false,
                    labelStyle: AppTextStyle.caption.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppTheme.surfaceVariant,
                    selectedColor: AppTheme.primary,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),
          Text('模式', style: AppTextStyle.label),
          const SizedBox(height: AppTheme.spacingS),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CheckInMode.values.map((mode) {
                final isSelected = selectedModes.contains(mode);
                return Padding(
                  padding: EdgeInsets.only(
                    right: mode == CheckInMode.values.last
                        ? 0
                        : AppTheme.spacingS,
                  ),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Text(_modeLabel(mode)),
                    onSelected: (_) => onModeTap(mode),
                    labelStyle: AppTextStyle.caption.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppTheme.surfaceVariant,
                    selectedColor: AppTheme.primary,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _modeLabel(CheckInMode mode) {
    return switch (mode) {
      CheckInMode.quick => '快速',
      CheckInMode.reflection => '反思',
    };
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.totalRecords,
    required this.activeDays,
    required this.reflections,
    required this.evidenceCount,
  });

  final int totalRecords;
  final int activeDays;
  final int reflections;
  final int evidenceCount;

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
            child: _SummaryItem(label: '记录总数', value: '$totalRecords'),
          ),
          Expanded(
            child: _SummaryItem(label: '活跃天数', value: '$activeDays'),
          ),
          Expanded(
            child: _SummaryItem(label: '带反思', value: '$reflections'),
          ),
          Expanded(
            child: _SummaryItem(label: '带图片', value: '$evidenceCount'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyle.h3),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyle.caption),
      ],
    );
  }
}

class _ScrollSection extends StatelessWidget {
  const _ScrollSection({
    required this.date,
    required this.checkIns,
    required this.goalProvider,
  });

  final DateTime date;
  final List<CheckIn> checkIns;
  final GoalProvider goalProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.surface,
            AppTheme.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 36,
            bottom: 10,
            child: Container(width: 2, color: AppTheme.surfaceDeep),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppUtils.friendlyDate(date),
                          style: AppTextStyle.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.year} / ${date.month.toString().padLeft(2, '0')} / ${date.day.toString().padLeft(2, '0')}',
                          style: AppTextStyle.caption,
                        ),
                      ],
                    ),
                  ),
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
                      '收录 ${checkIns.length}',
                      style: AppTextStyle.caption.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Column(
                  children: checkIns.map((checkIn) {
                    final goal = goalProvider.getGoalById(checkIn.goalId);
                    final goalTitle = goal?.title ?? '未命名目标';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: _HistoryEntryCard(
                        checkIn: checkIn,
                        goal: goal,
                        goalTitle: goalTitle,
                        onTap: () {
                          Navigator.of(context).push(
                            sharedAxisRoute(
                              CheckInDetailPage(
                                checkIn: checkIn,
                                goalTitle: goalTitle,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.checkIn,
    required this.goal,
    required this.goalTitle,
    required this.onTap,
  });

  final CheckIn checkIn;
  final Goal? goal;
  final String goalTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = _buildSummary(checkIn, goalTitle: goalTitle);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goalTitle,
                    style: AppTextStyle.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                    checkIn.moodEmoji,
                    style: AppTextStyle.body.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [
                _EntryTag(label: _modeLabel(checkIn.mode), emphasis: true),
                _EntryTag(label: _statusLabel(checkIn.status)),
                if (checkIn.duration != null)
                  _EntryTag(label: AppUtils.formatDuration(checkIn.duration!)),
                if (checkIn.imagePaths.isNotEmpty)
                  _EntryTag(label: '${checkIn.imagePaths.length} 张图片'),
                if (goal != null) _CategoryIconTag(category: goal!.category),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              Text(
                summary,
                style: AppTextStyle.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _normalizeSummaryLine(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _softCap(String value, int maxChars) {
    if (value.length <= maxChars) return value;
    return '${value.substring(0, maxChars)}...';
  }

  static String? _buildSummary(CheckIn checkIn, {required String goalTitle}) {
    final titleKey = _normalizeSummaryLine(goalTitle);

    if (checkIn.note != null && checkIn.note!.trim().isNotEmpty) {
      final note = _normalizeSummaryLine(checkIn.note!);
      if (note.isNotEmpty && note != titleKey) {
        return _softCap(note, 240);
      }
    }
    if (checkIn.reflectionProgress != null &&
        checkIn.reflectionProgress!.trim().isNotEmpty) {
      final body = _normalizeSummaryLine(checkIn.reflectionProgress!);
      if (body.isNotEmpty) {
        return _softCap('推进：$body', 240);
      }
    }
    if (checkIn.reflectionNext != null &&
        checkIn.reflectionNext!.trim().isNotEmpty) {
      final body = _normalizeSummaryLine(checkIn.reflectionNext!);
      if (body.isNotEmpty) {
        return _softCap('下一步：$body', 240);
      }
    }
    if (checkIn.reflectionBlocker != null &&
        checkIn.reflectionBlocker!.trim().isNotEmpty) {
      final body = _normalizeSummaryLine(checkIn.reflectionBlocker!);
      if (body.isNotEmpty) {
        return _softCap('阻碍：$body', 240);
      }
    }
    if (checkIn.imagePaths.isNotEmpty) {
      return '留下了 ${checkIn.imagePaths.length} 张图片作为证据。';
    }
    return null;
  }

  static String _modeLabel(CheckInMode mode) {
    return switch (mode) {
      CheckInMode.quick => '快速',
      CheckInMode.reflection => '反思',
    };
  }

  static String _statusLabel(CheckInStatus status) {
    return switch (status) {
      CheckInStatus.done => '完成',
      CheckInStatus.partial => '部分完成',
      CheckInStatus.skipped => '跳过',
    };
  }
}

class _CategoryIconTag extends StatelessWidget {
  const _CategoryIconTag({required this.category});

  final GoalCategory category;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _categoryLabel(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: PixelIcon(
          icon: PixelIcons.forCategory(category.value),
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  static String _categoryLabel(GoalCategory category) {
    return switch (category) {
      GoalCategory.habit => '习惯养成',
      GoalCategory.project => '项目计划',
      GoalCategory.study => '学习提升',
      GoalCategory.health => '健康运动',
      GoalCategory.wish => '愿望清单',
      GoalCategory.custom => '自定义',
    };
  }
}

class _EntryTag extends StatelessWidget {
  const _EntryTag({required this.label, this.emphasis = false});

  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasis ? AppTheme.primaryMuted : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: emphasis ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
