import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFF7F9FC);
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFF111111);

  static const Color primary = Color(0xFF111111);
  static const Color primaryLight = Color(0xFF30343B);
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryMuted = Color(0xFFEEF3F8);

  static const Color accent = Color(0xFF93A2FF);
  static const Color accentLight = Color(0xFFE8EDFF);
  static const Color accentStrong = Color(0xFF657BDF);
  static const Color bonusBlue = Color(0xFF4F67DB);
  static const Color bonusRose = Color(0xFFDF6B7A);
  static const Color bonusMint = Color(0xFF72AEBB);

  /// 高亮金（连续徽章最高档、像素图标 grid 8 号色对齐）。
  static const Color goldAccent = Color(0xFFF5C842);

  /// 月历热力图：按打卡状态着色（与 check_ins 聚合状态一致）。
  static const Color heatmapCellEmpty = Color(0xFFEBEEF5);
  static const Color heatmapCellSkipped = Color(0xFFD3D1C7);
  static const Color heatmapCellPartial = Color(0xFF9FE1CB);
  static const Color heatmapCellDone = Color(0xFF5DCAA5);

  /// GitHub 式「按次数」热力图色阶（0 次 → 高次），12 周图共用。
  static const Color heatmapIntensity0 = Color(0xFFE6E9ED);
  static const Color heatmapIntensity1 = Color(0xFFB8DDD6);
  static const Color heatmapIntensity2 = Color(0xFF7EC4B8);
  static const Color heatmapIntensity3 = Color(0xFF5EADA4);
  static const Color heatmapIntensity4 = Color(0xFF3D8A82);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F5FA);
  static const Color surfaceDeep = Color(0xFFE8EDF5);
  static const Color divider = Color(0xFFE9EEF5);
  static const Color border = Color(0xFFE4EAF1);

  static const Color textPrimary = primary;
  static const Color textSecondary = Color(0xFF5B6370);
  static const Color textHint = Color(0xFFA0A8B5);

  static const Color success = bonusBlue;
  static const Color warning = accentStrong;
  static const Color error = bonusRose;
  static const Color skipped = textHint;

  static const List<Color> rewardPalette = [
    bonusBlue,
    accent,
    bonusRose,
    bonusMint,
  ];

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  static const double radiusS = 14.0;
  static const double radiusM = 20.0;
  static const double radiusL = 28.0;
  static const double radiusXL = 36.0;

  static List<BoxShadow> get neuRaised => [
        BoxShadow(
          color: shadowDark.withValues(alpha: 0.05),
          offset: const Offset(0, 14),
          blurRadius: 32,
        ),
        BoxShadow(
          color: shadowDark.withValues(alpha: 0.02),
          offset: const Offset(0, 3),
          blurRadius: 10,
        ),
      ];

  static List<BoxShadow> get neuSubtle => [
        BoxShadow(
          color: shadowDark.withValues(alpha: 0.035),
          offset: const Offset(0, 10),
          blurRadius: 20,
        ),
      ];

  static List<BoxShadow> get neuFlat => [
        BoxShadow(
          color: shadowDark.withValues(alpha: 0.025),
          offset: const Offset(0, 5),
          blurRadius: 12,
        ),
      ];

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
    ).copyWith(
      onPrimary: Colors.white,
      onSecondary: primary,
      onSurface: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        hintStyle: const TextStyle(
          color: textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AppTextStyle {
  AppTextStyle._();

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.15,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textHint,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle statNumber = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppTheme.textPrimary,
    height: 1.0,
  );
}
