import 'package:flutter/material.dart';
import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: AppTheme.radiusXL,
              child: PixelIcon(
                icon: PixelIcons.diamond,
                size: 42,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(title, style: AppTextStyle.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              subtitle,
              style: AppTextStyle.body.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton(
                onPressed: onAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PixelIcon(
                      icon: PixelIcons.plus,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(actionLabel!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
