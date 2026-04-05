import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';

/// 年度报告长图内容区（离屏渲染，无交互）。
class AnnualReportCanvas extends StatelessWidget {
  final int year;
  final String nickname;
  final int distinctDays;
  final int totalCheckIns;
  final Map<int, int> moodHistogram;
  final int achievementUnlocksInYear;

  const AnnualReportCanvas({
    super.key,
    required this.year,
    required this.nickname,
    required this.distinctDays,
    required this.totalCheckIns,
    required this.moodHistogram,
    required this.achievementUnlocksInYear,
  });

  int get _moodTotal {
    var s = 0;
    for (final v in moodHistogram.values) {
      s += v;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final moodTotal = _moodTotal;

    return Container(
      width: 360,
      color: AppTheme.background,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: Text(
              '$year 年度报告',
              style: AppTextStyle.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nickname,
            style: AppTextStyle.h2.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppConstants.appName} · 数据仅来自本机记录',
            style: AppTextStyle.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _BigMetric(
            label: '这一年有记录的天数',
            value: '$distinctDays',
            unit: '天',
            icon: PixelIcons.leaf,
          ),
          const SizedBox(height: 12),
          _BigMetric(
            label: '打卡总次数（含各目标）',
            value: '$totalCheckIns',
            unit: '次',
            icon: PixelIcons.check,
          ),
          const SizedBox(height: 12),
          _BigMetric(
            label: '这一年新解锁成就',
            value: '$achievementUnlocksInYear',
            unit: '枚',
            icon: PixelIcons.medal,
          ),
          const SizedBox(height: 24),
          Text(
            '心情分布（1–5 分）',
            style: AppTextStyle.label.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (moodTotal == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: Text(
                '这一年还没有带心情分的记录。',
                style: AppTextStyle.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: Column(
                children: [
                  for (var score = 1; score <= 5; score++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MoodBarRow(
                        score: score,
                        count: moodHistogram[score] ?? 0,
                        total: moodTotal,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              PixelIcon(
                icon: PixelIcons.chart,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '导出日期 ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: AppTextStyle.caption.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final PixelIconData icon;

  const _BigMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: Center(
              child: PixelIcon(icon: icon, size: 20, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyle.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: AppTextStyle.h2.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: AppTextStyle.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _MoodBarRow extends StatelessWidget {
  final int score;
  final int count;
  final int total;

  const _MoodBarRow({
    required this.score,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            '$score 分',
            style: AppTextStyle.caption.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth * ratio.clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 16,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDeep,
                      border:
                          Border.all(color: AppTheme.textPrimary, width: 1),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      height: 16,
                      width: barW,
                      color: AppTheme.accentStrong,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTextStyle.caption.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
