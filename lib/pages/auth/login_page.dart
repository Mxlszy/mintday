import 'package:flutter/material.dart';

import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'auth_shared.dart';
import 'email_login_page.dart';
import 'phone_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _agreedToLegal = false;

  void _openPhoneLogin() {
    if (!_ensureLegalAccepted()) return;
    Navigator.of(context).push(fadeSlideRoute(const PhoneLoginPage()));
  }

  void _openEmailLogin() {
    if (!_ensureLegalAccepted()) return;
    Navigator.of(context).push(fadeSlideRoute(const EmailLoginPage()));
  }

  bool _ensureLegalAccepted() {
    if (_agreedToLegal) return true;
    AppUtils.showSnackBar(context, '请先同意用户协议', isError: true);
    return false;
  }

  Future<void> _showLegalDialog(String title) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            '$title内容请在正式上线前替换为最终版本。',
            style: AppTextStyle.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: AuthGradientScaffold(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingXL,
              AppTheme.spacingL,
              bottomInset + AppTheme.spacingL,
            ),
            child: Column(
              children: [
                const Spacer(),
                const AuthHeroIcon(icon: PixelIcons.sprout),
                const SizedBox(height: AppTheme.spacingXXL),
                Text(
                  'MintDay',
                  style: AppTextStyle.h1.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  '记录成长，铸造勋章',
                  style: AppTextStyle.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(flex: 2),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openPhoneLogin,
                        child: const Text('手机号登录'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _openEmailLogin,
                        child: const Text('邮箱登录'),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToLegal,
                      onChanged: (value) {
                        setState(() => _agreedToLegal = value ?? false);
                      },
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('我已阅读并同意', style: AppTextStyle.bodySmall),
                          TextButton(
                            onPressed: () => _showLegalDialog('用户协议'),
                            child: const Text('用户协议'),
                          ),
                          Text('和', style: AppTextStyle.bodySmall),
                          TextButton(
                            onPressed: () => _showLegalDialog('隐私政策'),
                            child: const Text('隐私政策'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
