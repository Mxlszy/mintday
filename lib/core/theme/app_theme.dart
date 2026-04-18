import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static bool _isDarkMode = false;

  static const _lightPalette = _ThemePalette(
    background: Color(0xFFF7F9FC),
    shadowLight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFF111111),
    primary: Color(0xFF111111),
    primaryLight: Color(0xFF30343B),
    primaryDark: Color(0xFF000000),
    primaryMuted: Color(0xFFEEF3F8),
    accent: Color(0xFF93A2FF),
    accentLight: Color(0xFFE8EDFF),
    accentStrong: Color(0xFF657BDF),
    bonusBlue: Color(0xFF4F67DB),
    bonusRose: Color(0xFFDF6B7A),
    bonusMint: Color(0xFF72AEBB),
    goldAccent: Color(0xFFF5C842),
    heatmapCellEmpty: Color(0xFFEBEEF5),
    heatmapCellSkipped: Color(0xFFD3D1C7),
    heatmapCellPartial: Color(0xFF9FE1CB),
    heatmapCellDone: Color(0xFF5DCAA5),
    heatmapIntensity0: Color(0xFFE6E9ED),
    heatmapIntensity1: Color(0xFFB8DDD6),
    heatmapIntensity2: Color(0xFF7EC4B8),
    heatmapIntensity3: Color(0xFF5EADA4),
    heatmapIntensity4: Color(0xFF3D8A82),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF2F5FA),
    surfaceDeep: Color(0xFFE8EDF5),
    divider: Color(0xFFE9EEF5),
    border: Color(0xFFE4EAF1),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF5B6370),
    textHint: Color(0xFFA0A8B5),
  );

  static const _darkPalette = _ThemePalette(
    background: Color(0xFF1A1A2E),
    shadowLight: Color(0xFF4A5B8A),
    shadowDark: Color(0xFF050814),
    primary: Color(0xFF6E83F5),
    primaryLight: Color(0xFF9EAEFF),
    primaryDark: Color(0xFF4C5BC8),
    primaryMuted: Color(0xFF243254),
    accent: Color(0xFF8EA4FF),
    accentLight: Color(0xFF29375E),
    accentStrong: Color(0xFF7086F2),
    bonusBlue: Color(0xFF7EA6FF),
    bonusRose: Color(0xFFF08FA3),
    bonusMint: Color(0xFF8ACFC0),
    goldAccent: Color(0xFFF4D67A),
    heatmapCellEmpty: Color(0xFF23314F),
    heatmapCellSkipped: Color(0xFF47526E),
    heatmapCellPartial: Color(0xFF2D776B),
    heatmapCellDone: Color(0xFF44A893),
    heatmapIntensity0: Color(0xFF22304A),
    heatmapIntensity1: Color(0xFF2E5B63),
    heatmapIntensity2: Color(0xFF3F807B),
    heatmapIntensity3: Color(0xFF5CA9A1),
    heatmapIntensity4: Color(0xFF7DD8C6),
    surface: Color(0xFF16213E),
    surfaceVariant: Color(0xFF1E2A4A),
    surfaceDeep: Color(0xFF223056),
    divider: Color(0xFF26365E),
    border: Color(0xFF2A3B66),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFB7C0D8),
    textHint: Color(0xFF7E88A7),
  );

  static _ThemePalette get _palette =>
      _isDarkMode ? _darkPalette : _lightPalette;

  static void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  static bool get isDarkMode => _isDarkMode;

  static Color get background => _palette.background;
  static Color get shadowLight => _palette.shadowLight;
  static Color get shadowDark => _palette.shadowDark;
  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.primaryLight;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primaryMuted => _palette.primaryMuted;
  static Color get accent => _palette.accent;
  static Color get accentLight => _palette.accentLight;
  static Color get accentStrong => _palette.accentStrong;
  static Color get bonusBlue => _palette.bonusBlue;
  static Color get bonusRose => _palette.bonusRose;
  static Color get bonusMint => _palette.bonusMint;
  static Color get goldAccent => _palette.goldAccent;
  static Color get heatmapCellEmpty => _palette.heatmapCellEmpty;
  static Color get heatmapCellSkipped => _palette.heatmapCellSkipped;
  static Color get heatmapCellPartial => _palette.heatmapCellPartial;
  static Color get heatmapCellDone => _palette.heatmapCellDone;
  static Color get heatmapIntensity0 => _palette.heatmapIntensity0;
  static Color get heatmapIntensity1 => _palette.heatmapIntensity1;
  static Color get heatmapIntensity2 => _palette.heatmapIntensity2;
  static Color get heatmapIntensity3 => _palette.heatmapIntensity3;
  static Color get heatmapIntensity4 => _palette.heatmapIntensity4;
  static Color get surface => _palette.surface;
  static Color get surfaceVariant => _palette.surfaceVariant;
  static Color get surfaceDeep => _palette.surfaceDeep;
  static Color get divider => _palette.divider;
  static Color get border => _palette.border;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textHint => _palette.textHint;
  static Color get success => bonusBlue;
  static Color get warning => accentStrong;
  static Color get error => bonusRose;
  static Color get skipped => textHint;

  static List<Color> get rewardPalette => [
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

  static List<BoxShadow> get neuRaised => _isDarkMode
      ? [
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.42),
            offset: const Offset(0, 18),
            blurRadius: 36,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.08),
            offset: const Offset(-3, -3),
            blurRadius: 14,
          ),
        ]
      : [
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

  static List<BoxShadow> get neuSubtle => _isDarkMode
      ? [
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.32),
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.05),
            offset: const Offset(-2, -2),
            blurRadius: 10,
          ),
        ]
      : [
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.035),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ];

  static List<BoxShadow> get neuFlat => _isDarkMode
      ? [
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.24),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.04),
            offset: const Offset(-1, -1),
            blurRadius: 6,
          ),
        ]
      : [
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.025),
            offset: const Offset(0, 5),
            blurRadius: 12,
          ),
        ];

  static ThemeData get lightTheme =>
      _buildTheme(_lightPalette, Brightness.light);

  static ThemeData get darkTheme => _buildTheme(_darkPalette, Brightness.dark);

  static ThemeData _buildTheme(_ThemePalette palette, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
          primary: palette.primary,
          secondary: palette.accent,
          surface: palette.surface,
          error: palette.bonusRose,
        ).copyWith(
          onPrimary: Colors.white,
          onSecondary: brightness == Brightness.dark
              ? Colors.white
              : palette.primaryDark,
          onSurface: palette.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: palette.border),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
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
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        prefixIconColor: palette.textHint,
        suffixIconColor: palette.textHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        hintStyle: TextStyle(
          color: palette.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceVariant,
        selectedColor: palette.primary,
        disabledColor: palette.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: palette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        brightness: brightness,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? palette.primary
            : palette.textPrimary,
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

  static TextStyle get h1 => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.15,
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.2,
  );

  static TextStyle get h3 => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.35,
  );

  static TextStyle get body => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
    height: 1.5,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textHint,
    height: 1.4,
  );

  static TextStyle get label => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle get statNumber => TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppTheme.textPrimary,
    height: 1.0,
  );
}

class _ThemePalette {
  final Color background;
  final Color shadowLight;
  final Color shadowDark;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryMuted;
  final Color accent;
  final Color accentLight;
  final Color accentStrong;
  final Color bonusBlue;
  final Color bonusRose;
  final Color bonusMint;
  final Color goldAccent;
  final Color heatmapCellEmpty;
  final Color heatmapCellSkipped;
  final Color heatmapCellPartial;
  final Color heatmapCellDone;
  final Color heatmapIntensity0;
  final Color heatmapIntensity1;
  final Color heatmapIntensity2;
  final Color heatmapIntensity3;
  final Color heatmapIntensity4;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceDeep;
  final Color divider;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const _ThemePalette({
    required this.background,
    required this.shadowLight,
    required this.shadowDark,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryMuted,
    required this.accent,
    required this.accentLight,
    required this.accentStrong,
    required this.bonusBlue,
    required this.bonusRose,
    required this.bonusMint,
    required this.goldAccent,
    required this.heatmapCellEmpty,
    required this.heatmapCellSkipped,
    required this.heatmapCellPartial,
    required this.heatmapCellDone,
    required this.heatmapIntensity0,
    required this.heatmapIntensity1,
    required this.heatmapIntensity2,
    required this.heatmapIntensity3,
    required this.heatmapIntensity4,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceDeep,
    required this.divider,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });
}
