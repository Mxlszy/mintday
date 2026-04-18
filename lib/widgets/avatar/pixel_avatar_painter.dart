import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import 'avatar_part_data.dart';

class PixelAvatar extends StatelessWidget {
  const PixelAvatar({super.key, required this.config, this.size = 78});

  final AvatarConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarHeight = size;
    final avatarWidth =
        avatarHeight * AvatarPartData.gridWidth / AvatarPartData.gridHeight;

    return SizedBox(
      width: avatarWidth,
      height: avatarHeight,
      child: CustomPaint(
        size: Size(avatarWidth, avatarHeight),
        painter: PixelAvatarPainter(config: config),
      ),
    );
  }
}

class PixelAvatarPainter extends CustomPainter {
  const PixelAvatarPainter({required this.config});

  final AvatarConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = min(
      size.width / AvatarPartData.gridWidth,
      size.height / AvatarPartData.gridHeight,
    );
    final drawWidth = cell * AvatarPartData.gridWidth;
    final drawHeight = cell * AvatarPartData.gridHeight;
    final offset = Offset(
      (size.width - drawWidth) / 2,
      (size.height - drawHeight) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    _paintPart(
      canvas,
      offset,
      cell,
      AvatarPartData.faceShapes[config.faceShape].pixels,
      AvatarPartData.skinColors[config.skinColor],
      paint,
    );
    _paintPart(
      canvas,
      offset,
      cell,
      AvatarPartData.bodyStyles[config.bodyStyle].pixels,
      AvatarPartData.bodyColors[config.bodyColor],
      paint,
    );
    _paintPart(
      canvas,
      offset,
      cell,
      AvatarPartData.hairStyles[config.hairStyle].pixels,
      AvatarPartData.hairStyles[config.hairStyle].baseColor,
      paint,
    );
    _paintPart(
      canvas,
      offset,
      cell,
      AvatarPartData.eyeStyles[config.eyeStyle].pixels,
      AvatarPartData.eyeStyles[config.eyeStyle].baseColor,
      paint,
    );
    _paintPart(
      canvas,
      offset,
      cell,
      AvatarPartData.mouthStyles[config.mouthStyle].pixels,
      AvatarPartData.mouthStyles[config.mouthStyle].baseColor,
      paint,
    );
    _paintPart(
      canvas,
      offset,
      cell,
      AvatarPartData.accessories[config.accessory].pixels,
      AvatarPartData.accessories[config.accessory].baseColor,
      paint,
    );
  }

  void _paintPart(
    Canvas canvas,
    Offset offset,
    double cell,
    List<List<int>> pixels,
    Color baseColor,
    Paint paint,
  ) {
    for (var y = 0; y < pixels.length; y++) {
      for (var x = 0; x < pixels[y].length; x++) {
        final value = pixels[y][x];
        if (value == 0) {
          continue;
        }

        paint.color = _resolveColor(value, baseColor);
        canvas.drawRect(
          Rect.fromLTWH(
            offset.dx + x * cell,
            offset.dy + y * cell,
            cell.ceilToDouble(),
            cell.ceilToDouble(),
          ),
          paint,
        );
      }
    }
  }

  Color _resolveColor(int value, Color baseColor) {
    return switch (value) {
      1 => baseColor,
      2 => _darken(baseColor, 0.2),
      3 => _lighten(baseColor, 0.15),
      _ => Colors.transparent,
    };
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0))
        .toColor();
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final nextLightness =
        hsl.lightness + (1 - hsl.lightness) * amount.clamp(0.0, 1.0);
    return hsl.withLightness(nextLightness.clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant PixelAvatarPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
