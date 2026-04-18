import 'dart:math';

import 'package:flutter/foundation.dart';

@immutable
class AvatarConfig {
  static const int skinColorCount = 5;
  static const int faceShapeCount = 3;
  static const int hairStyleCount = 6;
  static const int eyeStyleCount = 4;
  static const int mouthStyleCount = 3;
  static const int accessoryCount = 4;
  static const int bodyStyleCount = 6;
  static const int bodyColorCount = 6;

  final int skinColor;
  final int faceShape;
  final int hairStyle;
  final int eyeStyle;
  final int mouthStyle;
  final int accessory;
  final int bodyStyle;
  final int bodyColor;

  const AvatarConfig({
    required this.skinColor,
    required this.faceShape,
    required this.hairStyle,
    required this.eyeStyle,
    required this.mouthStyle,
    required this.accessory,
    required this.bodyStyle,
    required this.bodyColor,
  });

  static const AvatarConfig defaultConfig = AvatarConfig(
    skinColor: 1,
    faceShape: 0,
    hairStyle: 0,
    eyeStyle: 0,
    mouthStyle: 0,
    accessory: 0,
    bodyStyle: 0,
    bodyColor: 0,
  );

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    return AvatarConfig(
      skinColor: _readInt(json['skinColor'], defaultConfig.skinColor),
      faceShape: _readInt(json['faceShape'], defaultConfig.faceShape),
      hairStyle: _readInt(json['hairStyle'], defaultConfig.hairStyle),
      eyeStyle: _readInt(json['eyeStyle'], defaultConfig.eyeStyle),
      mouthStyle: _readInt(json['mouthStyle'], defaultConfig.mouthStyle),
      accessory: _readInt(json['accessory'], defaultConfig.accessory),
      bodyStyle: _readInt(json['bodyStyle'], defaultConfig.bodyStyle),
      bodyColor: _readInt(json['bodyColor'], defaultConfig.bodyColor),
    ).normalizeIndices();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'skinColor': skinColor,
      'faceShape': faceShape,
      'hairStyle': hairStyle,
      'eyeStyle': eyeStyle,
      'mouthStyle': mouthStyle,
      'accessory': accessory,
      'bodyStyle': bodyStyle,
      'bodyColor': bodyColor,
    };
  }

  AvatarConfig copyWith({
    int? skinColor,
    int? faceShape,
    int? hairStyle,
    int? eyeStyle,
    int? mouthStyle,
    int? accessory,
    int? bodyStyle,
    int? bodyColor,
  }) {
    return AvatarConfig(
      skinColor: skinColor ?? this.skinColor,
      faceShape: faceShape ?? this.faceShape,
      hairStyle: hairStyle ?? this.hairStyle,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      accessory: accessory ?? this.accessory,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      bodyColor: bodyColor ?? this.bodyColor,
    ).normalizeIndices();
  }

  AvatarConfig normalizeIndices() {
    return AvatarConfig(
      skinColor: _normalizeIndex(
        skinColor,
        skinColorCount,
        defaultConfig.skinColor,
      ),
      faceShape: _normalizeIndex(
        faceShape,
        faceShapeCount,
        defaultConfig.faceShape,
      ),
      hairStyle: _normalizeIndex(
        hairStyle,
        hairStyleCount,
        defaultConfig.hairStyle,
      ),
      eyeStyle: _normalizeIndex(
        eyeStyle,
        eyeStyleCount,
        defaultConfig.eyeStyle,
      ),
      mouthStyle: _normalizeIndex(
        mouthStyle,
        mouthStyleCount,
        defaultConfig.mouthStyle,
      ),
      accessory: _normalizeIndex(
        accessory,
        accessoryCount,
        defaultConfig.accessory,
      ),
      bodyStyle: _normalizeIndex(
        bodyStyle,
        bodyStyleCount,
        defaultConfig.bodyStyle,
      ),
      bodyColor: _normalizeIndex(
        bodyColor,
        bodyColorCount,
        defaultConfig.bodyColor,
      ),
    );
  }

  static AvatarConfig random([Random? random]) {
    final generator = random ?? Random();
    return AvatarConfig(
      skinColor: generator.nextInt(skinColorCount),
      faceShape: generator.nextInt(faceShapeCount),
      hairStyle: generator.nextInt(hairStyleCount),
      eyeStyle: generator.nextInt(eyeStyleCount),
      mouthStyle: generator.nextInt(mouthStyleCount),
      accessory: generator.nextInt(accessoryCount),
      bodyStyle: generator.nextInt(bodyStyleCount),
      bodyColor: generator.nextInt(bodyColorCount),
    );
  }

  static int _readInt(dynamic value, int fallback) {
    return value is int ? value : fallback;
  }

  static int _normalizeIndex(int value, int max, int fallback) {
    if (value >= 0 && value < max) {
      return value;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AvatarConfig &&
            runtimeType == other.runtimeType &&
            skinColor == other.skinColor &&
            faceShape == other.faceShape &&
            hairStyle == other.hairStyle &&
            eyeStyle == other.eyeStyle &&
            mouthStyle == other.mouthStyle &&
            accessory == other.accessory &&
            bodyStyle == other.bodyStyle &&
            bodyColor == other.bodyColor;
  }

  @override
  int get hashCode => Object.hash(
    skinColor,
    faceShape,
    hairStyle,
    eyeStyle,
    mouthStyle,
    accessory,
    bodyStyle,
    bodyColor,
  );
}
