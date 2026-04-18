import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/page_transitions.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/user_profile_prefs.dart';
import '../avatar/avatar_editor_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isCompleting = false;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: PixelIcons.flag,
      title: '记录你正在成为谁',
      subtitle: '设定目标，每天记录一点点成长',
    ),
    _OnboardingStep(
      icon: PixelIcons.fire,
      title: '专注 · 坚持 · 看见变化',
      subtitle: '计时器帮你记录每一分钟专注',
    ),
    _OnboardingStep(
      icon: PixelIcons.trophy,
      title: '铸造你的成长勋章',
      subtitle: '每个里程碑都值得被铭记',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentPage < _steps.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    await UserProfilePrefs.setOnboardingCompleted(true);
    if (!mounted) return;

    if (context.read<UserProfileProvider>().profile.avatarConfig == null) {
      await Navigator.of(
        context,
      ).push(fadeSlideRoute(const AvatarEditorPage(canSkip: true)));
      if (!mounted) return;
    }

    widget.onCompleted?.call();
  }

  List<Color> _gradientColorsFor(int index) {
    switch (index) {
      case 0:
        return [
          AppTheme.background,
          AppTheme.accentLight.withValues(
            alpha: AppTheme.isDarkMode ? 0.72 : 0.95,
          ),
          AppTheme.surface,
        ];
      case 1:
        return [
          AppTheme.background,
          AppTheme.bonusMint.withValues(
            alpha: AppTheme.isDarkMode ? 0.26 : 0.22,
          ),
          AppTheme.surface,
        ];
      case 2:
        return [
          AppTheme.background,
          AppTheme.goldAccent.withValues(
            alpha: AppTheme.isDarkMode ? 0.2 : 0.18,
          ),
          AppTheme.surface,
        ];
      default:
        return [AppTheme.background, AppTheme.surfaceVariant, AppTheme.surface];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _steps.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemBuilder: (context, index) {
              return _OnboardingSlide(
                step: _steps[index],
                gradientColors: _gradientColorsFor(index),
                isActive: index == _currentPage,
              );
            },
          ),
          Positioned(
            left: AppTheme.spacingL,
            right: AppTheme.spacingL,
            bottom: AppTheme.spacingL + bottomInset,
            child: IgnorePointer(
              ignoring: _isCompleting,
              child: _OnboardingBottomBar(
                currentPage: _currentPage,
                totalPages: _steps.length,
                isCompleting: _isCompleting,
                onPressed: _handlePrimaryAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.step,
    required this.gradientColors,
    required this.isActive,
  });

  final _OnboardingStep step;
  final List<Color> gradientColors;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingXL,
            AppTheme.spacingXXL,
            AppTheme.spacingXL,
            180,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            opacity: isActive ? 1 : 0.4,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              offset: isActive ? Offset.zero : const Offset(0, 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _OnboardingHeroIcon(icon: step.icon),
                  const SizedBox(height: AppTheme.spacingXXL),
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.h1.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    step.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.body.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeroIcon extends StatelessWidget {
  const _OnboardingHeroIcon({required this.icon});

  final PixelIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      height: 188,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(
          alpha: AppTheme.isDarkMode ? 0.76 : 0.88,
        ),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: AppTheme.border.withValues(
            alpha: AppTheme.isDarkMode ? 0.88 : 1,
          ),
        ),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Center(child: PixelIcon(icon: icon, size: 104)),
    );
  }
}

class _OnboardingBottomBar extends StatelessWidget {
  const _OnboardingBottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.isCompleting,
    required this.onPressed,
  });

  final int currentPage;
  final int totalPages;
  final bool isCompleting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(
          alpha: AppTheme.isDarkMode ? 0.9 : 0.94,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: isActive ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : AppTheme.surfaceDeep,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isLastPage ? '开始旅程' : '下一步'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final PixelIconData icon;
  final String title;
  final String subtitle;
}
