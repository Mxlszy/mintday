import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../core/user_profile_model.dart';
import '../services/user_profile_prefs.dart';

/// 用户资料状态（昵称等后续可与 DB 对齐；当前主控台昵称按产品默认展示）。
class UserProfileProvider extends ChangeNotifier {
  static const _name = 'UserProfileProvider';

  UserProfileModel _profile = UserProfileModel.defaultProfile;
  UserProfileModel get profile => _profile;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    try {
      // 预留：与 UserProfilePrefs / DB 对齐时在此 merge；主控台昵称当前为模型默认「忠实用户」。
      await UserProfilePrefs.getNickname();
      _profile = UserProfileModel.defaultProfile;
      _ready = true;
      notifyListeners();
    } catch (e, s) {
      log('[$_name] init 失败: $e', name: _name, error: e, stackTrace: s);
      _profile = UserProfileModel.defaultProfile;
      _ready = true;
      notifyListeners();
    }
  }

  /// 后续从服务端 / DB 刷新时可调用。
  void applyProfile(UserProfileModel next) {
    _profile = next;
    notifyListeners();
  }
}
