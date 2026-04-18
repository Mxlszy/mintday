import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../providers/auth_provider.dart';
import 'auth_shared.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  late final TextEditingController _loginEmailController;
  late final TextEditingController _loginPasswordController;
  late final TextEditingController _registerNicknameController;
  late final TextEditingController _registerEmailController;
  late final TextEditingController _registerPasswordController;
  late final TextEditingController _confirmPasswordController;

  int _selectedTab = 0;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmittingLogin = false;
  bool _isSubmittingRegister = false;

  @override
  void initState() {
    super.initState();
    _loginEmailController = TextEditingController();
    _loginPasswordController = TextEditingController();
    _registerNicknameController = TextEditingController();
    _registerEmailController = TextEditingController();
    _registerPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNicknameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (!_isValidEmail(email)) {
      AppUtils.showSnackBar(context, '请输入正确的邮箱地址', isError: true);
      return;
    }
    if (password.isEmpty) {
      AppUtils.showSnackBar(context, '请输入密码', isError: true);
      return;
    }

    setState(() => _isSubmittingLogin = true);
    final result = await context.read<AuthProvider>().signInWithEmail(
      email,
      password,
    );
    if (!mounted) return;

    setState(() => _isSubmittingLogin = false);
    if (!result.isSuccess) {
      AppUtils.showSnackBar(context, result.message, isError: true);
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submitRegister() async {
    final nickname = _registerNicknameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (nickname.isEmpty) {
      AppUtils.showSnackBar(context, '请输入昵称', isError: true);
      return;
    }
    if (!_isValidEmail(email)) {
      AppUtils.showSnackBar(context, '请输入正确的邮箱地址', isError: true);
      return;
    }
    if (password.length < 6) {
      AppUtils.showSnackBar(context, '密码至少需要6个字符', isError: true);
      return;
    }
    if (password != confirmPassword) {
      AppUtils.showSnackBar(context, '两次输入的密码不一致', isError: true);
      return;
    }

    setState(() => _isSubmittingRegister = true);
    final result = await context.read<AuthProvider>().signUpWithEmail(
      email,
      password,
      nickname,
    );
    if (!mounted) return;

    setState(() => _isSubmittingRegister = false);
    if (!result.isSuccess) {
      AppUtils.showSnackBar(context, result.message, isError: true);
      return;
    }

    AppUtils.showSnackBar(context, result.message);
    if (context.read<AuthProvider>().status == AuthStatus.authenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _selectedTab = 0);
  }

  Future<void> _showResetPasswordDialog() async {
    final controller = TextEditingController(text: _loginEmailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('重置密码'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: buildAuthInputDecoration(hintText: '请输入邮箱'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('发送邮件'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || email == null) return;
    if (!_isValidEmail(email)) {
      AppUtils.showSnackBar(context, '请输入正确的邮箱地址', isError: true);
      return;
    }

    final result = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    AppUtils.showSnackBar(
      context,
      result.message,
      isError: !result.isSuccess,
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      appBar: AppBar(title: const Text('邮箱登录')),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingXL,
          ),
          child: Column(
            children: [
              AuthPillSwitch(
                labels: const ['登录', '注册'],
                selectedIndex: _selectedTab,
                onChanged: (value) => setState(() => _selectedTab = value),
              ),
              const SizedBox(height: AppTheme.spacingL),
              AuthCard(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _selectedTab == 0
                      ? _buildLoginTab()
                      : _buildRegisterTab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      key: const ValueKey('login-tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('欢迎回来', style: AppTextStyle.h2),
        const SizedBox(height: AppTheme.spacingS),
        Text('使用邮箱和密码继续你的 MintDay 旅程。', style: AppTextStyle.bodySmall),
        const SizedBox(height: AppTheme.spacingL),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: buildAuthInputDecoration(hintText: '邮箱地址'),
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          decoration: buildAuthInputDecoration(
            hintText: '密码',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showResetPasswordDialog,
            child: const Text('忘记密码？'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmittingLogin ? null : _submitLogin,
            child: _isSubmittingLogin
                ? const ButtonLoader()
                : const Text('登录'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    return Column(
      key: const ValueKey('register-tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('创建账号', style: AppTextStyle.h2),
        const SizedBox(height: AppTheme.spacingS),
        Text('注册后即可在新设备上同步你的进度与成就。', style: AppTextStyle.bodySmall),
        const SizedBox(height: AppTheme.spacingL),
        TextField(
          controller: _registerNicknameController,
          decoration: buildAuthInputDecoration(hintText: '给自己取个名字吧'),
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: buildAuthInputDecoration(hintText: '邮箱地址'),
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _registerPasswordController,
          obscureText: _obscureRegisterPassword,
          decoration: buildAuthInputDecoration(
            hintText: '至少6位',
            suffixIcon: IconButton(
              onPressed: () {
                setState(
                  () =>
                      _obscureRegisterPassword = !_obscureRegisterPassword,
                );
              },
              icon: Icon(
                _obscureRegisterPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: buildAuthInputDecoration(
            hintText: '确认密码',
            suffixIcon: IconButton(
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmittingRegister ? null : _submitRegister,
            child: _isSubmittingRegister
                ? const ButtonLoader()
                : const Text('注册'),
          ),
        ),
      ],
    );
  }
}
