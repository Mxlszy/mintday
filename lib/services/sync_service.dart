import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../core/theme/app_theme.dart';
import '../core/utils.dart';
import 'database_service.dart';
import 'user_profile_prefs.dart';

class SyncService {
  SyncService._();

  static final ValueNotifier<double> syncProgress = ValueNotifier<double>(0);

  static Future<bool> checkLocalData() async {
    final db = await DatabaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM goals');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  static Future<void> showSyncDialog(BuildContext context) async {
    final userId = SupabaseConfig.isConfigured
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    if (userId == null) return;

    final synced = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SyncDialog(userId: userId),
    );

    if (!context.mounted || synced != true) return;
    AppUtils.showSnackBar(context, '本地数据同步完成');
  }

  static Future<void> syncLocalDataToCloud(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('请先在 SupabaseConfig 中填写项目配置');
    }

    final client = Supabase.instance.client;
    final db = await DatabaseService.database;

    final goals = await db.query('goals');
    final checkIns = await db.query('check_ins');
    final nftAssets = await db.query('nft_assets');
    final achievementUnlocks = await db.query('achievement_unlocks');

    final tasks = <Future<void> Function()>[
      () => _upsertRows(client, 'goals', goals, userId),
      () => _upsertRows(client, 'check_ins', checkIns, userId),
      () => _upsertRows(client, 'nft_assets', nftAssets, userId),
      () => _upsertRows(
        client,
        'achievement_unlocks',
        achievementUnlocks,
        userId,
      ),
    ];

    syncProgress.value = 0;
    for (var index = 0; index < tasks.length; index++) {
      await tasks[index]();
      syncProgress.value = (index + 1) / tasks.length;
    }

    await UserProfilePrefs.setSyncedToCloud(true);
  }

  static Future<void> _upsertRows(
    SupabaseClient client,
    String tableName,
    List<Map<String, Object?>> rows,
    String userId,
  ) async {
    if (rows.isEmpty) return;

    final payload = rows.map((row) {
      return <String, dynamic>{
        ...row,
        'user_id': userId,
      };
    }).toList();

    // TODO: Finalize each PostgreSQL table schema in Supabase Dashboard and
    // refine field mapping or switch to RPC once the cloud model is settled.
    await client.from(tableName).upsert(payload);
  }
}

class _SyncDialog extends StatefulWidget {
  const _SyncDialog({required this.userId});

  final String userId;

  @override
  State<_SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<_SyncDialog> {
  bool _isSyncing = false;
  String? _errorMessage;

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      await SyncService.syncLocalDataToCloud(widget.userId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('同步本地数据'),
      content: ValueListenableBuilder<double>(
        valueListenable: SyncService.syncProgress,
        builder: (context, progress, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '检测到本地历史数据，是否同步到云端？',
                style: AppTextStyle.bodySmall,
              ),
              const SizedBox(height: AppTheme.spacingM),
              if (_isSyncing) ...[
                LinearProgressIndicator(value: progress),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  '同步进度 ${(progress * 100).toInt()}%',
                  style: AppTextStyle.caption,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  _errorMessage!,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isSyncing ? null : () => Navigator.of(context).pop(false),
          child: const Text('暂不同步'),
        ),
        ElevatedButton(
          onPressed: _isSyncing ? null : _handleSync,
          child: _isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('立即同步'),
        ),
      ],
    );
  }
}
