import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_config.dart';

class UserProfilePrefs {
  UserProfilePrefs._();

  static const _keyNickname = 'mintday_user_nickname';
  static const _keyDarkMode = 'mintday_dark_mode';
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keySyncedToCloud = 'synced_to_cloud';
  static const _keyAvatarConfig = 'avatar_config';
  static const _keyAvatarBackgroundNftId = 'avatar_background_nft_id';
  static const _keyLocalFriendUserId = 'friend_local_user_id';
  static const _keySocialNotificationSeenPrefix =
      'social_notification_last_seen_';

  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString(_keyNickname)?.trim();
    return nickname != null && nickname.isNotEmpty ? nickname : 'MintDay 旅人';
  }

  static Future<void> setNickname(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final nextValue = value.trim();
    if (nextValue.isEmpty) {
      await prefs.remove(_keyNickname);
      return;
    }
    await prefs.setString(_keyNickname, nextValue);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  static Future<AvatarConfig?> getAvatarConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAvatarConfig);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AvatarConfig.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setAvatarConfig(AvatarConfig value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatarConfig, jsonEncode(value.toJson()));
  }

  static Future<String?> getAvatarBackgroundNftId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyAvatarBackgroundNftId)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> setAvatarBackgroundNftId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final nextValue = value.trim();
    if (nextValue.isEmpty) {
      await prefs.remove(_keyAvatarBackgroundNftId);
      return;
    }
    await prefs.setString(_keyAvatarBackgroundNftId, nextValue);
  }

  static Future<bool> getOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, value);
  }

  static Future<bool> getSyncedToCloud() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySyncedToCloud) ?? false;
  }

  static Future<void> setSyncedToCloud(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySyncedToCloud, value);
  }

  static Future<String> getLocalFriendUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_keyLocalFriendUserId)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = 'mint_${const Uuid().v4()}';
    await prefs.setString(_keyLocalFriendUserId, created);
    return created;
  }

  static Future<DateTime?> getSocialNotificationLastSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs
        .getString('$_keySocialNotificationSeenPrefix$userId')
        ?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setSocialNotificationLastSeen(
    String userId,
    DateTime value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keySocialNotificationSeenPrefix$userId',
      value.toIso8601String(),
    );
  }
}
