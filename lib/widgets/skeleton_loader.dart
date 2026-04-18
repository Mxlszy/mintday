import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final Duration duration;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(_controller.value);

        return ClipRect(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : MediaQuery.of(context).size.width;
                      final highlightWidth = math.max(84.0, width * 0.26);
                      final travelDistance = width + highlightWidth * 2;
                      final offsetX =
                          -highlightWidth + travelDistance * progress;

                      return Transform.translate(
                        offset: Offset(offsetX, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.rotate(
                            angle: -0.16,
                            child: Container(
                              width: highlightWidth,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.surface.withValues(
                                      alpha: AppTheme.isDarkMode ? 0.18 : 0.54,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingL),
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: child,
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
    this.alignment = Alignment.centerLeft,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppTheme.surfaceDeep, AppTheme.surface],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.border.withValues(
              alpha: AppTheme.isDarkMode ? 0.82 : 0.96,
            ),
          ),
        ),
      ),
    );
  }
}
