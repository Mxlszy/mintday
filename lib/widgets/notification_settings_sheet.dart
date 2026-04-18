import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/notification_service.dart';

void showNotificationSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const NotificationSettingsSheet(),
  );
}

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = NotificationService.instance;
    final enabled = await svc.isEnabled();
    final time = await svc.getSavedTime();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _time = time;
        _loading = false;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    final svc = NotificationService.instance;
    if (value) {
      await svc.requestPermission();
      await svc.enableReminder(_time);
    } else {
      await svc.disableReminder();
    }
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
    if (_enabled) {
      await NotificationService.instance.enableReminder(_time);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        AppTheme.spacingL + MediaQuery.of(context).padding.bottom,
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
          Text('每日打卡提醒', style: AppTextStyle.h3),
          const SizedBox(height: 6),
          Text('在指定时间发送系统通知，避免忘记打卡而中断连续记录。', style: AppTextStyle.bodySmall),
          const SizedBox(height: AppTheme.spacingL),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('开启提醒', style: AppTextStyle.body),
                Switch(
                  value: _enabled,
                  onChanged: _toggleEnabled,
                  activeThumbColor: AppTheme.surface,
                  activeTrackColor: AppTheme.primary,
                ),
              ],
            ),
            if (_enabled) ...[
              const SizedBox(height: AppTheme.spacingM),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('提醒时间', style: AppTextStyle.body),
                      Text(
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyle.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
