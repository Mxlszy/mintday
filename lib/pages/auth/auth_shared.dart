import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';

class AuthGradientScaffold extends StatelessWidget {
  const AuthGradientScaffold({
    super.key,
    this.appBar,
    required this.child,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.accentLight.withValues(
                alpha: AppTheme.isDarkMode ? 0.42 : 0.82,
              ),
              AppTheme.background,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class AuthHeroIcon extends StatelessWidget {
  const AuthHeroIcon({super.key, required this.icon});

  final PixelIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      height: 188,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(
          alpha: AppTheme.isDarkMode ? 0.76 : 0.9,
        ),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Center(child: PixelIcon(icon: icon, size: 104)),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingL),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: child,
    );
  }
}

InputDecoration buildAuthInputDecoration({
  required String hintText,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: AppTheme.surfaceVariant,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      borderSide: BorderSide(color: AppTheme.primary, width: 1.2),
    ),
  );
}

class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
      ),
    );
  }
}

class AuthPillSwitch extends StatelessWidget {
  const AuthPillSwitch({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : AppTheme.spacingXS,
                right: index == labels.length - 1 ? 0 : AppTheme.spacingXS,
              ),
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: AppTextStyle.caption.copyWith(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
