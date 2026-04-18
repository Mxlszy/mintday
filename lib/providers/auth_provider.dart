import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'user_profile_provider.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  StreamSubscription<AuthState>? _authSubscription;
  UserProfileProvider? _userProfileProvider;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _didInit = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isConfigured => _authService.isConfigured;

  Future<void> init() async {
    if (_didInit) return;
    _didInit = true;

    if (!_authService.isConfigured) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _applyUser(_authService.currentUser, notify: false);
    _authSubscription = _authService.onAuthStateChange.listen((state) {
      _applyUser(state.session?.user ?? _authService.currentUser);
    });
    notifyListeners();
  }

  void bindUserProfileProvider(UserProfileProvider provider) {
    if (identical(_userProfileProvider, provider)) {
      return;
    }
    _userProfileProvider = provider;

    final user = _user;
    if (user != null) {
      unawaited(provider.syncFromAuth(user));
    }
  }

  Future<AuthResult<User?>> signUpWithEmail(
    String email,
    String password,
    String nickname,
  ) async {
    return _runAction(() async {
      final result = await _authService.signUpWithEmail(
        email,
        password,
        nickname,
      );
      _handleResult(result);
      return result;
    });
  }

  Future<AuthResult<User?>> signInWithEmail(
    String email,
    String password,
  ) async {
    return _runAction(() async {
      final result = await _authService.signInWithEmail(email, password);
      _handleResult(result);
      return result;
    });
  }

  Future<AuthResult<void>> signInWithPhone(String phone) async {
    return _runAction(() async {
      final result = await _authService.signInWithPhone(phone);
      _handleResult(result);
      return result;
    });
  }

  Future<AuthResult<PhoneVerificationPayload>> verifyPhoneOtp(
    String phone,
    String otp,
  ) async {
    return _runAction(() async {
      final result = await _authService.verifyPhoneOtp(phone, otp);
      _handleResult(result);
      return result;
    });
  }

  Future<AuthResult<User>> updateNickname(String nickname) async {
    return _runAction(() async {
      final result = await _authService.updateNickname(nickname);
      _handleResult(result);
      return result;
    });
  }

  Future<AuthResult<void>> resetPassword(String email) async {
    return _runAction(() async {
      final result = await _authService.resetPassword(email);
      _handleResult(result, syncCurrentUser: false);
      return result;
    });
  }

  Future<AuthResult<void>> signOut() async {
    return _runAction(() async {
      final result = await _authService.signOut();
      if (result.isSuccess) {
        _applyUser(null, notify: false);
      } else {
        _errorMessage = result.message;
      }
      return result;
    });
  }

  Future<AuthResult<T>> _runAction<T>(
    Future<AuthResult<T>> Function() action,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleResult<T>(
    AuthResult<T> result, {
    bool syncCurrentUser = true,
  }) {
    _errorMessage = result.isSuccess ? null : result.message;
    if (!result.isSuccess) {
      return;
    }

    final payload = result.data;
    if (payload is User) {
      _applyUser(payload, notify: false);
      return;
    }
    if (payload is PhoneVerificationPayload) {
      _applyUser(payload.user, notify: false);
      return;
    }
    if (syncCurrentUser) {
      _applyUser(_authService.currentUser, notify: false);
    }
  }

  void _applyUser(User? nextUser, {bool notify = true}) {
    _user = nextUser;
    _status = nextUser == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;

    if (nextUser != null && _userProfileProvider != null) {
      unawaited(_userProfileProvider!.syncFromAuth(nextUser));
    }

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
