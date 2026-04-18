import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/neumorphic.dart';
import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../avatar/avatar_editor_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/share_export_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/notification_settings_sheet.dart';
import '../../widgets/user_profile_header.dart';
import '../history/history_page.dart';
import '../progress/progress_page.dart';
import '../social/friends_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        top: false,
        child:
            Consumer4<
              UserProfileProvider,
              ShareExportProvider,
              AuthProvider,
              FriendProvider
            >(
              builder: (context, userProfile, shareExport, auth, friend, _) {
                final maskedIdentity = _maskedIdentity(auth.user);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                    120,
                  ),
                  children: [
                    UserProfileHeader(
                      profile: userProfile.profile,
                      dateLabel: AppUtils.fullFriendlyDate(DateTime.now()),
                      onAvatarTap: () => _openAvatarEditor(context),
                    ),
                    if (maskedIdentity != null) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      _AuthIdentityCard(identity: maskedIdentity),
                    ],
                    const SizedBox(height: AppTheme.spacingXL),
                    const _SectionTitle(eyebrow: 'PERSONA', title: '账号与资料'),
                    const SizedBox(height: AppTheme.spacingM),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: PixelIcons.star,
                          title: '用户昵称',
                          subtitle: userProfile.profile.nickname,
                          onTap: () => _editNickname(
                            context,
                            userProfile.profile.nickname,
                          ),
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: PixelIcons.pencil,
                          title: '编辑形象',
                          subtitle: userProfile.profile.avatarConfig == null
                              ? '创建你的像素虚拟形象'
                              : '调整发型、五官和配饰',
                          onTap: () => _openAvatarEditor(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    const _SectionTitle(eyebrow: 'SOCIAL', title: '好友与社交'),
                    const SizedBox(height: AppTheme.spacingM),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: PixelIcons.heart,
                          title: '我的好友',
                          subtitle: '已经连接 ${friend.friendCount} 位一起坚持的小伙伴',
                          onTap: () => _openFriendsPage(context),
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: PixelIcons.note,
                          title: '我的 ID',
                          subtitle: friend.currentUserId,
                          trailing: Icon(
                            Icons.copy_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onTap: () =>
                              _copyFriendId(context, friend.currentUserId),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    const _SectionTitle(eyebrow: 'ARCHIVE', title: '旅程回看'),
                    const SizedBox(height: AppTheme.spacingM),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: PixelIcons.book,
                          title: '历史卷轴',
                          subtitle: '按日期查看打卡、情绪和记录',
                          onTap: () => Navigator.of(context).push(
                            sharedAxisRoute(
                              const HistoryPage(showAppBar: true),
                            ),
                          ),
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: PixelIcons.chart,
                          title: '成长图鉴',
                          subtitle: '查看进度、徽章和年度概览',
                          onTap: () => Navigator.of(context).push(
                            sharedAxisRoute(
                              const ProgressPage(showAppBar: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    const _SectionTitle(eyebrow: 'SETTINGS', title: '应用设置'),
                    const SizedBox(height: AppTheme.spacingM),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: PixelIcons.clock,
                          title: '通知设置',
                          subtitle: '调整每日提醒时间与开关',
                          onTap: () => showNotificationSettingsSheet(context),
                        ),
                        const _SettingsDivider(),
                        _ToggleSettingsTile(
                          icon: PixelIcons.moon,
                          title: '深色模式',
                          subtitle: '切换更沉浸的夜间界面',
                          value: userProfile.isDarkMode,
                          onChanged: (value) => _toggleDarkMode(context, value),
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: PixelIcons.note,
                          title: '数据导出',
                          subtitle: '导出打卡 CSV 数据',
                          trailing: shareExport.isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onTap: shareExport.isBusy
                              ? null
                              : () => _showExportSheet(context),
                        ),
                        const _SettingsDivider(),
                        const _VersionTile(),
                      ],
                    ),
                    if (auth.status == AuthStatus.authenticated) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: PixelIcons.lock,
                            title: '退出登录',
                            subtitle: '退出当前账号并返回登录页',
                            iconBackgroundColor: AppTheme.error.withValues(
                              alpha: AppTheme.isDarkMode ? 0.22 : 0.12,
                            ),
                            iconColor: AppTheme.error,
                            onTap: () => _confirmSignOut(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
      ),
    );
  }

  Future<void> _editNickname(
    BuildContext context,
    String currentNickname,
  ) async {
    final userProfileProvider = context.read<UserProfileProvider>();
    final nextValue = await showDialog<String>(
      context: context,
      builder: (_) => _EditNicknameDialog(initialValue: currentNickname),
    );

    if (nextValue == null) return;

    final success = await userProfileProvider.updateNickname(nextValue);
    if (!context.mounted) return;

    AppUtils.showSnackBar(
      context,
      success ? '昵称已更新' : '昵称保存失败，请稍后重试',
      isError: !success,
    );
  }

  void _openAvatarEditor(BuildContext context) {
    Navigator.of(context).push(fadeSlideRoute(const AvatarEditorPage()));
  }

  void _openFriendsPage(BuildContext context) {
    Navigator.of(context).push(sharedAxisRoute(const FriendsPage()));
  }

  Future<void> _copyFriendId(BuildContext context, String friendId) async {
    await Clipboard.setData(ClipboardData(text: friendId));
    if (!context.mounted) return;
    AppUtils.showSnackBar(context, '好友 ID 已复制');
  }

  Future<void> _toggleDarkMode(BuildContext context, bool value) async {
    final userProfileProvider = context.read<UserProfileProvider>();
    final success = await userProfileProvider.setDarkMode(value);
    if (!context.mounted || success) return;

    AppUtils.showSnackBar(context, '深色模式保存失败，请稍后重试', isError: true);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: Text('确认要退出当前账号吗？', style: AppTextStyle.bodySmall),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !context.mounted) return;

    final result = await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    AppUtils.showSnackBar(context, result.message, isError: !result.isSuccess);
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_ExportAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final currentYear = DateTime.now().year;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingM,
            AppTheme.spacingL,
            AppTheme.spacingL + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text('导出数据', style: AppTextStyle.h3),
              const SizedBox(height: 6),
              Text('选择要导出的打卡范围，文件格式为 CSV。', style: AppTextStyle.bodySmall),
              const SizedBox(height: AppTheme.spacingL),
              _BottomSheetAction(
                title: '导出 $currentYear 年记录',
                subtitle: '仅导出本自然年的打卡数据',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ExportAction.currentYear),
              ),
              const SizedBox(height: AppTheme.spacingS),
              _BottomSheetAction(
                title: '导出全部记录',
                subtitle: '导出当前设备中的全部打卡数据',
                onTap: () => Navigator.of(sheetContext).pop(_ExportAction.all),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    final shareExport = context.read<ShareExportProvider>();
    switch (action) {
      case _ExportAction.currentYear:
        await shareExport.shareYearCheckInsCsv(context, DateTime.now().year);
        break;
      case _ExportAction.all:
        await shareExport.shareAllCheckInsCsv(context);
        break;
    }
  }

  String? _maskedIdentity(User? user) {
    if (user == null) return null;

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return _maskEmail(email);
    }

    final phone = user.phone?.trim();
    if (phone != null && phone.isNotEmpty) {
      return _maskPhone(phone);
    }

    return null;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final local = parts.first;
    final domain = parts.last;
    if (local.length <= 2) {
      return '${local[0]}***@$domain';
    }
    return '${local.substring(0, 2)}***@$domain';
  }

  String _maskPhone(String phone) {
    final normalized = phone.replaceAll(' ', '');
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return normalized;

    final prefix = normalized.startsWith('+')
        ? '+${digits.substring(0, digits.length - 11)} '
        : '';
    final national = digits.length > 11
        ? digits.substring(digits.length - 11)
        : digits;
    return '$prefix${national.substring(0, 3)}****${national.substring(national.length - 4)}';
  }
}

enum _ExportAction { currentYear, all }

class _AuthIdentityCard extends StatelessWidget {
  const _AuthIdentityCard({required this.identity});

  final String identity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: PixelIcon(
                icon: PixelIcons.lock,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前登录', style: AppTextStyle.caption),
                const SizedBox(height: 4),
                Text(identity, style: AppTextStyle.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditNicknameDialog extends StatefulWidget {
  const _EditNicknameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<_EditNicknameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑昵称'),
      content: TextField(
        controller: _controller,
        maxLength: 20,
        autofocus: true,
        decoration: const InputDecoration(hintText: '输入昵称，留空将恢复默认称呼'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTextStyle.label),
        const SizedBox(height: 6),
        Text(title, style: AppTextStyle.h2),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final PixelIconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Center(
                  child: PixelIcon(
                    icon: icon,
                    size: 18,
                    color: iconColor ?? AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyle.body),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AppTextStyle.bodySmall),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: onTap == null
                        ? AppTheme.textHint
                        : AppTheme.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSettingsTile extends StatelessWidget {
  const _ToggleSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final PixelIconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Center(
                  child: PixelIcon(
                    icon: icon,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyle.body),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyle.bodySmall),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '读取中...';

        return _SettingsTile(
          icon: PixelIcons.diamond,
          title: 'App 版本',
          subtitle: '当前安装版本',
          trailing: Text(version, style: AppTextStyle.caption),
        );
      },
    );
  }
}

class _BottomSheetAction extends StatelessWidget {
  const _BottomSheetAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      borderRadius: AppTheme.radiusM,
      onTap: onTap,
      child: Row(
        children: [
          PixelIcon(icon: PixelIcons.note, size: 18, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.body),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyle.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
