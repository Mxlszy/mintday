import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../core/user_profile_model.dart';
import '../models/avatar_config.dart';
import '../services/user_profile_prefs.dart';

class UserProfileProvider extends ChangeNotifier {
  static const _name = 'UserProfileProvider';

  UserProfileModel _profile = UserProfileModel.defaultProfile;
  bool _ready = false;
  bool _isDarkMode = false;

  UserProfileModel get profile => _profile;
  bool get isReady => _ready;
  bool get isDarkMode => _isDarkMode;

  Future<void> init() async {
    try {
      final nickname = await _resolveInitialNickname();
      final avatarConfig = await UserProfilePrefs.getAvatarConfig();
      _isDarkMode = await UserProfilePrefs.getDarkMode();
      _profile = UserProfileModel.defaultProfile.copyWith(
        nickname: nickname,
        avatarConfig: avatarConfig,
      );
    } catch (error, stackTrace) {
      log(
        '[$_name] init failed: $error',
        name: _name,
        error: error,
        stackTrace: stackTrace,
      );
      _profile = UserProfileModel.defaultProfile;
      _isDarkMode = false;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<bool> updateNickname(String value) async {
    final nextValue = value.trim();

    try {
      final authUser = _currentAuthUser;
      if (authUser != null) {
        final metadata = Map<String, dynamic>.from(
          authUser.userMetadata ?? const {},
        );
        metadata['nickname'] = nextValue.isEmpty ? 'MintDay 旅人' : nextValue;
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: metadata),
        );
      }

      await UserProfilePrefs.setNickname(nextValue);
      final nickname = await UserProfilePrefs.getNickname();
      _profile = _profile.copyWith(nickname: nickname);
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      log(
        '[$_name] updateNickname failed: $error',
        name: _name,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateAvatarConfig(AvatarConfig value) async {
    final previous = _profile;
    _profile = _profile.copyWith(avatarConfig: value);
    notifyListeners();

    try {
      await UserProfilePrefs.setAvatarConfig(value);
      return true;
    } catch (error, stackTrace) {
      _profile = previous;
      notifyListeners();
      log(
        '[$_name] updateAvatarConfig failed: $error',
        name: _name,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> syncFromAuth(User user) async {
    final nickname = _nicknameFromUser(user);
    await UserProfilePrefs.setNickname(nickname);
    _profile = _profile.copyWith(nickname: nickname);
    notifyListeners();
  }

  Future<bool> setDarkMode(bool value) async {
    final previous = _isDarkMode;
    _isDarkMode = value;
    notifyListeners();

    try {
      await UserProfilePrefs.setDarkMode(value);
      return true;
    } catch (error, stackTrace) {
      _isDarkMode = previous;
      notifyListeners();
      log(
        '[$_name] setDarkMode failed: $error',
        name: _name,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void applyProfile(UserProfileModel next) {
    _profile = next;
    notifyListeners();
  }

  Future<String> _resolveInitialNickname() async {
    final authUser = _currentAuthUser;
    if (authUser != null) {
      final nickname = _nicknameFromUser(authUser);
      await UserProfilePrefs.setNickname(nickname);
      return nickname;
    }
    return UserProfilePrefs.getNickname();
  }

  User? get _currentAuthUser {
    if (!SupabaseConfig.isConfigured) return null;

    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  String _nicknameFromUser(User user) {
    final nickname = user.userMetadata?['nickname']?.toString().trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    return 'MintDay 旅人';
  }
}
