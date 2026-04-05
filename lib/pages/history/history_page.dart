import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/checkin_heatmap.dart';
import '../../widgets/github_heatmap.dart';
import '../check_in/check_in_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer2<CheckInProvider, GoalProvider>(
          builder: (context, checkInProvider, goalProvider, _) {
            if (checkInProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final grouped = checkInProvider.groupedByDate;
            final sortedKeys = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));
            final checkIns = checkInProvider.checkIns;
            final withReflection = checkIns.where(_hasReflection).length;
            final withImages =
                checkIns.where((checkIn) => checkIn.imagePaths.isNotEmpty).length;

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
                        const SizedBox(height: AppTheme.spacingL),
                        _HistorySummary(
                          totalRecords: checkIns.length,
                          activeDays: grouped.length,
                          reflections: withReflection,
                          evidenceCount: withImages,
                        ),
                        if (checkIns.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingL),
                          CheckInHeatmap(
                            dateStatusMap:
                                checkInProvider.dateStatusMap,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            '近 16 周轨迹',
                            style: AppTextStyle.h3,
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          GithubHeatmap(
                            countByDate:
                                checkInProvider.checkInCountByDate,
                            weeksToShow: 16,
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                        ],
                      ],
                    ),
                  ),
                ),
                if (checkIns.isEmpty)
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
                        title: AppConstants.emptyHistoryTitle,
                        subtitle: AppConstants.emptyHistorySubtitle,
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
                        },
                        childCount: sortedKeys.length,
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

  static bool _hasReflection(CheckIn checkIn) {
    return (checkIn.note?.isNotEmpty ?? false) ||
        (checkIn.reflectionProgress?.isNotEmpty ?? false) ||
        (checkIn.reflectionNext?.isNotEmpty ?? false) ||
        (checkIn.reflectionBlocker?.isNotEmpty ?? false);
  }
}

class _HistorySummary extends StatelessWidget {
  final int totalRecords;
  final int activeDays;
  final int reflections;
  final int evidenceCount;

  const _HistorySummary({
    required this.totalRecords,
    required this.activeDays,
    required this.reflections,
    required this.evidenceCount,
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
            child: _SummaryItem(label: '收录记录', value: '$totalRecords'),
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
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

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
  final DateTime date;
  final List<CheckIn> checkIns;
  final GoalProvider goalProvider;

  const _ScrollSection({
    required this.date,
    required this.checkIns,
    required this.goalProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
                    decoration: const BoxDecoration(
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
                            MaterialPageRoute(
                              builder: (_) => CheckInDetailPage(
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
  final CheckIn checkIn;
  final Goal? goal;
  final String goalTitle;
  final VoidCallback onTap;

  const _HistoryEntryCard({
    required this.checkIn,
    required this.goal,
    required this.goalTitle,
    required this.onTap,
  });

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                // 优先级：模式 > 状态 > 时长 > 图片数；分类仅图标，置底以免与正文混淆
                _EntryTag(label: checkIn.mode.label, emphasis: true),
                _EntryTag(label: checkIn.status.label),
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

  /// 折叠空白，避免 note / 反思字段里的换行在卡片上像「多出来的一行标签」。
  static String _normalizeSummaryLine(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 与 [Text.maxLines] 配合：超长时先在字符级截断，减少半字/异常折行。
  static String _softCap(String s, int maxChars) {
    if (s.length <= maxChars) return s;
    return '${s.substring(0, maxChars)}…';
  }

  String? _buildSummary(CheckIn checkIn, {required String goalTitle}) {
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
    if (checkIn.reflectionNext != null && checkIn.reflectionNext!.trim().isNotEmpty) {
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
}

/// 目标分类：仅像素图标 + Tooltip，避免与模式/状态文字胶囊混淆。
class _CategoryIconTag extends StatelessWidget {
  final GoalCategory category;

  const _CategoryIconTag({required this.category});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: category.label,
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
}

class _EntryTag extends StatelessWidget {
  final String label;
  final bool emphasis;

  const _EntryTag({required this.label, this.emphasis = false});

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
