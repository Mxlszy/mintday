import 'package:flutter/material.dart';
import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';
import '../models/milestone_progress.dart';

/// 里程碑解锁时的浮层庆祝弹窗，2.5 秒后自动消失
class MilestoneCelebrationOverlay extends StatefulWidget {
  final MilestoneProgress milestone;
  final VoidCallback onDismissed;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    required this.onDismissed,
  });

  @override
  State<MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();

  /// 弹出里程碑庆祝（自动插入 Overlay，2.5s 后消失）
  static void show(BuildContext context, MilestoneProgress milestone) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => MilestoneCelebrationOverlay(
        milestone: milestone,
        onDismissed: () => entry?.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _MilestoneCelebrationOverlayState
    extends State<MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // 2.5 秒后自动退出
    Future.delayed(const Duration(milliseconds: 2500), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: AppTheme.neuRaised,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    NeuContainer(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 14,
                      child: PixelIcon(
                        icon: PixelIcons.trophy,
                        size: 24,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMuted,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: Text(
                                  '里程碑解锁',
                                  style: AppTextStyle.caption.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.milestone.title,
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.milestone.description != null)
                            Text(
                              widget.milestone.description!,
                              style: AppTextStyle.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    PixelIcon(
                      icon: PixelIcons.star,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
