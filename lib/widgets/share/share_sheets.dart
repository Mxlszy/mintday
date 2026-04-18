import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/journey_insights.dart';
import '../../core/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/achievement.dart';
import '../../models/goal.dart';
import '../../models/nft_asset.dart';
import '../../pages/wallet/nft_detail_page.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/nft_provider.dart';
import '../../services/share_export_service.dart';
import '../../services/user_profile_prefs.dart';
import 'pixel_share_card.dart';

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
    builder: (_) => _AchievementShareSheetBody(
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

class _AchievementShareSheetBodyState
    extends State<_AchievementShareSheetBody> {
  final _shot = ScreenshotController();
  bool _capturing = false;
  bool _minting = false;

  Future<void> _sharePng() async {
    if (_capturing) return;
    if (kIsWeb) {
      AppUtils.showSnackBar(
        context,
        'Web 端暂不支持图片分享，请使用 Android、iOS 或桌面端。',
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
        text: '我在 MintDay 解锁了新的成就',
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _mintAchievementNft() async {
    if (_minting) return;
    setState(() => _minting = true);

    final ids = [...widget.achievementIds]
      ..sort((a, b) => a.name.compareTo(b.name));
    final titles = ids
        .map((id) => AchievementCatalog.byId[id]?.title ?? id.name)
        .toList();
    final single = ids.length == 1 ? AchievementCatalog.byId[ids.first] : null;

    final asset = await context.read<NftProvider>().generateNftCard(
      single?.title ?? '连锁成就解锁',
      single?.subtitle ??
          '一次点亮 ${ids.length} 项成就：${titles.take(2).join('、')}${ids.length > 2 ? ' 等' : ''}',
      NftCategory.achievement,
      ids.map((id) => id.name).join(','),
    );

    if (!mounted) return;
    setState(() => _minting = false);

    if (asset == null) {
      AppUtils.showSnackBar(context, '生成 NFT 卡片失败，请稍后重试', isError: true);
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(sharedAxisRoute(NftDetailPage(assetId: asset.id)));
    });
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
      child: _SheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AppTheme.spacingM),
            Text('成就解锁 · 分享卡片', style: AppTextStyle.h3),
            const SizedBox(height: 6),
            Text(
              '已解锁 ${widget.achievementIds.length} 项成就，可以直接分享，也可以顺手铸造成 NFT 纪念卡。',
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
            OutlinedButton(
              onPressed: (_capturing || _minting) ? null : _mintAchievementNft,
              child: _minting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('铸造为 NFT'),
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
                    onPressed: (_capturing || _minting) ? null : _sharePng,
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

  int _maxStreak(CheckInProvider provider, List<Goal> goals) {
    var maxValue = 0;
    for (final goal in goals) {
      final streak = provider.getStreak(goal.id);
      if (streak > maxValue) maxValue = streak;
    }
    return maxValue;
  }
}

Future<void> showStatusShareSheet(BuildContext context) async {
  final nickname = await UserProfilePrefs.getNickname();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StatusShareSheetBody(nickname: nickname),
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
        'Web 端暂不支持图片分享，请使用 Android、iOS 或桌面端。',
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
        text: '这是我的 MintDay 打卡状态',
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
        .where((badge) => badge.unlocked)
        .take(4)
        .map((badge) => badge.title)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        bottom: AppTheme.spacingL + MediaQuery.paddingOf(context).bottom,
      ),
      child: _SheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
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
                  unlockedBadgeCount: badges
                      .where((badge) => badge.unlocked)
                      .length,
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

  int _maxStreak(CheckInProvider provider, List<Goal> goals) {
    var maxValue = 0;
    for (final goal in goals) {
      final streak = provider.getStreak(goal.id);
      if (streak > maxValue) maxValue = streak;
    }
    return maxValue;
  }
}

class _SheetContainer extends StatelessWidget {
  final Widget child;

  const _SheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
