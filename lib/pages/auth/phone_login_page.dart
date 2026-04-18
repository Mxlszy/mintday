import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'auth_shared.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  static const _dialCodes = <_DialCodeOption>[
    _DialCodeOption(label: '+86', name: '中国大陆'),
    _DialCodeOption(label: '+1', name: '美国/加拿大'),
    _DialCodeOption(label: '+81', name: '日本'),
    _DialCodeOption(label: '+82', name: '韩国'),
    _DialCodeOption(label: '+852', name: '中国香港'),
    _DialCodeOption(label: '+886', name: '中国台湾'),
  ];

  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;

  String _selectedDialCode = '+86';
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  bool _didAutoSubmitOtp = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedDialCode${_phoneController.text.trim()}';

  bool _validatePhone() {
    final value = _phoneController.text.trim();
    if (value.isEmpty || value.length < 5) {
      AppUtils.showSnackBar(context, '请输入正确的手机号', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _requestCode() async {
    if (_isSendingCode || !_validatePhone()) return;

    setState(() => _isSendingCode = true);
    final result = await context.read<AuthProvider>().signInWithPhone(
      _fullPhoneNumber,
    );
    if (!mounted) return;

    setState(() => _isSendingCode = false);
    if (!result.isSuccess) {
      AppUtils.showSnackBar(context, result.message, isError: true);
      return;
    }

    AppUtils.showSnackBar(context, result.message);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  void _handleOtpChanged(String value) {
    if (value.length < 6) {
      _didAutoSubmitOtp = false;
      return;
    }
    if (_didAutoSubmitOtp || _isVerifying) return;

    _didAutoSubmitOtp = true;
    _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying || !_validatePhone()) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppUtils.showSnackBar(context, '请输入6位验证码', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    final result = await context.read<AuthProvider>().verifyPhoneOtp(
      _fullPhoneNumber,
      otp,
    );
    if (!mounted) return;

    setState(() => _isVerifying = false);
    if (!result.isSuccess || result.data == null) {
      AppUtils.showSnackBar(context, result.message, isError: true);
      return;
    }

    if (result.data!.needsNickname) {
      final nicknameSaved = await _promptNickname();
      if (!mounted || !nicknameSaved) return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<bool> _promptNickname() async {
    final controller = TextEditingController(text: AuthService.defaultNickname);
    final nickname = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('设置昵称'),
          content: TextField(
            controller: controller,
            maxLength: 20,
            autofocus: true,
            decoration: buildAuthInputDecoration(hintText: 'MintDay 旅人'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted) return false;
    final result = await context.read<AuthProvider>().updateNickname(
      nickname?.trim().isNotEmpty == true
          ? nickname!.trim()
          : AuthService.defaultNickname,
    );

    if (!mounted) return false;
    if (!result.isSuccess) {
      AppUtils.showSnackBar(context, result.message, isError: true);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      appBar: AppBar(title: const Text('手机号登录')),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingXL,
          ),
          child: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('验证码登录', style: AppTextStyle.h2),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  '输入带国际区号的手机号，验证码会通过短信发送。',
                  style: AppTextStyle.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Row(
                  children: [
                    SizedBox(
                      width: 122,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDialCode,
                        decoration: buildAuthInputDecoration(hintText: '区号'),
                        items: _dialCodes.map((option) {
                          return DropdownMenuItem<String>(
                            value: option.label,
                            child: Text(option.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedDialCode = value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: buildAuthInputDecoration(hintText: '手机号'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 6,
                        onChanged: _handleOtpChanged,
                        decoration: buildAuthInputDecoration(hintText: '6位验证码'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    SizedBox(
                      width: 124,
                      height: 56,
                      child: _countdown > 0
                          ? Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                '${_countdown}s 后重新获取',
                                textAlign: TextAlign.center,
                                style: AppTextStyle.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: _isSendingCode ? null : _requestCode,
                              child: _isSendingCode
                                  ? ButtonLoader(color: AppTheme.primary)
                                  : const Text('获取验证码'),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    child: _isVerifying
                        ? const ButtonLoader()
                        : const Text('登录'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialCodeOption {
  const _DialCodeOption({required this.label, required this.name});

  final String label;
  final String name;
}
