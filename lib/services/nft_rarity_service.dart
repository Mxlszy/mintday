import '../models/nft_asset.dart';

class NftRarityEvaluation {
  const NftRarityEvaluation({
    required this.rarity,
    this.reasons = const <String>[],
    this.isSpecialTimePoint = false,
    this.isHoliday = false,
    this.holidayLabel,
  });

  final NftRarity rarity;
  final List<String> reasons;
  final bool isSpecialTimePoint;
  final bool isHoliday;
  final String? holidayLabel;
}

class NftRarityService {
  NftRarityService._();

  static const Map<String, String> _fixedHolidayLabels = {
    '01-01': '元旦',
    '02-14': '情人节',
    '05-01': '劳动节',
    '06-01': '儿童节',
    '09-10': '教师节',
    '10-01': '国庆节',
    '12-24': '平安夜',
    '12-25': '圣诞节',
    '12-31': '跨年夜',
  };

  static NftRarityEvaluation evaluate({
    required DateTime capturedAt,
    int? mood,
    required int streakDays,
    bool isGoalFinalCheckIn = false,
  }) {
    final normalizedMood = (mood ?? 0).clamp(0, 5);
    final holidayLabel = _holidayLabelFor(capturedAt);
    final isNightMoment = capturedAt.hour < 5;
    final isHoliday = holidayLabel != null;
    final isSpecialTimePoint = isNightMoment || isHoliday;

    if (streakDays >= 100 || isGoalFinalCheckIn) {
      final reasons = <String>[
        if (streakDays >= 100) '连续打卡达到 $streakDays 天',
        if (isGoalFinalCheckIn) '完成目标的最终打卡',
      ];
      return NftRarityEvaluation(
        rarity: NftRarity.legendary,
        reasons: reasons,
        isSpecialTimePoint: isSpecialTimePoint,
        isHoliday: isHoliday,
        holidayLabel: holidayLabel,
      );
    }

    if (streakDays >= 30 || isSpecialTimePoint) {
      final reasons = <String>[
        if (streakDays >= 30) '连续打卡达到 $streakDays 天',
        if (isSpecialTimePoint)
          isHoliday ? '特殊节日打卡 · $holidayLabel' : '凌晨时刻完成打卡',
      ];
      return NftRarityEvaluation(
        rarity: NftRarity.epic,
        reasons: reasons,
        isSpecialTimePoint: isSpecialTimePoint,
        isHoliday: isHoliday,
        holidayLabel: holidayLabel,
      );
    }

    if (streakDays >= 7 || normalizedMood >= 5) {
      final reasons = <String>[
        if (streakDays >= 7) '连续打卡达到 $streakDays 天',
        if (normalizedMood >= 5) '心情满分',
      ];
      return NftRarityEvaluation(
        rarity: NftRarity.rare,
        reasons: reasons,
        isSpecialTimePoint: isSpecialTimePoint,
        isHoliday: isHoliday,
        holidayLabel: holidayLabel,
      );
    }

    return NftRarityEvaluation(
      rarity: NftRarity.common,
      reasons: const ['完成一次日常打卡'],
      isSpecialTimePoint: isSpecialTimePoint,
      isHoliday: isHoliday,
      holidayLabel: holidayLabel,
    );
  }

  static String? holidayLabel(DateTime capturedAt) {
    return _holidayLabelFor(capturedAt);
  }

  static bool isSpecialTimePoint(DateTime capturedAt) {
    return capturedAt.hour < 5 || _holidayLabelFor(capturedAt) != null;
  }

  static String? _holidayLabelFor(DateTime dateTime) {
    final key =
        '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    return _fixedHolidayLabels[key];
  }
}
