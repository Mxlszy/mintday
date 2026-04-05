import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';

/// 像素风打卡成就分享卡（由 [Screenshot] 或离屏 capture 包裹）。
class PixelShareCard extends StatelessWidget {
  final String nickname;
  final int maxStreakDays;
  final int totalRecords;
  final int unlockedBadgeCount;
  final List<String> highlightLines;
  final String headline;
  final String footer;

  const PixelShareCard({
    super.key,
    required this.nickname,
    required this.maxStreakDays,
    required this.totalRecords,
    required this.unlockedBadgeCount,
    this.highlightLines = const [],
    this.headline = '打卡成就',
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: AppTheme.primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            offset: const Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: Text(
                  headline,
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppConstants.appName,
                style: AppTextStyle.caption.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            nickname,
            style: AppTextStyle.h2.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '正在用记录，把自己推向想成为的样子。',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _StatBlock(
                icon: PixelIcons.fire,
                label: '最长连续',
                value: maxStreakDays <= 0 ? '—' : '$maxStreakDays 天',
              ),
              const SizedBox(width: 12),
              _StatBlock(
                icon: PixelIcons.check,
                label: '累计记录',
                value: '$totalRecords 次',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBlock(
                icon: PixelIcons.medal,
                label: '图鉴徽章',
                value: '$unlockedBadgeCount 枚',
              ),
            ],
          ),
          if (highlightLines.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最近亮点',
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final line in highlightLines.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '▪ ',
                            style: AppTextStyle.caption.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: AppTextStyle.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              PixelIcon(
                icon: PixelIcons.star,
                size: 14,
                color: AppTheme.accentStrong,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  footer,
                  style: AppTextStyle.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final PixelIconData icon;
  final String label;
  final String value;

  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelIcon(icon: icon, size: 16, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyle.caption.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyle.h3.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
