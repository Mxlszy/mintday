import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/journey_insights.dart';
import '../../core/utils.dart';
import '../../core/theme/app_theme.dart';
import '../../models/achievement.dart';
import '../../models/goal.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../services/share_export_service.dart';
import '../../services/user_profile_prefs.dart';
import 'pixel_share_card.dart';

/// 成就解锁后的分享半屏（含 [Screenshot] 预览 + 系统分享）。
Future<void> showAchievementShareSheet(
  BuildContext context, {
  required List<AchievementId> achievementIds,
}) async {
  if (achievementIds.isEmpty) return;

  final nickname = await UserProfilePrefs.getNickname();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AchievementShareSheetBody(
      nickname: nickname,
      achievementIds: achievementIds,
    ),
  );
}

class _AchievementShareSheetBody extends StatefulWidget {
  final String nickname;
  final List<AchievementId> achievementIds;

  const _AchievementShareSheetBody({
    required this.nickname,
    required this.achievementIds,
  });

  @override
  State<_AchievementShareSheetBody> createState() =>
      _AchievementShareSheetBodyState();
}

class _AchievementShareSheetBodyState extends State<_AchievementShareSheetBody> {
  final _shot = ScreenshotController();
  bool _capturing = false;

  Future<void> _sharePng() async {
    if (_capturing) return;
    if (kIsWeb) {
      AppUtils.showSnackBar(
        context,
        'Web 端暂不支持图片分享，请使用 Android / iOS / 桌面客户端。',
        isError: true,
      );
      return;
    }
    setState(() => _capturing = true);
    try {
      final bytes = await _shot.capture(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
        delay: const Duration(milliseconds: 120),
      );
      if (!mounted || bytes == null) return;
      await ShareExportService.sharePngBytes(
        bytes,
        'mintday_achievement_${DateTime.now().millisecondsSinceEpoch}',
        text: '我在 MintDay 解锁了新成就',
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.read<GoalProvider>();
    final checkInProvider = context.read<CheckInProvider>();
    final goals = goalProvider.goals;
    final maxStreak = _maxStreak(checkInProvider, goals);
    final badges = buildCollectibleBadges(
      goals: goals,
      checkIns: checkInProvider.checkIns,
      maxStreak: maxStreak,
    );
    final unlocked = badges.where((b) => b.unlocked).length;

    final titles = widget.achievementIds
        .map((id) => AchievementCatalog.byId[id]?.title ?? id.name)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        bottom: AppTheme.spacingL + MediaQuery.paddingOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: AppTheme.spacingM),
            Text('解锁成就 · 分享卡片', style: AppTextStyle.h3),
            const SizedBox(height: 6),
            Text(
              '已解锁 ${widget.achievementIds.length} 项，可生成图片分享到其他 App。',
              style: AppTextStyle.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Center(
              child: Screenshot(
                controller: _shot,
                child: PixelShareCard(
                  nickname: widget.nickname,
                  maxStreakDays: maxStreak,
                  totalRecords: checkInProvider.checkIns.length,
                  unlockedBadgeCount: unlocked,
                  highlightLines: titles,
                  headline: '新成就解锁',
                  footer:
                      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} · MintDay',
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('稍后再说'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _capturing ? null : _sharePng,
                    child: _capturing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('生成并分享'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _maxStreak(CheckInProvider p, List<Goal> goals) {
    var m = 0;
    for (final g in goals) {
      final s = p.getStreak(g.id);
      if (s > m) m = s;
    }
    return m;
  }
}

/// 主控台「状态分享」半屏。
Future<void> showStatusShareSheet(BuildContext context) async {
  final nickname = await UserProfilePrefs.getNickname();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StatusShareSheetBody(nickname: nickname),
  );
}

class _StatusShareSheetBody extends StatefulWidget {
  final String nickname;

  const _StatusShareSheetBody({required this.nickname});

  @override
  State<_StatusShareSheetBody> createState() => _StatusShareSheetBodyState();
}

class _StatusShareSheetBodyState extends State<_StatusShareSheetBody> {
  final _shot = ScreenshotController();
  bool _capturing = false;

  Future<void> _sharePng() async {
    if (_capturing) return;
    if (kIsWeb) {
      AppUtils.showSnackBar(
        context,
        'Web 端暂不支持图片分享，请使用 Android / iOS / 桌面客户端。',
        isError: true,
      );
      return;
    }
    setState(() => _capturing = true);
    try {
      final bytes = await _shot.capture(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
        delay: const Duration(milliseconds: 120),
      );
      if (!mounted || bytes == null) return;
      await ShareExportService.sharePngBytes(
        bytes,
        'mintday_status_${DateTime.now().millisecondsSinceEpoch}',
        text: '我的 MintDay 打卡状态',
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.read<GoalProvider>();
    final checkInProvider = context.read<CheckInProvider>();
    final goals = goalProvider.goals;
    final maxStreak = _maxStreak(checkInProvider, goals);
    final badges = buildCollectibleBadges(
      goals: goals,
      checkIns: checkInProvider.checkIns,
      maxStreak: maxStreak,
    );
    final unlockedTitles = badges
        .where((b) => b.unlocked)
        .take(4)
        .map((b) => b.title)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        bottom: AppTheme.spacingL + MediaQuery.paddingOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: AppTheme.spacingM),
            Text('分享我的打卡状态', style: AppTextStyle.h3),
            const SizedBox(height: AppTheme.spacingM),
            Center(
              child: Screenshot(
                controller: _shot,
                child: PixelShareCard(
                  nickname: widget.nickname,
                  maxStreakDays: maxStreak,
                  totalRecords: checkInProvider.checkIns.length,
                  unlockedBadgeCount: badges.where((b) => b.unlocked).length,
                  highlightLines: unlockedTitles,
                  headline: '打卡成就',
                  footer:
                      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} · MintDay',
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _capturing ? null : _sharePng,
                    child: _capturing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('生成并分享'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _maxStreak(CheckInProvider p, List<Goal> goals) {
    var m = 0;
    for (final g in goals) {
      final s = p.getStreak(g.id);
      if (s > m) m = s;
    }
    return m;
  }
}
