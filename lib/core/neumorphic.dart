import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class NeuContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final bool isPressed;
  final bool isSubtle;
  final Color? color;
  final VoidCallback? onTap;

  const NeuContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusL,
    this.isPressed = false,
    this.isSubtle = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = isPressed
        ? AppTheme.neuFlat
        : (isSubtle ? AppTheme.neuSubtle : AppTheme.neuRaised);

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) {
      return container;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: container,
    );
  }
}

class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? color;
  final bool toggled;

  const NeuButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.borderRadius = AppTheme.radiusM,
    this.color,
    this.toggled = false,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressing = false;

  bool get _isDown => _pressing || widget.toggled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isDown
              ? (widget.color ?? AppTheme.surfaceVariant)
              : (widget.color ?? AppTheme.surface),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppTheme.border),
          boxShadow: _isDown ? AppTheme.neuFlat : AppTheme.neuRaised,
        ),
        child: widget.child,
      ),
    );
  }
}

class NeuIconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;

  const NeuIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 48,
    this.isSelected = false,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _pressing = false;

  bool get _isDown => _pressing || widget.isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isDown ? AppTheme.primaryMuted : AppTheme.surface,
          borderRadius: BorderRadius.circular(widget.size / 2.4),
          border: Border.all(color: AppTheme.border),
          boxShadow: _isDown ? AppTheme.neuFlat : AppTheme.neuSubtle,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class NeuInset extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const NeuInset({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppTheme.radiusM,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
