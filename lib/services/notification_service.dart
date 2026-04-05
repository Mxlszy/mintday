import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'mintday_daily';
  static const _channelName = '每日打卡提醒';
  static const _notifId = 0;
  static const _prefEnabled = 'notif_enabled';
  static const _prefHour = 'notif_hour';
  static const _prefMinute = 'notif_minute';

  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
    log('[Notif] 初始化完成', name: 'NotificationService');

    // 恢复上次设置
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefEnabled) ?? false;
    if (enabled) {
      final h = prefs.getInt(_prefHour) ?? 20;
      final m = prefs.getInt(_prefMinute) ?? 0;
      await _scheduleDaily(TimeOfDay(hour: h, minute: m));
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  Future<void> enableReminder(TimeOfDay time) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, true);
    await prefs.setInt(_prefHour, time.hour);
    await prefs.setInt(_prefMinute, time.minute);
    await _scheduleDaily(time);
    log('[Notif] 已启用提醒: ${time.hour}:${time.minute}', name: 'NotificationService');
  }

  Future<void> disableReminder() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, false);
    await _plugin.cancel(_notifId);
    log('[Notif] 已关闭提醒', name: 'NotificationService');
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  Future<TimeOfDay> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_prefHour) ?? 20;
    final m = prefs.getInt(_prefMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _scheduleDaily(TimeOfDay time) async {
    if (kIsWeb) return;

    await _plugin.cancel(_notifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '每天提醒你完成打卡，保持习惯连续性',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _notifId,
      '🌱 打卡提醒',
      '今天还没打卡，别让连续记录断掉！',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
