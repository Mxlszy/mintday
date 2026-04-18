import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/avatar_config.dart';
import '../../models/nft_asset.dart';
import '../avatar/pixel_avatar_painter.dart';
import 'nft_card_render_data.dart';
import 'nft_visuals.dart';

class CreativeNftTemplateDefinition {
  const CreativeNftTemplateDefinition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.accentColor,
    required this.usesCollectionData,
    required this.defaultTitle,
    required this.defaultDescription,
    required this.builder,
  });

  final String id;
  final String name;
  final String subtitle;
  final PixelIconData icon;
  final NftCategory category;
  final Color accentColor;
  final bool usesCollectionData;
  final String Function(NftCardRenderData data) defaultTitle;
  final String Function(NftCardRenderData data) defaultDescription;
  final Widget Function(NftCardRenderData data, bool compact) builder;
}

final List<CreativeNftTemplateDefinition> creativeNftTemplates =
    <CreativeNftTemplateDefinition>[
      CreativeNftTemplateDefinition(
        id: 'pixel_diary',
        name: '像素日记',
        subtitle: '像把今天写进了一本会发光的日志',
        icon: PixelIcons.note,
        category: NftCategory.creative,
        accentColor: const Color(0xFFFF8A65),
        usesCollectionData: false,
        defaultTitle: (data) => '${data.goalTitle} · 像素日记',
        defaultDescription: (data) => data.primaryNote,
        builder: (data, compact) =>
            PixelDiaryTemplate(data: data, compact: compact),
      ),
      CreativeNftTemplateDefinition(
        id: 'data_viz',
        name: '数据可视化',
        subtitle: '把连续天数、专注时长变成像素图表',
        icon: PixelIcons.chart,
        category: NftCategory.creative,
        accentColor: const Color(0xFF4FC3F7),
        usesCollectionData: false,
        defaultTitle: (data) => '${data.goalTitle} · 数据之光',
        defaultDescription: (data) =>
            '累计 ${data.totalCheckIns} 次打卡，连续 ${data.streakDays} 天',
        builder: (data, compact) =>
            DataVizTemplate(data: data, compact: compact),
      ),
      CreativeNftTemplateDefinition(
        id: 'season_card',
        name: '季节卡',
        subtitle: '根据日期自动切换春夏秋冬主题',
        icon: PixelIcons.sun,
        category: NftCategory.creative,
        accentColor: const Color(0xFFFFD740),
        usesCollectionData: false,
        defaultTitle: (data) => '${_seasonName(data.createdAt)} 收藏卡',
        defaultDescription: (data) =>
            '把 ${data.goalTitle} 留在 ${_seasonName(data.createdAt)} 的颜色里',
        builder: (data, compact) =>
            SeasonCardTemplate(data: data, compact: compact),
      ),
      CreativeNftTemplateDefinition(
        id: 'milestone_badge',
        name: '里程碑纪念',
        subtitle: '奖杯、勋章与像素绶带的荣耀版式',
        icon: PixelIcons.trophy,
        category: NftCategory.creative,
        accentColor: const Color(0xFFE040FB),
        usesCollectionData: false,
        defaultTitle: (data) => '${data.goalTitle} · 荣耀勋章',
        defaultDescription: (data) => '把今天的坚持做成一枚可收藏的像素勋章',
        builder: (data, compact) =>
            MilestoneBadgeTemplate(data: data, compact: compact),
      ),
      CreativeNftTemplateDefinition(
        id: 'mood_spectrum',
        name: '心情光谱',
        subtitle: '最近 7 天心情生成一条渐变色带',
        icon: PixelIcons.heart,
        category: NftCategory.collection,
        accentColor: const Color(0xFF72AEBB),
        usesCollectionData: true,
        defaultTitle: (data) => '七日心情光谱',
        defaultDescription: (data) => '把最近一周的情绪波动压缩进一张色带 NFT',
        builder: (data, compact) =>
            MoodSpectrumTemplate(data: data, compact: compact),
      ),
      CreativeNftTemplateDefinition(
        id: 'minimal',
        name: '极简主义',
        subtitle: '大面积留白，只保留一句话和日期',
        icon: PixelIcons.diamond,
        category: NftCategory.creative,
        accentColor: const Color(0xFFA0A0A0),
        usesCollectionData: false,
        defaultTitle: (data) => data.goalTitle,
        defaultDescription: (data) => data.primaryNote,
        builder: (data, compact) =>
            MinimalistTemplate(data: data, compact: compact),
      ),
      CreativeNftTemplateDefinition(
        id: 'time_stamp',
        name: '时光邮票',
        subtitle: '像一枚为今天盖章的像素邮票',
        icon: PixelIcons.calendar,
        category: NftCategory.creative,
        accentColor: const Color(0xFF8C6ED9),
        usesCollectionData: false,
        defaultTitle: (data) => 'Time Stamp · ${data.goalTitle}',
        defaultDescription: (data) => '这一天值得被盖章留念',
        builder: (data, compact) =>
            TimeStampTemplate(data: data, compact: compact),
      ),
    ];

CreativeNftTemplateDefinition creativeTemplateById(String? templateId) {
  return creativeNftTemplates.firstWhere(
    (item) => item.id == templateId,
    orElse: () => creativeNftTemplates.first,
  );
}

Widget buildCreativeNftTemplate({
  required String? templateId,
  required NftCardRenderData data,
  bool compact = false,
}) {
  final definition = creativeTemplateById(templateId);
  return definition.builder(data, compact);
}

class PixelDiaryTemplate extends StatelessWidget {
  const PixelDiaryTemplate({
    super.key,
    required this.data,
    this.compact = false,
  });

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 24.0 : AppTheme.radiusXL;
    return _TemplateShell(
      radius: radius,
      rarity: data.rarity,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E2723), Color(0xFF7B4B2A), Color(0xFFFFCC80)],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TemplateHeader(
              icon: PixelIcons.note,
              title: 'PIXEL DIARY',
              dateLabel: _dateLabel(data.createdAt),
            ),
            SizedBox(height: compact ? 16 : 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(compact ? 14 : 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD9B98B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.h3.copyWith(
                        color: const Color(0xFF5A3D2B),
                        fontSize: compact ? 17 : 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.primaryNote,
                      maxLines: compact ? 5 : 7,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.body.copyWith(
                        color: const Color(0xFF6E5442),
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        PixelMoodFace(
                          mood: data.primaryMood,
                          size: compact ? 24 : 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data.goalTitle,
                            style: AppTextStyle.bodySmall.copyWith(
                              color: const Color(0xFF8A6A54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                PixelAvatar(
                  config: data.avatarConfig ?? AvatarConfig.defaultConfig,
                  size: compact ? 40 : 46,
                ),
                const SizedBox(width: 10),
                Text(
                  data.nickname,
                  style: AppTextStyle.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DataVizTemplate extends StatelessWidget {
  const DataVizTemplate({super.key, required this.data, this.compact = false});

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bars = <double>[
      (data.streakDays / 100).clamp(0.08, 1.0),
      (data.totalCheckIns / math.max(data.totalCheckIns, 30)).clamp(0.08, 1.0),
      (data.focusMinutes / math.max(data.focusMinutes, 180)).clamp(0.08, 1.0),
      ((data.primaryMood) / 5).clamp(0.08, 1.0),
    ];

    return _TemplateShell(
      rarity: data.rarity,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0C1628), Color(0xFF1F3B63), Color(0xFF4FC3F7)],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TemplateHeader(
              icon: PixelIcons.chart,
              title: 'DATA VIZ',
              dateLabel: data.rarity.label,
            ),
            SizedBox(height: compact ? 18 : 22),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.h2.copyWith(
                color: Colors.white,
                fontSize: compact ? 22 : 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.goalTitle,
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const Spacer(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(bars.length, (index) {
                  final labels = ['连续', '累计', '专注', '心情'];
                  final values = [
                    '${data.streakDays}',
                    '${data.totalCheckIns}',
                    '${data.focusMinutes}',
                    '${data.primaryMood}',
                  ];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == bars.length - 1 ? 0 : 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            values[index],
                            style: AppTextStyle.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: bars[index],
                                widthFactor: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.22),
                                        Colors.white,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            labels[index],
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeasonCardTemplate extends StatelessWidget {
  const SeasonCardTemplate({
    super.key,
    required this.data,
    this.compact = false,
  });

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _seasonColors(data.createdAt);
    return _TemplateShell(
      rarity: data.rarity,
      background: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 46,
            child: Icon(
              Icons.blur_on_rounded,
              size: compact ? 82 : 116,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TemplateHeader(
                  icon: _seasonIcon(data.createdAt),
                  title: _seasonName(data.createdAt).toUpperCase(),
                  dateLabel: data.goalTitle,
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.h1.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 28 : 34,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.description,
                  maxLines: compact ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      PixelMoodFace(
                        mood: data.primaryMood,
                        size: compact ? 24 : 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        data.nickname,
                        style: AppTextStyle.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MilestoneBadgeTemplate extends StatelessWidget {
  const MilestoneBadgeTemplate({
    super.key,
    required this.data,
    this.compact = false,
  });

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _TemplateShell(
      rarity: data.rarity,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF200F30), Color(0xFF5B2C83), Color(0xFFFFC857)],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 22),
        child: Column(
          children: [
            _TemplateHeader(
              icon: PixelIcons.trophy,
              title: 'MILESTONE',
              dateLabel: _dateLabel(data.createdAt),
            ),
            const Spacer(),
            Container(
              width: compact ? 170 : 214,
              height: compact ? 170 : 214,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFF59D),
                    Color(0xFFFFD740),
                    Color(0xFFFF8F00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD740).withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Center(
                child: PixelIcon(
                  icon: PixelIcons.medal,
                  size: compact ? 70 : 92,
                  color: const Color(0xFF6B3900),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.h2.copyWith(
                color: Colors.white,
                fontSize: compact ? 22 : 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.description,
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const Spacer(),
            Text(
              'STREAK ${data.streakDays} · FOCUS ${data.focusMinutes}M',
              style: AppTextStyle.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodSpectrumTemplate extends StatelessWidget {
  const MoodSpectrumTemplate({
    super.key,
    required this.data,
    this.compact = false,
  });

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final moods = data.recentMoodSeries.isEmpty
        ? <int>[data.primaryMood]
        : data.recentMoodSeries.take(7).toList();
    final blocks = moods.isEmpty ? 1 : moods.length;

    return _TemplateShell(
      rarity: data.rarity,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10131C), Color(0xFF243B55), Color(0xFF1E5151)],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TemplateHeader(
              icon: PixelIcons.heart,
              title: 'MOOD SPECTRUM',
              dateLabel: '$blocks DAYS',
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              style: AppTextStyle.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: List.generate(blocks, (index) {
                  final mood = moods[index];
                  final colors = moodToneColors(mood);
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index == blocks - 1 ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: colors,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Spacer(),
                          PixelMoodFace(mood: mood, size: compact ? 22 : 26),
                          const SizedBox(height: 10),
                          Text(
                            'D${index + 1}',
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '最近的心情正在慢慢汇成一条自己的光谱。',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.76),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MinimalistTemplate extends StatelessWidget {
  const MinimalistTemplate({
    super.key,
    required this.data,
    this.compact = false,
  });

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = nftRarityColor(data.rarity);
    return _TemplateShell(
      rarity: data.rarity,
      background: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.isDarkMode
              ? const Color(0xFF1A1F2E)
              : const Color(0xFFF7F7F5),
          AppTheme.isDarkMode
              ? const Color(0xFF11151F)
              : const Color(0xFFFFFCF5),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateLabel(data.createdAt),
              style: AppTextStyle.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Container(width: compact ? 42 : 56, height: 4, color: color),
            const SizedBox(height: 18),
            Text(
              data.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.h1.copyWith(
                color: AppTheme.isDarkMode
                    ? Colors.white
                    : const Color(0xFF161616),
                fontSize: compact ? 28 : 36,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.description,
              maxLines: compact ? 4 : 5,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.body.copyWith(
                color: AppTheme.isDarkMode
                    ? Colors.white.withValues(alpha: 0.72)
                    : const Color(0xFF555555),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  data.nickname,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                NftCategoryChip(category: NftCategory.creative, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TimeStampTemplate extends StatelessWidget {
  const TimeStampTemplate({
    super.key,
    required this.data,
    this.compact = false,
  });

  final NftCardRenderData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _TemplateShell(
      rarity: data.rarity,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF12203A), Color(0xFF304878), Color(0xFF9C89B8)],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TemplateHeader(
              icon: PixelIcons.calendar,
              title: 'TIME STAMP',
              dateLabel: _timeLabel(data.createdAt),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.goalTitle,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Container(
                        width: compact ? 120 : 150,
                        height: compact ? 120 : 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Center(
                          child: PixelIcon(
                            icon: PixelIcons.calendar,
                            size: compact ? 58 : 74,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      data.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateShell extends StatelessWidget {
  const _TemplateShell({
    required this.rarity,
    required this.background,
    required this.child,
    this.radius = AppTheme.radiusXL,
  });

  final NftRarity rarity;
  final Gradient background;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final rarityPalette = nftRarityPalette(rarity);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: background,
        border: Border.all(
          color: rarityPalette.base.withValues(alpha: 0.92),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityPalette.glow.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _TemplateHeader extends StatelessWidget {
  const _TemplateHeader({
    required this.icon,
    required this.title,
    required this.dateLabel,
  });

  final PixelIconData icon;
  final String title;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: PixelIcon(icon: icon, size: 18, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: AppTextStyle.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _dateLabel(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}.$month.$day';
}

String _timeLabel(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _seasonName(DateTime dateTime) {
  switch (dateTime.month) {
    case 3:
    case 4:
    case 5:
      return '春季';
    case 6:
    case 7:
    case 8:
      return '夏季';
    case 9:
    case 10:
    case 11:
      return '秋季';
    default:
      return '冬季';
  }
}

List<Color> _seasonColors(DateTime dateTime) {
  switch (_seasonName(dateTime)) {
    case '春季':
      return const [Color(0xFF6EC6A8), Color(0xFF9BE15D), Color(0xFFF9F871)];
    case '夏季':
      return const [Color(0xFF00B4DB), Color(0xFF0083B0), Color(0xFF5CE1E6)];
    case '秋季':
      return const [Color(0xFF8C4A1F), Color(0xFFC96B2C), Color(0xFFFFC371)];
    default:
      return const [Color(0xFF6A82FB), Color(0xFF2F3B8F), Color(0xFFC2E9FB)];
  }
}

PixelIconData _seasonIcon(DateTime dateTime) {
  switch (_seasonName(dateTime)) {
    case '春季':
      return PixelIcons.sprout;
    case '夏季':
      return PixelIcons.sun;
    case '秋季':
      return PixelIcons.star;
    default:
      return PixelIcons.moon;
  }
}
