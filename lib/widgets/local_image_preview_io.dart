import 'dart:io';
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
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackPreview(
            imagePath: imagePath,
            width: width,
            height: height,
            borderRadius: borderRadius,
          );
        },
      ),
    );

    if (onTap == null) {
      return preview;
    }

    return GestureDetector(onTap: onTap, child: preview);
  }
}

class _FallbackPreview extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double borderRadius;

  const _FallbackPreview({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(Icons.broken_image_outlined, color: AppTheme.textHint),
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
  }
}
