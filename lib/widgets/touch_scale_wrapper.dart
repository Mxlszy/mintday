import 'package:flutter/material.dart';

class TouchScaleWrapper extends StatefulWidget {
  const TouchScaleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.behavior = HitTestBehavior.translucent,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final HitTestBehavior behavior;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  @override
  State<TouchScaleWrapper> createState() => _TouchScaleWrapperState();
}

class _TouchScaleWrapperState extends State<TouchScaleWrapper> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: widget.enabled && _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
