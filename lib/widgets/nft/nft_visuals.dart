import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nft_asset.dart';

class NftPalette {
  const NftPalette({
    required this.gradient,
    required this.glow,
    required this.frame,
    required this.icon,
    required this.secondary,
  });

  final List<Color> gradient;
  final Color glow;
  final Color frame;
  final Color icon;
  final Color secondary;
}

class NftRarityPalette {
  const NftRarityPalette({
    required this.base,
    required this.glow,
    required this.soft,
    required this.gradient,
  });

  final Color base;
  final Color glow;
  final Color soft;
  final List<Color> gradient;
}

NftPalette nftPaletteForCategory(NftCategory category) {
  return switch (category) {
    NftCategory.achievement => const NftPalette(
      gradient: [Color(0xFF2E103B), Color(0xFF6E2C91), Color(0xFFE0A63B)],
      glow: Color(0xFFF3C04C),
      frame: Color(0xFFFFE3A6),
      icon: Color(0xFFFFE6A8),
      secondary: Color(0xFFC77DFF),
    ),
    NftCategory.milestone => const NftPalette(
      gradient: [Color(0xFF0C2D48), Color(0xFF146C94), Color(0xFF18B7A8)],
      glow: Color(0xFF7CF2D9),
      frame: Color(0xFF9AE7FF),
      icon: Color(0xFFC9FFF9),
      secondary: Color(0xFF59D1FF),
    ),
    NftCategory.streak => const NftPalette(
      gradient: [Color(0xFF481013), Color(0xFFC03D2C), Color(0xFFFF9842)],
      glow: Color(0xFFFFC766),
      frame: Color(0xFFFFD1A8),
      icon: Color(0xFFFFE1B6),
      secondary: Color(0xFFFF7A59),
    ),
    NftCategory.custom => const NftPalette(
      gradient: [Color(0xFF14332A), Color(0xFF1F7A69), Color(0xFF7BDFC1)],
      glow: Color(0xFFB3FFE9),
      frame: Color(0xFFC8FFF0),
      icon: Color(0xFFE6FFF7),
      secondary: Color(0xFF69D6B4),
    ),
    NftCategory.moment => const NftPalette(
      gradient: [Color(0xFF11253A), Color(0xFF24556C), Color(0xFF6DD4BF)],
      glow: Color(0xFF88ECFF),
      frame: Color(0xFFA6E4FF),
      icon: Color(0xFFE6FAFF),
      secondary: Color(0xFFFFC857),
    ),
    NftCategory.creative => const NftPalette(
      gradient: [Color(0xFF311847), Color(0xFF5B2C83), Color(0xFFFF8A65)],
      glow: Color(0xFFFFB76B),
      frame: Color(0xFFFFD2A7),
      icon: Color(0xFFFFF0D9),
      secondary: Color(0xFFE040FB),
    ),
    NftCategory.collection => const NftPalette(
      gradient: [Color(0xFF1D2038), Color(0xFF4555A4), Color(0xFF8BC6EC)],
      glow: Color(0xFFC8E9FF),
      frame: Color(0xFFE6F3FF),
      icon: Color(0xFFFFFFFF),
      secondary: Color(0xFF8C6ED9),
    ),
  };
}

PixelIconData nftIconForCategory(NftCategory category) {
  return switch (category) {
    NftCategory.achievement => PixelIcons.trophy,
    NftCategory.milestone => PixelIcons.sprout,
    NftCategory.streak => PixelIcons.fire,
    NftCategory.custom => PixelIcons.diamond,
    NftCategory.moment => PixelIcons.camera,
    NftCategory.creative => PixelIcons.star,
    NftCategory.collection => PixelIcons.chart,
  };
}

NftRarityPalette nftRarityPalette(NftRarity rarity) {
  return switch (rarity) {
    NftRarity.common => const NftRarityPalette(
      base: Color(0xFFA0A0A0),
      glow: Color(0xFFD2D2D2),
      soft: Color(0xFFE8E8E8),
      gradient: [Color(0xFFB0B0B0), Color(0xFF8D8D8D)],
    ),
    NftRarity.rare => const NftRarityPalette(
      base: Color(0xFF4FC3F7),
      glow: Color(0xFFB3E5FC),
      soft: Color(0xFFE1F5FE),
      gradient: [Color(0xFFB0BEC5), Color(0xFF4FC3F7)],
    ),
    NftRarity.epic => const NftRarityPalette(
      base: Color(0xFFFFD740),
      glow: Color(0xFFFFF3B0),
      soft: Color(0xFFFFECB3),
      gradient: [Color(0xFFFFF176), Color(0xFFFFB300)],
    ),
    NftRarity.legendary => const NftRarityPalette(
      base: Color(0xFFE040FB),
      glow: Color(0xFFFF80AB),
      soft: Color(0xFFFFF59D),
      gradient: [
        Color(0xFFE040FB),
        Color(0xFFFF8A65),
        Color(0xFFFFD740),
        Color(0xFF4FC3F7),
      ],
    ),
  };
}

Color nftStatusColor(NftStatus status) {
  return switch (status) {
    NftStatus.pending => AppTheme.accentStrong,
    NftStatus.minting => AppTheme.goldAccent,
    NftStatus.minted => AppTheme.bonusMint,
    NftStatus.failed => AppTheme.error,
  };
}

Color nftRarityColor(NftRarity? rarity) {
  return nftRarityPalette(rarity ?? NftRarity.common).base;
}

List<Color> moodToneColors(int mood) {
  return switch (mood) {
    1 => const [Color(0xFF2F4858), Color(0xFF4C6983), Color(0xFF8CA3C8)],
    2 => const [Color(0xFF503A65), Color(0xFF8063A8), Color(0xFFBE95FF)],
    3 => const [Color(0xFF255C4C), Color(0xFF4C8C75), Color(0xFF97D8A6)],
    4 => const [Color(0xFF5A4C1F), Color(0xFFB88C36), Color(0xFFFFD166)],
    5 => const [Color(0xFF6C1D45), Color(0xFFDE4D86), Color(0xFFFFA8C9)],
    _ => const [Color(0xFF2E3A59), Color(0xFF566C9A), Color(0xFF96B4E6)],
  };
}

PixelIconData pixelMoodIcon(int mood) {
  return switch (mood) {
    1 => const PixelIconData([
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 8, 8, 8, 8, 8, 8, 0],
      [8, 8, 4, 8, 8, 4, 8, 8],
      [8, 8, 4, 8, 8, 4, 8, 8],
      [8, 8, 8, 8, 8, 8, 8, 8],
      [8, 8, 8, 1, 1, 8, 8, 8],
      [8, 8, 1, 8, 8, 1, 8, 8],
      [0, 8, 8, 8, 8, 8, 8, 0],
    ]),
    2 => const PixelIconData([
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 8, 8, 8, 8, 8, 8, 0],
      [8, 8, 4, 8, 8, 4, 8, 8],
      [8, 8, 4, 8, 8, 4, 8, 8],
      [8, 8, 8, 8, 8, 8, 8, 8],
      [8, 8, 1, 1, 1, 1, 8, 8],
      [8, 8, 8, 8, 8, 8, 8, 8],
      [0, 8, 8, 8, 8, 8, 8, 0],
    ]),
    3 => const PixelIconData([
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 5, 5, 5, 5, 5, 5, 0],
      [5, 5, 1, 5, 5, 1, 5, 5],
      [5, 5, 1, 5, 5, 1, 5, 5],
      [5, 5, 5, 5, 5, 5, 5, 5],
      [5, 5, 1, 1, 1, 1, 5, 5],
      [5, 5, 5, 5, 5, 5, 5, 5],
      [0, 5, 5, 5, 5, 5, 5, 0],
    ]),
    4 => const PixelIconData([
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 8, 8, 8, 8, 8, 8, 0],
      [8, 8, 1, 8, 8, 1, 8, 8],
      [8, 8, 1, 8, 8, 1, 8, 8],
      [8, 8, 8, 8, 8, 8, 8, 8],
      [8, 1, 8, 8, 8, 8, 1, 8],
      [0, 8, 1, 1, 1, 1, 8, 0],
      [0, 0, 8, 8, 8, 8, 0, 0],
    ]),
    5 => const PixelIconData([
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 6, 6, 6, 6, 6, 6, 0],
      [6, 6, 1, 6, 6, 1, 6, 6],
      [6, 6, 1, 6, 6, 1, 6, 6],
      [6, 6, 8, 6, 6, 8, 6, 6],
      [6, 6, 1, 1, 1, 1, 6, 6],
      [0, 6, 8, 1, 1, 8, 6, 0],
      [0, 0, 6, 6, 6, 6, 0, 0],
    ]),
    _ => const PixelIconData([
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 5, 5, 5, 5, 5, 5, 0],
      [5, 5, 1, 5, 5, 1, 5, 5],
      [5, 5, 1, 5, 5, 1, 5, 5],
      [5, 5, 5, 5, 5, 5, 5, 5],
      [5, 5, 1, 1, 1, 1, 5, 5],
      [5, 5, 5, 5, 5, 5, 5, 5],
      [0, 5, 5, 5, 5, 5, 5, 0],
    ]),
  };
}

class NftStatusChip extends StatelessWidget {
  const NftStatusChip({super.key, required this.status});

  final NftStatus status;

  @override
  Widget build(BuildContext context) {
    final color = nftStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        status.label,
        style: AppTextStyle.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class NftRarityChip extends StatelessWidget {
  const NftRarityChip({super.key, required this.rarity, this.compact = false});

  final NftRarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = nftRarityPalette(rarity);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: palette.gradient),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.28),
            blurRadius: compact ? 10 : 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        rarity.label,
        style: AppTextStyle.caption.copyWith(
          color: Colors.black.withValues(alpha: 0.78),
          fontWeight: FontWeight.w800,
          fontSize: compact ? 10.5 : 12,
        ),
      ),
    );
  }
}

class NftCategoryChip extends StatelessWidget {
  const NftCategoryChip({
    super.key,
    required this.category,
    this.compact = false,
  });

  final NftCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = nftPaletteForCategory(category);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: palette.frame.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.frame.withValues(alpha: 0.28)),
      ),
      child: Text(
        category.label,
        style: AppTextStyle.caption.copyWith(
          color: palette.frame,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PixelMoodFace extends StatelessWidget {
  const PixelMoodFace({super.key, required this.mood, this.size = 28});

  final int mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PixelIcon(icon: pixelMoodIcon(mood), size: size);
  }
}
