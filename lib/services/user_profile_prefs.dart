import 'package:shared_preferences/shared_preferences.dart';

/// 本地用户展示信息（昵称用于分享卡）。
class UserProfilePrefs {
  UserProfilePrefs._();

  static const _keyNickname = 'mintday_user_nickname';

  static Future<String> getNickname() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyNickname)?.trim().isNotEmpty == true
        ? p.getString(_keyNickname)!.trim()
        : 'MintDay 旅人';
  }

  static Future<void> setNickname(String value) async {
    final p = await SharedPreferences.getInstance();
    final v = value.trim();
    if (v.isEmpty) {
      await p.remove(_keyNickname);
    } else {
      await p.setString(_keyNickname, v);
    }
  }
}
