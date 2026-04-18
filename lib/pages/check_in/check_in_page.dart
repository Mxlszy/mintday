import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../wallet/mint_nft_page.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/social_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/local_image_preview.dart';
import '../../widgets/milestone_celebration.dart';
import '../../widgets/mood_selector.dart';

class CheckInPage extends StatefulWidget {
  final String goalId;
  final CheckInMode initialMode;

  const CheckInPage({
    super.key,
    required this.goalId,
    this.initialMode = CheckInMode.quick,
  });

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  static const _maxImages = 3;

  final _noteController = TextEditingController();
  final _progressController = TextEditingController();
  final _blockerController = TextEditingController();
  final _nextController = TextEditingController();
  final _picker = ImagePicker();

  late CheckInMode _mode;
  CheckInStatus _status = CheckInStatus.done;
  int? _mood;
  int? _duration;
  final List<String> _selectedImagePaths = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _progressController.dispose();
    _blockerController.dispose();
    _nextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = context.read<GoalProvider>().getGoalById(widget.goalId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('记录今天')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          120,
        ),
        children: [
          _HeaderCard(goalTitle: goal?.title ?? '今日记录'),
          const SizedBox(height: AppTheme.spacingL),
          _SectionCard(label: '打卡模式', child: _buildModeSelector()),
          const SizedBox(height: AppTheme.spacingL),
          _SectionCard(label: '完成状态', child: _buildStatusSelector()),
          const SizedBox(height: AppTheme.spacingL),
          _SectionCard(label: '今天的感觉', child: _buildMoodSection()),
          const SizedBox(height: AppTheme.spacingL),
          if (_mode == CheckInMode.quick)
            _SectionCard(
              label: '简短记录',
              hint: '选填',
              child: _buildQuickContent(),
            ),
          if (_mode == CheckInMode.reflection) _buildReflectionContent(),
          const SizedBox(height: AppTheme.spacingL),
          _SectionCard(
            label: '图片证据',
            hint: '${_selectedImagePaths.length}/$_maxImages',
            child: _buildImageSection(),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _SectionCard(
            label: '投入时长',
            hint: '选填',
            child: _buildDurationPicker(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            0,
            AppTheme.spacingL,
            AppTheme.spacingL,
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('提交打卡'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: CheckInMode.values.map((mode) {
        final isSelected = _mode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode == CheckInMode.quick ? AppTheme.spacingS : 0,
            ),
            child: _PillButton(
              label: mode.label,
              selected: isSelected,
              onTap: () => setState(() => _mode = mode),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: CheckInStatus.values.map((status) {
        final isSelected = _status == status;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: status != CheckInStatus.skipped ? AppTheme.spacingS : 0,
            ),
            child: _PillButton(
              label: status.label,
              selected: isSelected,
              onTap: () => setState(() => _status = status),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodSection() {
    return MoodSelector(
      selected: _mood,
      onChanged: (value) => setState(() => _mood = value),
    );
  }

  Widget _buildQuickContent() {
    return TextField(
      controller: _noteController,
      decoration: const InputDecoration(hintText: '今天做了什么，或者想给今天留下一句话'),
      style: AppTextStyle.body,
      maxLines: 4,
      maxLength: 500,
    );
  }

  Widget _buildReflectionContent() {
    return Column(
      children: [
        _SectionCard(
          label: '今天最小的推进',
          hint: '选填',
          child: TextField(
            controller: _progressController,
            decoration: const InputDecoration(hintText: '例如：把第 3 节课程看完了'),
            style: AppTextStyle.body,
            maxLines: 3,
            maxLength: 300,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        _SectionCard(
          label: '遇到的阻碍',
          hint: '选填',
          child: TextField(
            controller: _blockerController,
            decoration: const InputDecoration(hintText: '例如：下班太晚，精力不够'),
            style: AppTextStyle.body,
            maxLines: 2,
            maxLength: 200,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        _SectionCard(
          label: '下一步想推进什么',
          hint: '选填',
          child: TextField(
            controller: _nextController,
            decoration: const InputDecoration(hintText: '例如：明天先完成 4 个单词卡片'),
            style: AppTextStyle.body,
            maxLines: 2,
            maxLength: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final isSupported = StorageService.supportsPersistentImages;
    final canAddMore = _selectedImagePaths.length < _maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSupported
              ? '可以附上截图、照片或证据图片。'
              : '当前平台暂不支持本地图片保存，建议在 Windows 或 Android 上使用。',
          style: AppTextStyle.caption,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: [
            ..._selectedImagePaths.asMap().entries.map((entry) {
              return _SelectedImageTile(
                imagePath: entry.value,
                onRemove: _isSubmitting
                    ? null
                    : () => _removeImageAt(entry.key),
              );
            }),
            if (isSupported && canAddMore)
              _AddImageTile(
                remainingCount: _maxImages - _selectedImagePaths.length,
                onTap: _isSubmitting ? null : _pickImages,
              ),
          ],
        ),
        if (_selectedImagePaths.isEmpty) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text('还没有添加图片', style: AppTextStyle.bodySmall),
        ],
      ],
    );
  }

  Widget _buildDurationPicker() {
    const options = [15, 30, 45, 60, 90, 120];

    return Wrap(
      spacing: AppTheme.spacingS,
      runSpacing: AppTheme.spacingS,
      children: options.map((minutes) {
        final isSelected = _duration == minutes;
        return _PillButton(
          label: AppUtils.formatDuration(minutes),
          selected: isSelected,
          onTap: () => setState(() {
            _duration = isSelected ? null : minutes;
          }),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final checkInProvider = context.read<CheckInProvider>();

    final persistedImagePaths = _selectedImagePaths.isEmpty
        ? const <String>[]
        : await StorageService.saveImages(_selectedImagePaths);

    if (_selectedImagePaths.isNotEmpty &&
        persistedImagePaths.length != _selectedImagePaths.length) {
      for (final imagePath in persistedImagePaths) {
        await StorageService.deleteImage(imagePath);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppUtils.showSnackBar(context, '图片保存失败，请重试', isError: true);
      return;
    }

    final checkIn = await checkInProvider.submitCheckIn(
      goalId: widget.goalId,
      mode: _mode,
      status: _status,
      mood: _mood,
      duration: _duration,
      note: _noteController.text,
      reflectionProgress: _progressController.text,
      reflectionBlocker: _blockerController.text,
      reflectionNext: _nextController.text,
      imagePaths: persistedImagePaths,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (checkIn != null) {
      final streak = checkInProvider.getStreak(widget.goalId);
      final goal = context.read<GoalProvider>().getGoalById(widget.goalId);
      _showSuccessFeedback(checkIn, goal, streak);
      return;
    }

    for (final imagePath in persistedImagePaths) {
      await StorageService.deleteImage(imagePath);
    }
    if (!mounted) return;
    AppUtils.showSnackBar(context, '提交失败，请稍后重试', isError: true);
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImagePaths.length;
    if (remaining <= 0) return;

    try {
      final files = await _picker.pickMultiImage(limit: remaining);
      if (files.isEmpty || !mounted) return;

      setState(() {
        _selectedImagePaths.addAll(files.map((file) => file.path));
      });
    } catch (_) {
      if (!mounted) return;
      AppUtils.showSnackBar(context, '选择图片失败，请稍后重试', isError: true);
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  void _showSuccessFeedback(CheckIn checkIn, Goal? goal, int streak) {
    final checkInProvider = context.read<CheckInProvider>();
    final milestone = checkInProvider.pendingMilestone;
    checkInProvider.clearPendingMilestone();
    final navigator = Navigator.of(context);

    // 先弹里程碑庆祝浮层（若有）
    if (milestone != null) {
      MilestoneCelebrationOverlay.show(context, milestone);
    }

    showModalBottomSheet<_CheckInSuccessAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareableCheckInSuccessSheet(
        streak: streak,
        checkIn: checkIn,
        goal: goal,
      ),
    ).then((action) {
      if (!mounted) return;
      navigator.pop();
      if (action == _CheckInSuccessAction.mintNft) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.push(
            sharedAxisRoute(MintNftPage(initialCheckInId: checkIn.id)),
          );
        });
      }
    });
  }
}

class _HeaderCard extends StatelessWidget {
  final String goalTitle;

  const _HeaderCard({required this.goalTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今天记录什么', style: AppTextStyle.label),
          const SizedBox(height: 8),
          Text(goalTitle, style: AppTextStyle.h2),
          const SizedBox(height: 12),
          Row(
            children: [
              PixelIcon(
                icon: PixelIcons.clock,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppUtils.fullFriendlyDate(DateTime.now()),
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _SectionCard({required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyle.label),
              if (hint != null) ...[
                const SizedBox(width: 6),
                Text(hint!, style: AppTextStyle.caption),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodySmall.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SelectedImageTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onRemove;

  const _SelectedImageTile({required this.imagePath, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: LocalImagePreview(
            imagePath: imagePath,
            width: 104,
            height: 104,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final int remainingCount;
  final VoidCallback? onTap;

  const _AddImageTile({required this.remainingCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelIcon(icon: PixelIcons.plus, size: 20, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text('继续添加', style: AppTextStyle.bodySmall),
            const SizedBox(height: 2),
            Text('还能加 $remainingCount 张', style: AppTextStyle.caption),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _CheckInSuccessSheet extends StatelessWidget {
  final int streak;

  const _CheckInSuccessSheet({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: const Center(
              child: PixelIcon(
                icon: PixelIcons.trophy,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            streak > 1 ? AppUtils.streakText(streak) : '今天已记录',
            style: AppTextStyle.h2,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            AppUtils.randomEncouragement(),
            style: AppTextStyle.body.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('继续'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CheckInSuccessAction { mintNft }

class _ShareableCheckInSuccessSheet extends StatefulWidget {
  final int streak;
  final CheckIn checkIn;
  final Goal? goal;

  const _ShareableCheckInSuccessSheet({
    required this.streak,
    required this.checkIn,
    required this.goal,
  });

  @override
  State<_ShareableCheckInSuccessSheet> createState() =>
      _ShareableCheckInSuccessSheetState();
}

class _ShareableCheckInSuccessSheetState
    extends State<_ShareableCheckInSuccessSheet> {
  bool _isSharing = false;
  late bool _hasShared;

  @override
  void initState() {
    super.initState();
    _hasShared = context.read<SocialProvider>().hasPublishedCheckIn(
      widget.checkIn.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canShare = widget.goal?.isPublic == true;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: const Center(
              child: PixelIcon(
                icon: PixelIcons.trophy,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            widget.streak > 1 ? AppUtils.streakText(widget.streak) : '今天已记录',
            style: AppTextStyle.h2,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            AppUtils.randomEncouragement(),
            style: AppTextStyle.body.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canShare && !_isSharing && !_hasShared
                  ? _shareToSocial
                  : null,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _hasShared ? Icons.check_circle : Icons.public,
                      size: 18,
                    ),
              label: Text(
                _hasShared
                    ? '已分享到广场'
                    : canShare
                    ? '分享到广场'
                    : '目标未公开，暂不可分享',
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_CheckInSuccessAction.mintNft),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('铸造纪念 NFT'),
            ),
          ),
          if (!canShare) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '去编辑目标开启“公开这个目标”后，就可以把这次打卡分享到成长广场。',
              style: AppTextStyle.caption,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('继续'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToSocial() async {
    final goal = widget.goal;
    if (goal == null || !goal.isPublic) {
      AppUtils.showSnackBar(context, '这个目标还没有公开，暂时不能分享', isError: true);
      return;
    }

    setState(() => _isSharing = true);
    final published = await context.read<SocialProvider>().publishCheckIn(
      widget.checkIn,
      goal,
    );

    if (!mounted) return;
    setState(() {
      _isSharing = false;
      _hasShared = published || _hasShared;
    });

    AppUtils.showSnackBar(
      context,
      published ? '已分享到成长广场' : '这条打卡已经分享过了',
      isError: !published,
    );
  }
}
