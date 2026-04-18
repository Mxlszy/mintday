import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/avatar_config.dart';
import 'avatar/pixel_avatar_painter.dart';

class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.label,
    this.avatarAssetPath,
    this.avatarConfig,
    this.size = 52,
    this.borderRadius = 18,
  });

  final String label;
  final String? avatarAssetPath;
  final AvatarConfig? avatarConfig;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallbackColor =
        _avatarPalette[label.hashCode.abs() % _avatarPalette.length];
    final child = _buildChild(fallbackColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor.withValues(
          alpha: AppTheme.isDarkMode ? 0.28 : 0.14,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildChild(Color fallbackColor) {
    if (avatarConfig != null) {
      return Center(
        child: PixelAvatar(config: avatarConfig!, size: size * 0.78),
      );
    }

    if (avatarAssetPath != null && avatarAssetPath!.isNotEmpty) {
      final source = avatarAssetPath!;
      if (source.startsWith('http')) {
        return Image.network(
          source,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitial(fallbackColor),
        );
      }

      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitial(fallbackColor),
      );
    }

    return _buildInitial(fallbackColor);
  }

  Widget _buildInitial(Color fallbackColor) {
    final initial = label.trim().isEmpty ? 'M' : label.trim().substring(0, 1);
    return Center(
      child: Text(
        initial,
        style: AppTextStyle.body.copyWith(
          color: fallbackColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  List<Color> get _avatarPalette => [
    AppTheme.primary,
    AppTheme.bonusBlue,
    AppTheme.bonusMint,
    AppTheme.accentStrong,
    AppTheme.error,
  ];
}
