import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'theme/app_theme.dart';

class AppUtils {
  AppUtils._();

  static MintGreetingStreakTier _greetingStreakTier(int streak) {
    if (streak <= 0) return MintGreetingStreakTier.zero;
    if (streak <= 2) return MintGreetingStreakTier.oneToTwo;
    if (streak <= 6) return MintGreetingStreakTier.threeToSix;
    if (streak <= 13) return MintGreetingStreakTier.sevenToThirteen;
    if (streak <= 29) return MintGreetingStreakTier.fourteenToTwentyNine;
    return MintGreetingStreakTier.thirtyPlus;
  }

  /// 按连续天数 × 今日打卡状态从 [AppConstants.dynamicGreetings] 随机一条；
  /// 使用当前毫秒时间戳为种子，每次调用都可能不同（重建时文案可能变化）。
  static String dynamicGreeting({
    required int streak,
    required bool isTodayChecked,
    required bool isStreakBroken,
  }) {
    final status = isTodayChecked
        ? MintGreetingTodayStatus.completedToday
        : (isStreakBroken
            ? MintGreetingTodayStatus.streakBroken
            : MintGreetingTodayStatus.notChecked);
    final tier = _greetingStreakTier(streak);
    final pool = AppConstants.dynamicGreetings[tier]![status]!;
    final index =
        Random(DateTime.now().millisecondsSinceEpoch).nextInt(pool.length);
    return pool[index];
  }

  static String randomEncouragement() {
    final rand = Random();
    final messages = AppConstants.encouragementMessages;
    return messages[rand.nextInt(messages.length)];
  }

  static String friendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    if (date.year == now.year) {
      return DateFormat('M月d日').format(date);
    }
    return DateFormat('yyyy年M月d日').format(date);
  }

  static String fullFriendlyDate(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${friendlyDate(date)} · 周$weekday';
  }

  static String streakText(int days) {
    if (days <= 0) return '尚未开始';
    if (days == 1) return '第 1 天';
    return '连续 $days 天';
  }

  static String progressText(double progress) {
    final percentage = (progress * 100).toInt();
    return '$percentage%';
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.bonusRose : null,
      ),
    );
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours 小时';
    return '$hours 小时 $remainingMinutes 分钟';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<DateTime> getDaysInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(
      lastDay.day,
      (index) => firstDay.add(Duration(days: index)),
    );
  }
}
