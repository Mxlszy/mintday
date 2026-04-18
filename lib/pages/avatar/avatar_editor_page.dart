import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/avatar_config.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/avatar/avatar_part_data.dart';
import '../../widgets/avatar/pixel_avatar_painter.dart';

class AvatarEditorPage extends StatefulWidget {
  const AvatarEditorPage({super.key, this.canSkip = false});

  final bool canSkip;

  @override
  State<AvatarEditorPage> createState() => _AvatarEditorPageState();
}

class _AvatarEditorPageState extends State<AvatarEditorPage> {
  static const List<String> _tabs = <String>[
    '肤色',
    '脸型',
    '发型',
    '眼睛',
    '嘴巴',
    '配饰',
    '上衣',
    '配色',
  ];

  late AvatarConfig _config;
  bool _initialized = false;
  bool _isSaving = false;
  int _selectedTab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _config =
        context.read<UserProfileProvider>().profile.avatarConfig ??
        AvatarConfig.defaultConfig;
    _initialized = true;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final success = await context
        .read<UserProfileProvider>()
        .updateAvatarConfig(_config);
    if (!mounted) return;

    if (!success) {
      setState(() => _isSaving = false);
      AppUtils.showSnackBar(context, '形象保存失败，请稍后重试', isError: true);
      return;
    }

    Navigator.of(context).pop(_config);
  }

  void _randomize() {
    setState(() => _config = AvatarConfig.random());
  }

  void _reset() {
    setState(() => _config = AvatarConfig.defaultConfig);
  }

  String _currentOptionLabel() {
    return switch (_selectedTab) {
      0 => AvatarPartData.skinLabels[_config.skinColor],
      1 => AvatarPartData.faceShapes[_config.faceShape].label,
      2 => AvatarPartData.hairStyles[_config.hairStyle].label,
      3 => AvatarPartData.eyeStyles[_config.eyeStyle].label,
      4 => AvatarPartData.mouthStyles[_config.mouthStyle].label,
      5 => AvatarPartData.accessories[_config.accessory].label,
      6 => AvatarPartData.bodyStyles[_config.bodyStyle].label,
      _ => AvatarPartData.bodyColorLabels[_config.bodyColor],
    };
  }

  List<_AvatarOptionData> _optionsForCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.skinColors.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.skinLabels[index],
            selected: _config.skinColor == index,
            previewConfig: _config.copyWith(skinColor: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(skinColor: index)),
          ),
        );
      case 1:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.faceShapes.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.faceShapes[index].label,
            selected: _config.faceShape == index,
            previewConfig: _config.copyWith(faceShape: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(faceShape: index)),
          ),
        );
      case 2:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.hairStyles.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.hairStyles[index].label,
            selected: _config.hairStyle == index,
            previewConfig: _config.copyWith(hairStyle: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(hairStyle: index)),
          ),
        );
      case 3:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.eyeStyles.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.eyeStyles[index].label,
            selected: _config.eyeStyle == index,
            previewConfig: _config.copyWith(eyeStyle: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(eyeStyle: index)),
          ),
        );
      case 4:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.mouthStyles.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.mouthStyles[index].label,
            selected: _config.mouthStyle == index,
            previewConfig: _config.copyWith(mouthStyle: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(mouthStyle: index)),
          ),
        );
      case 5:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.accessories.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.accessories[index].label,
            selected: _config.accessory == index,
            previewConfig: _config.copyWith(accessory: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(accessory: index)),
          ),
        );
      case 6:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.bodyStyles.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.bodyStyles[index].label,
            selected: _config.bodyStyle == index,
            previewConfig: _config.copyWith(bodyStyle: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(bodyStyle: index)),
          ),
        );
      default:
        return List<_AvatarOptionData>.generate(
          AvatarPartData.bodyColors.length,
          (int index) => _AvatarOptionData(
            label: AvatarPartData.bodyColorLabels[index],
            selected: _config.bodyColor == index,
            previewConfig: _config.copyWith(bodyColor: index),
            onTap: () =>
                setState(() => _config = _config.copyWith(bodyColor: index)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewSize = (MediaQuery.sizeOf(context).width - 120)
        .clamp(120.0, 200.0)
        .toDouble();
    final options = _optionsForCurrentTab();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppTheme.background,
            AppTheme.accentLight.withValues(
              alpha: AppTheme.isDarkMode ? 0.76 : 0.94,
            ),
            AppTheme.bonusMint.withValues(
              alpha: AppTheme.isDarkMode ? 0.14 : 0.08,
            ),
            AppTheme.surface,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leadingWidth: widget.canSkip ? 72 : null,
          leading: widget.canSkip
              ? TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '跳过',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : null,
          title: const Text('创建形象'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Text('完成'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingS,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 6,
                  child: Column(
                    children: <Widget>[
                      Text(
                        '实时预览',
                        style: AppTextStyle.label.copyWith(letterSpacing: 0.4),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: previewSize + 44,
                            height: previewSize + 44,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surface,
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.neuRaised,
                            ),
                            child: Center(
                              child: PixelAvatar(
                                config: _config,
                                size: previewSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(
                            alpha: AppTheme.isDarkMode ? 0.82 : 0.88,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          '当前选择：${_tabs[_selectedTab]} · ${_currentOptionLabel()}',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('部件调整', style: AppTextStyle.h3),
                      const SizedBox(height: 6),
                      Text('切换分类，挑一套最像你的像素形象。', style: AppTextStyle.bodySmall),
                      const SizedBox(height: AppTheme.spacingM),
                      SizedBox(
                        height: 46,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: List<Widget>.generate(_tabs.length, (
                              int index,
                            ) {
                              final selected = _selectedTab == index;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == _tabs.length - 1
                                      ? 0
                                      : AppTheme.spacingS,
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTab = index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppTheme.primary
                                          : AppTheme.surface.withValues(
                                              alpha: AppTheme.isDarkMode
                                                  ? 0.74
                                                  : 0.9,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: selected
                                            ? AppTheme.primary
                                            : AppTheme.border,
                                      ),
                                      boxShadow: selected
                                          ? AppTheme.neuFlat
                                          : AppTheme.neuSubtle,
                                    ),
                                    child: Text(
                                      _tabs[index],
                                      style: AppTextStyle.bodySmall.copyWith(
                                        color: selected
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        '选择${_tabs[_selectedTab]}',
                        style: AppTextStyle.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      SizedBox(
                        height: 132,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: ListView.separated(
                            key: ValueKey<int>(_selectedTab),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: options.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppTheme.spacingM),
                            itemBuilder: (BuildContext context, int index) {
                              final option = options[index];
                              return _AvatarOptionCard(option: option);
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _randomize,
                              child: const Text('随机'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _reset,
                              child: const Text('重置'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _AvatarOptionData {
  const _AvatarOptionData({
    required this.label,
    required this.selected,
    required this.previewConfig,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AvatarConfig previewConfig;
  final VoidCallback onTap;
}

class _AvatarOptionCard extends StatelessWidget {
  const _AvatarOptionCard({required this.option});

  final _AvatarOptionData option;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 92,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: option.selected ? AppTheme.primary : AppTheme.border,
              width: option.selected ? 2 : 1,
            ),
            boxShadow: option.selected
                ? AppTheme.neuFlat
                : <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.shadowDark.withValues(
                        alpha: AppTheme.isDarkMode ? 0.18 : 0.04,
                      ),
                      offset: const Offset(0, 10),
                      blurRadius: 18,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(
                  child: PixelAvatar(config: option.previewConfig, size: 44),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: option.selected
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
