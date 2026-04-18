import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class AuthResult<T> {
  const AuthResult._({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  final bool isSuccess;
  final String message;
  final T? data;

  factory AuthResult.success({String message = '', T? data}) {
    return AuthResult._(isSuccess: true, message: message, data: data);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, message: message);
  }
}

class PhoneVerificationPayload {
  const PhoneVerificationPayload({
    required this.user,
    required this.needsNickname,
  });

  final User user;
  final bool needsNickname;
}

class AuthService {
  const AuthService();

  static const String defaultNickname = 'MintDay 旅人';

  bool get isConfigured => SupabaseConfig.isConfigured;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  User? get currentUser {
    if (!isConfigured) return null;

    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get onAuthStateChange {
    if (!isConfigured) {
      return const Stream<AuthState>.empty();
    }

    try {
      return _auth.onAuthStateChange;
    } catch (_) {
      return const Stream<AuthState>.empty();
    }
  }

  Future<AuthResult<User?>> signUpWithEmail(
    String email,
    String password,
    String nickname,
  ) async {
    if (!isConfigured) {
      return AuthResult.failure('请先在 SupabaseConfig 中填写项目配置');
    }

    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nickname': _normalizeNickname(nickname)},
      );

      final message = response.session == null
          ? '注册成功，请前往邮箱完成验证'
          : '注册成功';
      return AuthResult.success(message: message, data: response.user);
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  Future<AuthResult<User?>> signInWithEmail(
    String email,
    String password,
  ) async {
    if (!isConfigured) {
      return AuthResult.failure('请先在 SupabaseConfig 中填写项目配置');
    }

    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(message: '登录成功', data: response.user);
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  Future<AuthResult<void>> signInWithPhone(String phone) async {
    if (!isConfigured) {
      return AuthResult.failure('请先在 SupabaseConfig 中填写项目配置');
    }

    try {
      await _auth.signInWithOtp(phone: phone.trim(), shouldCreateUser: true);
      return AuthResult.success(message: '验证码已发送');
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  Future<AuthResult<PhoneVerificationPayload>> verifyPhoneOtp(
    String phone,
    String otp,
  ) async {
    if (!isConfigured) {
      return AuthResult.failure('请先在 SupabaseConfig 中填写项目配置');
    }

    try {
      final response = await _auth.verifyOTP(
        phone: phone.trim(),
        token: otp.trim(),
        type: OtpType.sms,
      );
      final user = response.user ?? currentUser;
      if (user == null) {
        return AuthResult.failure('登录状态同步失败，请稍后重试');
      }

      final needsNickname = _extractNickname(user).isEmpty;
      return AuthResult.success(
        message: '登录成功',
        data: PhoneVerificationPayload(
          user: user,
          needsNickname: needsNickname,
        ),
      );
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  Future<AuthResult<User>> updateNickname(String nickname) async {
    if (!isConfigured) {
      return AuthResult.failure('请先在 SupabaseConfig 中填写项目配置');
    }

    final user = currentUser;
    if (user == null) {
      return AuthResult.failure('登录状态已失效，请重新登录');
    }

    try {
      final metadata = Map<String, dynamic>.from(user.userMetadata ?? const {});
      metadata['nickname'] = _normalizeNickname(nickname);
      final response = await _auth.updateUser(UserAttributes(data: metadata));
      final updatedUser = response.user ?? currentUser;
      if (updatedUser == null) {
        return AuthResult.failure('昵称保存失败，请稍后重试');
      }

      return AuthResult.success(message: '昵称已保存', data: updatedUser);
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  Future<AuthResult<void>> resetPassword(String email) async {
    if (!isConfigured) {
      return AuthResult.failure('请先在 SupabaseConfig 中填写项目配置');
    }

    try {
      await _auth.resetPasswordForEmail(email.trim());
      return AuthResult.success(message: '重置邮件已发送');
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  Future<AuthResult<void>> signOut() async {
    if (!isConfigured) {
      return AuthResult.success(message: '已退出登录');
    }

    try {
      await _auth.signOut();
      return AuthResult.success(message: '已退出登录');
    } on AuthException catch (error) {
      return AuthResult.failure(_mapAuthError(error.message));
    } catch (error) {
      return AuthResult.failure(_mapUnknownError(error));
    }
  }

  String _normalizeNickname(String nickname) {
    final value = nickname.trim();
    return value.isEmpty ? defaultNickname : value;
  }

  String _extractNickname(User user) {
    final value = user.userMetadata?['nickname']?.toString().trim() ?? '';
    return value;
  }

  String _mapAuthError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials')) {
      return '邮箱或密码错误';
    }
    if (lowerMessage.contains('user already registered')) {
      return '该邮箱已被注册';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return '请先验证邮箱';
    }
    if (lowerMessage.contains('password should be at least 6 characters')) {
      return '密码至少需要6个字符';
    }
    if (lowerMessage.contains('token has expired or is invalid') ||
        lowerMessage.contains('otp expired') ||
        lowerMessage.contains('otp has expired')) {
      return '验证码已过期，请重新获取';
    }
    if (lowerMessage.contains(
      'for security purposes, you can only request this after',
    )) {
      return '操作过于频繁，请稍后再试';
    }
    if (lowerMessage.contains('invalid phone number') ||
        lowerMessage.contains('unable to validate phone number')) {
      return '请输入正确的手机号（需带国际区号）';
    }
    if (_looksLikeNetworkError(lowerMessage)) {
      return '网络连接失败，请检查网络设置';
    }

    return '操作失败，请稍后重试';
  }

  String _mapUnknownError(Object error) {
    final lowerMessage = error.toString().toLowerCase();
    if (_looksLikeNetworkError(lowerMessage)) {
      return '网络连接失败，请检查网络设置';
    }
    return '操作失败，请稍后重试';
  }

  bool _looksLikeNetworkError(String message) {
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('clientexception') ||
        message.contains('connection closed') ||
        message.contains('xmlhttprequest error');
  }
}
