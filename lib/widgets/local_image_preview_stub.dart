import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../core/theme/app_theme.dart';

class LocalImagePreview extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final VoidCallback? onTap;

  const LocalImagePreview({
    super.key,
    required this.imagePath,
    this.width = 96,
    this.height = 96,
    this.borderRadius = AppTheme.radiusM,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: AppTheme.textHint),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            path.basename(imagePath),
            style: AppTextStyle.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return preview;
    }

    return GestureDetector(
      onTap: onTap,
      child: preview,
    );
  }
}
