import 'package:flutter/material.dart';
import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';

/// 当用户连续 5 次使用快速打卡后，在首页展示此引导卡片
class ReflectionGuideCard extends StatelessWidget {
  final VoidCallback onTryReflection;
  final VoidCallback onDismiss;

  const ReflectionGuideCard({
    super.key,
    required this.onTryReflection,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 14,
            isSubtle: true,
            child: PixelIcon(
              icon: PixelIcons.book,
              size: 22,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今天试试反思打卡？',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '记录推进、阻碍与明日计划，让成长更清晰',
                  style: AppTextStyle.caption,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    NeuButton(
                      onPressed: onTryReflection,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: AppTheme.primaryMuted,
                      child: Text(
                        '试一试',
                        style: AppTextStyle.caption.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Text(
                        '不用了',
                        style: AppTextStyle.caption.copyWith(
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
