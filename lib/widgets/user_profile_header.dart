import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/user_profile_model.dart';
import '../core/utils.dart';

/// 主控台顶部：像素头像 + 昵称/欢迎语 + 通知。
class UserProfileHeader extends StatelessWidget {
  final UserProfileModel profile;
  final String dateLabel;

  /// 若传入则覆盖 [UserProfileModel.welcomeMessage]（例如首页动态问候）。
  final String? headlineGreeting;
  final VoidCallback? onNotificationTap;

  const UserProfileHeader({
    super.key,
    required this.profile,
    required this.dateLabel,
    this.headlineGreeting,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PixelAvatarFrame(
              assetPath: profile.avatarAssetPath,
              size: 56,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nickname,
                    style: AppTextStyle.h2.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    headlineGreeting ?? profile.welcomeMessage,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!kIsWeb) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onNotificationTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowDark.withValues(alpha: 0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          child: Text(
            dateLabel,
            style: AppTextStyle.caption.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppUtils.randomEncouragement(),
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 方形圆角头像 + 像素化阶梯边框；无资源时绘制内置像素角色。
class _PixelAvatarFrame extends StatelessWidget {
  final String? assetPath;
  final double size;

  const _PixelAvatarFrame({
    required this.assetPath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final inner = size - 10;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelatedBorderPainter(
          cornerRadius: 10,
          step: 3,
          outerColor: AppTheme.primary,
          midColor: AppTheme.surface,
          innerColor: AppTheme.accentStrong,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: inner,
              height: inner,
              child: assetPath != null
                  ? Image.asset(
                      assetPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          CustomPaint(painter: _MintPixelAvatarPainter()),
                    )
                  : CustomPaint(painter: _MintPixelAvatarPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

/// 在头像外缘绘制「锯齿台阶」式描边，模拟像素画边框。
class _PixelatedBorderPainter extends CustomPainter {
  final double cornerRadius;
  final double step;
  final Color outerColor;
  final Color midColor;
  final Color innerColor;

  _PixelatedBorderPainter({
    required this.cornerRadius,
    required this.step,
    required this.outerColor,
    required this.midColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius.clamp(0.0, math.min(w, h) / 2);

    void strokePolyline(List<Offset> pts, Paint paint, {bool close = false}) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      if (close) path.close();
      canvas.drawPath(path, paint);
    }

    // 外圈粗线（直角阶梯近似圆角矩形）
    final outer = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.miter;

    final mid = Paint()
      ..color = midColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.miter;

    final inner = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.miter;

    List<Offset> steppedRect(double inset) {
      final x0 = inset;
      final y0 = inset;
      final x1 = w - inset;
      final y1 = h - inset;
      final s = step;
      return [
        Offset(x0 + r, y0),
        Offset(x1 - r, y0),
        Offset(x1 - r + s, y0 + s),
        Offset(x1, y0 + r),
        Offset(x1, y1 - r),
        Offset(x1 - s, y1 - r + s),
        Offset(x1 - r, y1),
        Offset(x0 + r, y1),
        Offset(x0 + r - s, y1 - s),
        Offset(x0, y1 - r),
        Offset(x0, y0 + r),
        Offset(x0 + s, y0 + r - s),
        Offset(x0 + r, y0),
      ];
    }

    strokePolyline(steppedRect(1.5), outer, close: true);
    strokePolyline(steppedRect(3.5), mid, close: true);
    strokePolyline(steppedRect(5), inner, close: true);
  }

  @override
  bool shouldRepaint(covariant _PixelatedBorderPainter oldDelegate) {
    return oldDelegate.outerColor != outerColor ||
        oldDelegate.midColor != midColor ||
        oldDelegate.innerColor != innerColor ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.step != step;
  }
}

/// 内置 8-bit 风格 Mint 小人（不依赖外部图片）。
class _MintPixelAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final n = 8;
    final cell = size.width / n;
    final bg = Paint()..color = AppTheme.surfaceDeep;
    canvas.drawRect(Offset.zero & size, bg);

    void px(int gx, int gy, Color c) {
      final paint = Paint()..color = c;
      canvas.drawRect(
        Rect.fromLTWH(gx * cell, gy * cell, cell + 0.5, cell + 0.5),
        paint,
      );
    }

    const skin = Color(0xFFFFD4A8);
    final hair = AppTheme.primaryLight;
    final eye = AppTheme.primary;
    final shirt = AppTheme.bonusMint;
    final blush = AppTheme.bonusRose.withValues(alpha: 0.55);

    // 头发
    for (var x = 2; x <= 5; x++) {
      px(x, 1, hair);
    }
    px(1, 2, hair);
    px(6, 2, hair);
    // 脸
    for (var y = 2; y <= 4; y++) {
      for (var x = 2; x <= 5; x++) {
        if (x == 1 || x == 6) continue;
        px(x, y, skin);
      }
    }
    px(2, 3, eye);
    px(5, 3, eye);
    px(2, 4, blush);
    px(5, 4, blush);
    px(3, 5, skin);
    px(4, 5, skin);
    // 身体
    for (var x = 2; x <= 5; x++) {
      for (var y = 6; y <= 7; y++) {
        px(x, y, shirt);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
