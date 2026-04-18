import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/user_profile_model.dart';
import '../core/utils.dart';
import '../models/avatar_config.dart';
import 'avatar/pixel_avatar_painter.dart';

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({
    super.key,
    required this.profile,
    required this.dateLabel,
    this.headlineGreeting,
    this.onNotificationTap,
    this.onAvatarTap,
    this.level = 1,
    this.xpCurrent = 0,
    this.xpMax = 100,
  });

  final UserProfileModel profile;
  final String dateLabel;
  final String? headlineGreeting;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final int level;
  final int xpCurrent;
  final int xpMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeroPanelCard(
          profile: profile,
          onNotificationTap: onNotificationTap,
          onAvatarTap: onAvatarTap,
          level: level,
          xpCurrent: xpCurrent,
          xpMax: xpMax,
        ),
        const SizedBox(height: 10),
        _BottomRow(dateLabel: dateLabel),
      ],
    );
  }
}

class _HeroPanelCard extends StatelessWidget {
  const _HeroPanelCard({
    required this.profile,
    this.onNotificationTap,
    this.onAvatarTap,
    required this.level,
    required this.xpCurrent,
    required this.xpMax,
  });

  final UserProfileModel profile;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final int level;
  final int xpCurrent;
  final int xpMax;

  @override
  Widget build(BuildContext context) {
    final palette = _HeaderPalette.current();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: palette.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.panelBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.panelShadow,
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _AvatarFrame(
            assetPath: profile.avatarAssetPath,
            avatarConfig: profile.avatarConfig,
            width: 80,
            height: 100,
            level: level,
            onTap: onAvatarTap,
            palette: palette,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatBlock(
              nickname: profile.nickname,
              level: level,
              xpCurrent: xpCurrent,
              xpMax: xpMax,
              palette: palette,
            ),
          ),
          if (!kIsWeb && onNotificationTap != null) ...<Widget>[
            const SizedBox(width: 10),
            _NotifButton(onTap: onNotificationTap!, palette: palette),
          ],
        ],
      ),
    );
  }
}

class _AvatarFrame extends StatelessWidget {
  const _AvatarFrame({
    required this.assetPath,
    required this.avatarConfig,
    required this.width,
    required this.height,
    required this.level,
    required this.palette,
    this.onTap,
  });

  final String? assetPath;
  final AvatarConfig? avatarConfig;
  final double width;
  final double height;
  final int level;
  final VoidCallback? onTap;
  final _HeaderPalette palette;

  Widget _buildAvatar() {
    final fallback = Center(
      child: PixelAvatar(
        config: avatarConfig ?? AvatarConfig.defaultConfig,
        size: 82,
      ),
    );

    if (avatarConfig != null) {
      return fallback;
    }

    if (assetPath == null) {
      return fallback;
    }

    return Image.asset(
      assetPath!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = SizedBox(
      width: width + 8,
      height: height + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: palette.avatarBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.avatarBorder, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: _buildAvatar(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: palette.badgeBg,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: palette.panelBg, width: 1.5),
              ),
              child: Text(
                'Lv.$level',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: palette.badgeFg,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return frame;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: frame,
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.nickname,
    required this.level,
    required this.xpCurrent,
    required this.xpMax,
    required this.palette,
  });

  final String nickname;
  final int level;
  final int xpCurrent;
  final int xpMax;
  final _HeaderPalette palette;

  bool get _isMax => xpMax > 0 && xpCurrent >= xpMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textSub,
            letterSpacing: 0.1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              'Lv.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.textSub,
                height: 1.15,
              ),
            ),
            Text(
              '$level',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: palette.textMain,
                letterSpacing: -0.8,
                height: 1.05,
                shadows: <Shadow>[
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
            if (_isMax) ...<Widget>[
              const SizedBox(width: 6),
              Text(
                'MAX',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: palette.textHint,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 1, color: palette.divider),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'EXP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.textSub,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '$xpCurrent / $xpMax',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: palette.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _PixelXpBar(
          current: xpCurrent,
          max: xpMax,
          trackColor: palette.xpTrack,
          trackBorderColor: palette.xpTrackBorder,
          fillColor: palette.xpFill,
          highlightColor: palette.xpHighlight,
        ),
      ],
    );
  }
}

class _PixelXpBar extends StatelessWidget {
  const _PixelXpBar({
    required this.current,
    required this.max,
    required this.trackColor,
    required this.trackBorderColor,
    required this.fillColor,
    required this.highlightColor,
  });

  final int current;
  final int max;
  final Color trackColor;
  final Color trackBorderColor;
  final Color fillColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return CustomPaint(
      painter: _XpBarPainter(
        progress: progress,
        trackColor: trackColor,
        trackBorderColor: trackBorderColor,
        fillColor: fillColor,
        highlightColor: highlightColor,
      ),
      child: const SizedBox(height: 10, width: double.infinity),
    );
  }
}

class _XpBarPainter extends CustomPainter {
  const _XpBarPainter({
    required this.progress,
    required this.trackColor,
    required this.trackBorderColor,
    required this.fillColor,
    required this.highlightColor,
  });

  final double progress;
  final Color trackColor;
  final Color trackBorderColor;
  final Color fillColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(2);

    final outerRect = RRect.fromLTRBR(
      0.5,
      0.5,
      size.width - 0.5,
      size.height - 0.5,
      radius,
    );

    canvas.drawRRect(outerRect, Paint()..color = trackColor);

    if (progress > 0.005) {
      final fillWidth = (size.width - 1.0) * progress;
      canvas.drawRRect(
        RRect.fromLTRBR(0.5, 0.5, 0.5 + fillWidth, size.height - 0.5, radius),
        Paint()..color = fillColor,
      );

      if (fillWidth > 4) {
        canvas.drawRect(
          Rect.fromLTWH(1.5, 1.5, fillWidth - 2, (size.height - 3) * 0.28),
          Paint()..color = highlightColor,
        );
      }
    }

    canvas.drawRRect(
      outerRect,
      Paint()
        ..color = trackBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _XpBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.trackBorderColor != trackBorderColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.highlightColor != highlightColor;
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final palette = _HeaderPalette.current();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: palette.dateTagBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.dateTagBorder),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSub,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppUtils.randomEncouragement(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textHint,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotifButton extends StatelessWidget {
  const _NotifButton({required this.onTap, required this.palette});

  final VoidCallback onTap;
  final _HeaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.avatarBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.avatarBorder),
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: 18,
            color: palette.textSub,
          ),
        ),
      ),
    );
  }
}

class _HeaderPalette {
  const _HeaderPalette({
    required this.panelBg,
    required this.panelBorder,
    required this.panelShadow,
    required this.avatarBg,
    required this.avatarBorder,
    required this.divider,
    required this.xpTrack,
    required this.xpTrackBorder,
    required this.xpFill,
    required this.xpHighlight,
    required this.textMain,
    required this.textSub,
    required this.textHint,
    required this.badgeBg,
    required this.badgeFg,
    required this.dateTagBg,
    required this.dateTagBorder,
  });

  final Color panelBg;
  final Color panelBorder;
  final Color panelShadow;
  final Color avatarBg;
  final Color avatarBorder;
  final Color divider;
  final Color xpTrack;
  final Color xpTrackBorder;
  final Color xpFill;
  final Color xpHighlight;
  final Color textMain;
  final Color textSub;
  final Color textHint;
  final Color badgeBg;
  final Color badgeFg;
  final Color dateTagBg;
  final Color dateTagBorder;

  factory _HeaderPalette.current() {
    final isDark = AppTheme.isDarkMode;
    return _HeaderPalette(
      panelBg: AppTheme.surface,
      panelBorder: AppTheme.border,
      panelShadow: AppTheme.shadowDark.withValues(alpha: isDark ? 0.28 : 0.06),
      avatarBg: AppTheme.surfaceVariant,
      avatarBorder: AppTheme.border,
      divider: AppTheme.divider,
      xpTrack: AppTheme.surfaceDeep,
      xpTrackBorder: AppTheme.border,
      xpFill: isDark ? AppTheme.accent : AppTheme.textPrimary,
      xpHighlight: Colors.white.withValues(alpha: isDark ? 0.24 : 0.16),
      textMain: AppTheme.textPrimary,
      textSub: AppTheme.textSecondary,
      textHint: AppTheme.textHint,
      badgeBg: isDark ? AppTheme.accentStrong : AppTheme.textPrimary,
      badgeFg: Colors.white,
      dateTagBg: AppTheme.surfaceVariant,
      dateTagBorder: AppTheme.border,
    );
  }
}
