import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';

class AiCompanionEntryButton extends StatefulWidget {
  final VoidCallback onTap;

  const AiCompanionEntryButton({super.key, required this.onTap});

  @override
  State<AiCompanionEntryButton> createState() => _AiCompanionEntryButtonState();
}

class _AiCompanionEntryButtonState extends State<AiCompanionEntryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        final haloOpacity = 0.16 + pulse * 0.12;
        final haloSize = 58 + pulse * 10;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(40),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: haloSize,
                          height: haloSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withValues(
                              alpha: haloOpacity,
                            ),
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                offset: const Offset(0, 10),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: PixelIcon(
                              icon: PixelIcons.star,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.neuSubtle,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI 陪伴',
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '聊聊进度、情绪和下一步',
                            style: AppTextStyle.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
