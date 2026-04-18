import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/user_profile_model.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../models/nft_asset.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/nft_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/nft_rarity_service.dart';
import '../../widgets/local_image_preview.dart';
import '../../widgets/nft/creative_nft_templates.dart';
import '../../widgets/nft/nft_card_factory.dart';
import '../../widgets/nft/nft_card_render_data.dart';
import '../../widgets/nft/nft_visuals.dart';
import 'nft_detail_page.dart';

enum MintNftSource { recentCheckIn, creativeStudio }

class MintNftPage extends StatefulWidget {
  const MintNftPage({super.key, this.initialCheckInId});

  final String? initialCheckInId;

  @override
  State<MintNftPage> createState() => _MintNftPageState();
}

class _MintNftPageState extends State<MintNftPage>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final AnimationController _mintProgressController;
  late final AnimationController _burstController;

  int _step = 0;
  MintNftSource _source = MintNftSource.recentCheckIn;
  String? _selectedCheckInId;
  String? _selectedTemplateId;
  bool _isMinting = false;
  bool _titleTouched = false;
  bool _descriptionTouched = false;
  String? _draftSyncKey;

  @override
  void initState() {
    super.initState();
    _selectedCheckInId = widget.initialCheckInId;
    _mintProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _mintProgressController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProvider = context.watch<CheckInProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final profile = context.watch<UserProfileProvider>().profile;
    final recentCheckIns = checkInProvider.checkIns
        .where((item) => item.status != CheckInStatus.skipped)
        .take(14)
        .toList();

    _ensureSelectedCheckIn(recentCheckIns);

    final selectedCheckIn = _findSelectedCheckIn(recentCheckIns);
    final templates = _buildTemplateOptions();
    _ensureSelectedTemplate(templates);

    final selectedTemplate = templates.firstWhere(
      (item) => item.id == _selectedTemplateId,
      orElse: () => templates.first,
    );

    final seedData = _buildRenderData(
      selectedTemplate,
      checkInProvider: checkInProvider,
      goalProvider: goalProvider,
      profile: profile,
      checkIns: recentCheckIns,
      selectedCheckIn: selectedCheckIn,
      overrideTitle: null,
      overrideDescription: null,
    );
    _syncDraftText(selectedTemplate, seedData);

    final previewData = _buildRenderData(
      selectedTemplate,
      checkInProvider: checkInProvider,
      goalProvider: goalProvider,
      profile: profile,
      checkIns: recentCheckIns,
      selectedCheckIn: selectedCheckIn,
      overrideTitle: _titleController.text.trim(),
      overrideDescription: _descriptionController.text.trim(),
    );

    final rarityReasons = List<String>.from(
      previewData.metadata['rarityReasons'] as List<dynamic>? ?? const [],
    ).map((item) => item.toString()).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('铸造 NFT')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingM,
                  AppTheme.spacingL,
                  AppTheme.spacingM,
                ),
                child: _StepIndicator(currentStep: _step),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSourceStep(recentCheckIns, selectedCheckIn),
                    _buildTemplateStep(
                      templates,
                      selectedTemplate,
                      previewData,
                    ),
                    _buildCustomizeStep(selectedTemplate, previewData),
                    _buildConfirmStep(
                      selectedTemplate,
                      previewData,
                      rarityReasons,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isMinting)
            Positioned.fill(
              child: _MintingOverlay(
                progress: _mintProgressController,
                burst: _burstController,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            0,
            AppTheme.spacingL,
            AppTheme.spacingL,
          ),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isMinting ? null : _goBack,
                    child: const Text('上一步'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isMinting
                      ? null
                      : () => _handlePrimaryAction(
                          recentCheckIns: recentCheckIns,
                          selectedCheckIn: selectedCheckIn,
                          selectedTemplate: selectedTemplate,
                          previewData: previewData,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_step == 3 ? '铸造 NFT' : '下一步'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceStep(
    List<CheckIn> recentCheckIns,
    CheckIn? selectedCheckIn,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        0,
        AppTheme.spacingL,
        AppTheme.spacingXL,
      ),
      children: [
        Text('选择来源', style: AppTextStyle.h2),
        const SizedBox(height: 8),
        Text(
          '可以把一次真实打卡铸造成瞬间 NFT，也可以直接进入创意合成模式。',
          style: AppTextStyle.bodySmall,
        ),
        const SizedBox(height: AppTheme.spacingL),
        Row(
          children: [
            Expanded(
              child: _SourceCard(
                title: '最近打卡',
                subtitle: '基于真实照片、心情和连续数据生成',
                icon: PixelIcons.camera,
                selected: _source == MintNftSource.recentCheckIn,
                onTap: () =>
                    setState(() => _source = MintNftSource.recentCheckIn),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _SourceCard(
                title: '创意合成',
                subtitle: '混合模板与最近数据做成艺术风 NFT',
                icon: PixelIcons.star,
                selected: _source == MintNftSource.creativeStudio,
                onTap: () =>
                    setState(() => _source = MintNftSource.creativeStudio),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        if (_source == MintNftSource.recentCheckIn) ...[
          Text('选择一条打卡记录', style: AppTextStyle.h3),
          const SizedBox(height: AppTheme.spacingM),
          if (recentCheckIns.isEmpty)
            const _EmptySelectionCard(
              title: '还没有可用打卡',
              subtitle: '先完成一次打卡，就可以把瞬间铸造成 NFT。',
            )
          else
            ...recentCheckIns.map(
              (checkIn) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: _CheckInSourceTile(
                  checkIn: checkIn,
                  selected: checkIn.id == selectedCheckIn?.id,
                  onTap: () => setState(() => _selectedCheckInId = checkIn.id),
                ),
              ),
            ),
        ] else ...[
          const _EmptySelectionCard(
            title: '创意模式已就绪',
            subtitle: '系统会优先参考最近一条打卡与最近 7 次记录，为模板补足内容。',
          ),
        ],
      ],
    );
  }

  Widget _buildTemplateStep(
    List<_MintTemplateOption> templates,
    _MintTemplateOption selectedTemplate,
    NftCardRenderData previewData,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        0,
        AppTheme.spacingL,
        AppTheme.spacingXL,
      ),
      children: [
        Text('选择模板', style: AppTextStyle.h2),
        const SizedBox(height: 8),
        Text('滑动选择模板，预览会实时更新。', style: AppTextStyle.bodySmall),
        const SizedBox(height: AppTheme.spacingL),
        AspectRatio(
          aspectRatio: 420 / 560,
          child: buildNftArtwork(
            category: selectedTemplate.category,
            data: previewData,
            templateId: selectedTemplate.templateId,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        SizedBox(
          height: 134,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppTheme.spacingM),
            itemBuilder: (context, index) {
              final item = templates[index];
              return _TemplateTile(
                option: item,
                selected: item.id == selectedTemplate.id,
                onTap: () => setState(() => _selectedTemplateId = item.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizeStep(
    _MintTemplateOption selectedTemplate,
    NftCardRenderData previewData,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        0,
        AppTheme.spacingL,
        AppTheme.spacingXL,
      ),
      children: [
        Text('自定义文案', style: AppTextStyle.h2),
        const SizedBox(height: 8),
        Text('你可以改一个标题，再留下一句今天的话。', style: AppTextStyle.bodySmall),
        const SizedBox(height: AppTheme.spacingL),
        SizedBox(
          height: 260,
          child: AspectRatio(
            aspectRatio: 420 / 560,
            child: buildNftArtwork(
              category: selectedTemplate.category,
              data: previewData,
              templateId: selectedTemplate.templateId,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        TextField(
          controller: _titleController,
          maxLength: 28,
          onChanged: (_) => _titleTouched = true,
          decoration: const InputDecoration(
            labelText: 'NFT 标题',
            hintText: '例如：凌晨 1 点的坚持',
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextField(
          controller: _descriptionController,
          maxLength: 60,
          minLines: 2,
          maxLines: 3,
          onChanged: (_) => _descriptionTouched = true,
          decoration: const InputDecoration(
            labelText: '一句描述',
            hintText: '例如：把今天的小小推进，留成一张会发光的卡片。',
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(
    _MintTemplateOption selectedTemplate,
    NftCardRenderData previewData,
    List<String> rarityReasons,
  ) {
    final rarity = previewData.rarity;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        0,
        AppTheme.spacingL,
        AppTheme.spacingXL,
      ),
      children: [
        Text('确认铸造', style: AppTextStyle.h2),
        const SizedBox(height: 8),
        Text('系统已经根据这次数据计算出稀有度。', style: AppTextStyle.bodySmall),
        const SizedBox(height: AppTheme.spacingL),
        AspectRatio(
          aspectRatio: 420 / 560,
          child: buildNftArtwork(
            category: selectedTemplate.category,
            data: previewData,
            templateId: selectedTemplate.templateId,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Row(
          children: [
            NftRarityChip(rarity: rarity),
            const SizedBox(width: 10),
            NftCategoryChip(category: selectedTemplate.category),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('稀有度判定', style: AppTextStyle.h3),
              const SizedBox(height: 10),
              ...rarityReasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.auto_awesome, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(reason, style: AppTextStyle.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _StatSummaryRow(data: previewData),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction({
    required List<CheckIn> recentCheckIns,
    required CheckIn? selectedCheckIn,
    required _MintTemplateOption selectedTemplate,
    required NftCardRenderData previewData,
  }) async {
    if (_step == 0) {
      if (_source == MintNftSource.recentCheckIn && selectedCheckIn == null) {
        AppUtils.showSnackBar(context, '先选一条打卡记录', isError: true);
        return;
      }
      return _goNext();
    }

    if (_step < 3) {
      return _goNext();
    }

    await _mintNft(
      selectedTemplate: selectedTemplate,
      previewData: previewData,
      selectedCheckIn: selectedCheckIn,
      recentCheckIns: recentCheckIns,
    );
  }

  Future<void> _mintNft({
    required _MintTemplateOption selectedTemplate,
    required NftCardRenderData previewData,
    required CheckIn? selectedCheckIn,
    required List<CheckIn> recentCheckIns,
  }) async {
    setState(() => _isMinting = true);
    _mintProgressController.forward(from: 0);
    _burstController.reset();

    final nftProvider = context.read<NftProvider>();
    final metadata = Map<String, dynamic>.from(previewData.metadata);
    metadata['mintSource'] = _source.name;
    metadata['templateId'] = selectedTemplate.templateId;
    metadata['recentContextCount'] = recentCheckIns.length;

    final asset = await nftProvider.createRenderedNft(
      category: selectedTemplate.category,
      sourceId: selectedCheckIn?.goalId ?? metadata['goalId']?.toString(),
      checkInId: selectedCheckIn?.id,
      templateId: selectedTemplate.templateId,
      renderData: previewData.copyWith(metadata: metadata),
      allowExistingMatch: true,
    );

    if (asset == null) {
      if (!mounted) return;
      setState(() => _isMinting = false);
      AppUtils.showSnackBar(context, '生成 NFT 卡片失败，请稍后重试', isError: true);
      return;
    }

    final minted = asset.status == NftStatus.minted
        ? asset
        : await nftProvider.mintNft(asset.id);
    await _mintProgressController.animateTo(
      1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );

    if (minted?.status == NftStatus.minted) {
      await _burstController.forward(from: 0);
      if (!mounted) return;
      setState(() => _isMinting = false);
      Navigator.of(
        context,
      ).pushReplacement(sharedAxisRoute(NftDetailPage(assetId: minted!.id)));
      return;
    }

    if (!mounted) return;
    setState(() => _isMinting = false);
    AppUtils.showSnackBar(context, '铸造失败，请稍后再试', isError: true);
  }

  void _goNext() {
    if (_step >= 3) return;
    setState(() => _step += 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_step <= 0) return;
    setState(() => _step -= 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _ensureSelectedCheckIn(List<CheckIn> recentCheckIns) {
    if (_selectedCheckInId != null &&
        recentCheckIns.any((item) => item.id == _selectedCheckInId)) {
      return;
    }
    _selectedCheckInId = recentCheckIns.isEmpty
        ? null
        : recentCheckIns.first.id;
  }

  void _ensureSelectedTemplate(List<_MintTemplateOption> templates) {
    if (templates.isEmpty) {
      _selectedTemplateId = null;
      return;
    }

    if (_selectedTemplateId != null &&
        templates.any((item) => item.id == _selectedTemplateId)) {
      return;
    }
    _selectedTemplateId = templates.first.id;
  }

  CheckIn? _findSelectedCheckIn(List<CheckIn> recentCheckIns) {
    try {
      return recentCheckIns.firstWhere((item) => item.id == _selectedCheckInId);
    } catch (_) {
      return recentCheckIns.isEmpty ? null : recentCheckIns.first;
    }
  }

  List<_MintTemplateOption> _buildTemplateOptions() {
    const momentTemplate = _MintTemplateOption(
      id: 'moment_core',
      templateId: 'moment_core',
      name: '打卡瞬间',
      subtitle: '照片、心情与数据组合成纪念卡',
      icon: PixelIcons.camera,
      category: NftCategory.moment,
      accentColor: Color(0xFF4FC3F7),
      usesCollectionData: false,
      defaultTitle: _defaultMomentTitle,
      defaultDescription: _defaultMomentDescription,
    );

    final creativeOptions = creativeNftTemplates
        .map(
          (item) => _MintTemplateOption(
            id: item.id,
            templateId: item.id,
            name: item.name,
            subtitle: item.subtitle,
            icon: item.icon,
            category: item.category,
            accentColor: item.accentColor,
            usesCollectionData: item.usesCollectionData,
            defaultTitle: item.defaultTitle,
            defaultDescription: item.defaultDescription,
          ),
        )
        .toList();

    if (_source == MintNftSource.recentCheckIn) {
      return <_MintTemplateOption>[momentTemplate, ...creativeOptions];
    }
    return creativeOptions;
  }

  NftCardRenderData _buildRenderData(
    _MintTemplateOption option, {
    required CheckInProvider checkInProvider,
    required GoalProvider goalProvider,
    required UserProfileModel profile,
    required List<CheckIn> checkIns,
    required CheckIn? selectedCheckIn,
    required String? overrideTitle,
    required String? overrideDescription,
  }) {
    final primaryCheckIn =
        selectedCheckIn ?? (checkIns.isEmpty ? null : checkIns.first);
    final goal = primaryCheckIn == null
        ? null
        : goalProvider.getGoalById(primaryCheckIn.goalId);
    final collectionCheckIns = option.usesCollectionData
        ? _collectContextCheckIns(primaryCheckIn, checkIns)
        : (primaryCheckIn == null
              ? const <CheckIn>[]
              : <CheckIn>[primaryCheckIn]);
    final streakDays = goal == null ? 0 : checkInProvider.getStreak(goal.id);
    final totalCheckIns = goal == null
        ? collectionCheckIns.length
        : checkInProvider
              .getCheckInsForGoal(goal.id)
              .where((item) => item.status != CheckInStatus.skipped)
              .length;
    final focusMinutes = option.usesCollectionData
        ? collectionCheckIns.fold<int>(
            0,
            (sum, item) => sum + (item.duration ?? 0),
          )
        : (primaryCheckIn?.duration ?? 0);
    final capturedAt = primaryCheckIn?.createdAt ?? DateTime.now();
    final rarity = NftRarityService.evaluate(
      capturedAt: capturedAt,
      mood: primaryCheckIn?.mood,
      streakDays: streakDays,
      isGoalFinalCheckIn:
          goal?.status == GoalStatus.completed || goal?.progress == 1,
    );

    final seedData = NftCardRenderData(
      title: '',
      description: '',
      createdAt: capturedAt,
      nickname: profile.nickname,
      rarity: rarity.rarity,
      avatarConfig: profile.avatarConfig,
      primaryCheckIn: primaryCheckIn,
      goal: goal,
      collectionCheckIns: collectionCheckIns,
      streakDays: streakDays,
      totalCheckIns: totalCheckIns,
      focusMinutes: focusMinutes,
    );

    return NftCardRenderData(
      title: overrideTitle?.trim().isNotEmpty == true
          ? overrideTitle!.trim()
          : option.defaultTitle(seedData),
      description: overrideDescription?.trim().isNotEmpty == true
          ? overrideDescription!.trim()
          : option.defaultDescription(seedData),
      createdAt: capturedAt,
      nickname: profile.nickname,
      rarity: rarity.rarity,
      avatarConfig: profile.avatarConfig,
      primaryCheckIn: primaryCheckIn,
      goal: goal,
      collectionCheckIns: collectionCheckIns,
      streakDays: streakDays,
      totalCheckIns: totalCheckIns,
      focusMinutes: focusMinutes,
      metadata: <String, dynamic>{
        'goalId': goal?.id,
        'goalTitle': goal?.title,
        'mood': primaryCheckIn?.mood,
        'streakDays': streakDays,
        'totalCheckIns': totalCheckIns,
        'focusMinutes': focusMinutes,
        'capturedAt': capturedAt.toIso8601String(),
        'collectionCheckInIds': collectionCheckIns
            .map((item) => item.id)
            .toList(),
        'rarityReasons': rarity.reasons,
        'specialTimePoint': rarity.isSpecialTimePoint,
        'holidayLabel': rarity.holidayLabel,
        'templateLabel': option.name,
      },
    );
  }

  List<CheckIn> _collectContextCheckIns(
    CheckIn? primaryCheckIn,
    List<CheckIn> checkIns,
  ) {
    if (checkIns.isEmpty) return const <CheckIn>[];
    if (primaryCheckIn == null) {
      return checkIns.take(7).toList();
    }
    final sameGoal = checkIns
        .where((item) => item.goalId == primaryCheckIn.goalId)
        .take(7)
        .toList();
    return sameGoal.isEmpty ? checkIns.take(7).toList() : sameGoal;
  }

  void _syncDraftText(_MintTemplateOption option, NftCardRenderData seedData) {
    final syncKey =
        '${_source.name}:${option.id}:${seedData.primaryCheckIn?.id ?? 'none'}';
    if (_draftSyncKey == syncKey) return;

    if (!_titleTouched) {
      _titleController.text = option.defaultTitle(seedData);
    }
    if (!_descriptionTouched) {
      _descriptionController.text = option.defaultDescription(seedData);
    }
    _draftSyncKey = syncKey;
  }
}

class _MintTemplateOption {
  const _MintTemplateOption({
    required this.id,
    required this.templateId,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.accentColor,
    required this.usesCollectionData,
    required this.defaultTitle,
    required this.defaultDescription,
  });

  final String id;
  final String templateId;
  final String name;
  final String subtitle;
  final PixelIconData icon;
  final NftCategory category;
  final Color accentColor;
  final bool usesCollectionData;
  final String Function(NftCardRenderData data) defaultTitle;
  final String Function(NftCardRenderData data) defaultDescription;
}

String _defaultMomentTitle(NftCardRenderData data) {
  return '${data.goalTitle} · ${data.createdAt.month}/${data.createdAt.day}';
}

String _defaultMomentDescription(NftCardRenderData data) {
  return data.primaryNote;
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const titles = ['来源', '模板', '自定义', '确认'];
    return Row(
      children: List.generate(titles.length, (index) {
        final selected = index == currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == titles.length - 1 ? 0 : 10,
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  titles[index],
                  style: AppTextStyle.caption.copyWith(
                    color: selected ? AppTheme.textPrimary : AppTheme.textHint,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final PixelIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: 1.4,
          ),
          boxShadow: AppTheme.neuSubtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelIcon(
              icon: icon,
              size: 22,
              color: selected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyle.h3.copyWith(
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyle.bodySmall.copyWith(
                color: selected
                    ? Colors.white.withValues(alpha: 0.78)
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInSourceTile extends StatelessWidget {
  const _CheckInSourceTile({
    required this.checkIn,
    required this.selected,
    required this.onTap,
  });

  final CheckIn checkIn;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = checkIn.imagePaths.isEmpty
        ? null
        : checkIn.imagePaths.first;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryMuted : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: imagePath == null
                  ? Container(
                      width: 68,
                      height: 68,
                      color: AppTheme.surfaceVariant,
                      child: Center(
                        child: PixelMoodFace(mood: checkIn.mood ?? 3, size: 26),
                      ),
                    )
                  : LocalImagePreview(
                      imagePath: imagePath,
                      width: 68,
                      height: 68,
                      borderRadius: AppTheme.radiusM,
                    ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppUtils.fullDateLabel(checkIn.date),
                    style: AppTextStyle.label,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    checkIn.note ??
                        checkIn.reflectionProgress ??
                        checkIn.reflectionNext ??
                        '这次打卡没有留下文字',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _MintTemplateOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 186,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: selected
              ? option.accentColor.withValues(alpha: 0.16)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: selected ? option.accentColor : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelIcon(icon: option.icon, size: 20, color: option.accentColor),
            const SizedBox(height: 12),
            Text(
              option.name,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              option.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                NftCategoryChip(category: option.category, compact: true),
                const Spacer(),
                if (option.usesCollectionData)
                  Text(
                    '7天',
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySelectionCard extends StatelessWidget {
  const _EmptySelectionCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.h3),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyle.bodySmall),
        ],
      ),
    );
  }
}

class _StatSummaryRow extends StatelessWidget {
  const _StatSummaryRow({required this.data});

  final NftCardRenderData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryPill(label: '连续', value: '${data.streakDays}'),
        const SizedBox(width: 8),
        _SummaryPill(label: '累计', value: '${data.totalCheckIns}'),
        const SizedBox(width: 8),
        _SummaryPill(label: '专注', value: '${data.focusMinutes}m'),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyle.caption),
          ],
        ),
      ),
    );
  }
}

class _MintingOverlay extends StatelessWidget {
  const _MintingOverlay({required this.progress, required this.burst});

  final Animation<double> progress;
  final Animation<double> burst;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.54)),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, burst]),
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + burst.value * 0.04,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.neuRaised,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PixelMoodFace(mood: 5, size: 34),
                        const SizedBox(height: 14),
                        Text('正在像素铸造炉中成型', style: AppTextStyle.h3),
                        const SizedBox(height: 10),
                        Text(
                          '系统正在生成卡面、写入稀有度，并完成纪念 NFT 的模拟上链。',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.bodySmall,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Container(
                          height: 18,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: math.max(0.1, progress.value),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4FC3F7),
                                      Color(0xFFFFD740),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(progress.value * 100).clamp(0, 100).toInt()}%',
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (burst.value > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _MintBurstPainter(progress: burst.value),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MintBurstPainter extends CustomPainter {
  const _MintBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = const [
      Color(0xFF4FC3F7),
      Color(0xFFFFD740),
      Color(0xFFE040FB),
      Color(0xFFFF8A65),
    ];

    for (var i = 0; i < 20; i++) {
      final angle = (math.pi * 2 / 20) * i + progress * 0.3;
      final distance = 26 + progress * 90 + (i % 4) * 8;
      final particle =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      paint.color = colors[i % colors.length].withValues(
        alpha: 0.7 * (1 - progress),
      );
      canvas.drawCircle(particle, 2 + (i % 3).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MintBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
