import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ai_message.dart';
import '../../models/avatar_config.dart';
import '../../providers/ai_companion_provider.dart';
import '../../widgets/avatar/pixel_avatar_painter.dart';
import '../../widgets/pixel_progress_bar.dart';
import '../../widgets/skeleton_loader.dart';

const Duration _kMessageAnimationDuration = Duration(milliseconds: 280);
const AvatarConfig _kAiCompanionAvatarConfig = AvatarConfig(
  skinColor: 0,
  faceShape: 1,
  hairStyle: 5,
  eyeStyle: 2,
  mouthStyle: 0,
  accessory: 0,
  bodyStyle: 5,
  bodyColor: 2,
);

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  static const _quickPrompts = <String>['我的进度', '给我鼓励', '今天做什么？', '给我建议'];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<_ChatTimelineItem> _items = <_ChatTimelineItem>[];

  List<AiMessage> _pendingMessages = const <AiMessage>[];
  bool _pendingIsTyping = false;
  bool _syncQueued = false;
  int _lastScrollKey = -1;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.clear();
    context.read<AiCompanionProvider>().sendMessage(trimmed);
  }

  void _queueAnimatedListSync(AiCompanionProvider provider) {
    _pendingMessages = provider.messages;
    _pendingIsTyping = provider.isTyping;
    if (_syncQueued) return;

    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueued = false;
      if (!mounted) return;
      _applyAnimatedListSync();
    });
  }

  void _applyAnimatedListSync() {
    final nextItems = <_ChatTimelineItem>[
      ..._pendingMessages.map(
        (message) => _ChatTimelineItem.message(
          message,
          insight: context.read<AiCompanionProvider>().insightForMessage(
            message.id,
          ),
        ),
      ),
      if (_pendingIsTyping) const _ChatTimelineItem.typing(),
    ];
    final listState = _listKey.currentState;

    if (listState == null) {
      setState(() {
        _items
          ..clear()
          ..addAll(nextItems);
      });
      _scheduleScroll(_scrollKeyForCurrentState());
      return;
    }

    var sharedPrefix = 0;
    while (sharedPrefix < _items.length &&
        sharedPrefix < nextItems.length &&
        _items[sharedPrefix] == nextItems[sharedPrefix]) {
      sharedPrefix++;
    }

    for (var index = _items.length - 1; index >= sharedPrefix; index--) {
      final removedItem = _items.removeAt(index);
      listState.removeItem(
        index,
        (context, animation) => _buildAnimatedListItem(removedItem, animation),
        duration: _kMessageAnimationDuration,
      );
    }

    for (var index = sharedPrefix; index < nextItems.length; index++) {
      _items.insert(index, nextItems[index]);
      listState.insertItem(index, duration: _kMessageAnimationDuration);
    }

    _scheduleScroll(_scrollKeyForCurrentState());
  }

  int _scrollKeyForCurrentState() {
    return _pendingMessages.length * 10 + (_pendingIsTyping ? 1 : 0);
  }

  void _scheduleScroll(int key) {
    if (_lastScrollKey == key) return;
    _lastScrollKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildAnimatedListItem(
    _ChatTimelineItem item,
    Animation<double> animation,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: _AnimatedMessageEntry(
        animation: animation,
        child: switch (item.type) {
          _ChatTimelineItemType.message => _MessageBubble(
            message: item.message!,
            insight: item.insight,
          ),
          _ChatTimelineItemType.typing => const _TypingMessageRow(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiCompanionProvider>();

    if (!provider.isBootstrapping) {
      _queueAnimatedListSync(provider);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: provider.isBootstrapping
            ? const _AiChatSkeletonView()
            : Column(
                children: [
                  const _AiChatHeader(),
                  Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        AppTheme.spacingM,
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                      ),
                      initialItemCount: _items.length,
                      itemBuilder: (context, index, animation) {
                        return _buildAnimatedListItem(_items[index], animation);
                      },
                    ),
                  ),
                  _ComposerPanel(
                    controller: _controller,
                    quickPrompts: _quickPrompts,
                    isTyping: provider.isTyping,
                    onSend: (text) => _handleSend(context, text),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AiChatSkeletonView extends StatelessWidget {
  const _AiChatSkeletonView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AiChatHeader(),
        Expanded(
          child: SkeletonLoader(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingM,
                AppTheme.spacingL,
                AppTheme.spacingL,
              ),
              children: const [
                _AiSkeletonBubble(width: 228, alignRight: false),
                SizedBox(height: AppTheme.spacingM),
                _AiSkeletonBubble(width: 174, alignRight: true),
                SizedBox(height: AppTheme.spacingM),
                _AiSkeletonBubble(width: 252, alignRight: false, tall: true),
                SizedBox(height: AppTheme.spacingM),
                _AiSkeletonBubble(width: 188, alignRight: false),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingM,
            AppTheme.spacingL,
            AppTheme.spacingM + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.neuRaised,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Row(
                children: [
                  Expanded(child: SkeletonBlock(height: 38, borderRadius: 999)),
                  SizedBox(width: AppTheme.spacingS),
                  SkeletonBlock(width: 52, height: 52, borderRadius: 26),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiSkeletonBubble extends StatelessWidget {
  const _AiSkeletonBubble({
    required this.width,
    required this.alignRight,
    this.tall = false,
  });

  final double width;
  final bool alignRight;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final bubble = SkeletonCard(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      borderRadius: AppTheme.radiusL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(height: tall ? 14 : 12, borderRadius: 7),
          const SizedBox(height: 8),
          SkeletonBlock(
            width: width * 0.64,
            height: tall ? 14 : 12,
            borderRadius: 7,
          ),
          if (tall) ...const [
            SizedBox(height: 8),
            SkeletonBlock(width: 120, height: 12, borderRadius: 7),
          ],
        ],
      ),
    );

    if (alignRight) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(width: width, child: bubble),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Center(child: SkeletonBlock(width: 14, height: 14)),
        ),
        const SizedBox(width: 10),
        SizedBox(width: width, child: bubble),
      ],
    );
  }
}

class _AiChatHeader extends StatelessWidget {
  const _AiChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppTheme.textPrimary,
                ),
                splashRadius: 22,
              ),
            ),
            Text(
              'AI 伙伴',
              style: AppTextStyle.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: AppTheme.spacingS),
                child: _AiAvatar(size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerPanel extends StatefulWidget {
  final TextEditingController controller;
  final List<String> quickPrompts;
  final bool isTyping;
  final ValueChanged<String> onSend;

  const _ComposerPanel({
    required this.controller,
    required this.quickPrompts,
    required this.isTyping,
    required this.onSend,
  });

  @override
  State<_ComposerPanel> createState() => _ComposerPanelState();
}

class _ComposerPanelState extends State<_ComposerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _promptHintController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _promptHintOffset = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: 6,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 26,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 6,
        end: -4,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: -4,
        end: 2,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 2,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 24,
    ),
  ]).animate(_promptHintController);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.quickPrompts.isEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      _promptHintController.forward();
    });
  }

  @override
  void dispose() {
    _promptHintController.dispose();
    super.dispose();
  }

  Color _pillTint(int index) {
    return switch (index % 3) {
      0 => AppTheme.accent,
      1 => AppTheme.bonusMint,
      _ => AppTheme.bonusBlue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingL,
          AppTheme.spacingM + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL),
          ),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.neuRaised,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 42,
              child: AnimatedBuilder(
                animation: _promptHintController,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.quickPrompts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppTheme.spacingS),
                  itemBuilder: (context, index) {
                    final prompt = widget.quickPrompts[index];

                    return _PromptPill(
                      label: prompt,
                      tintColor: _pillTint(index),
                      enabled: !widget.isTyping,
                      onPressed: () => widget.onSend(prompt),
                    );
                  },
                ),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_promptHintOffset.value, 0),
                    child: child,
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: widget.isTyping ? null : widget.onSend,
                    decoration: const InputDecoration(
                      hintText: '和我聊聊你的状态、进度或想法',
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.isTyping
                        ? null
                        : () => widget.onSend(widget.controller.text),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 20),
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

class _PromptPill extends StatelessWidget {
  final String label;
  final Color tintColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _PromptPill({
    required this.label,
    required this.tintColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final background = tintColor.withValues(alpha: enabled ? 0.08 : 0.04);
    final border = tintColor.withValues(alpha: enabled ? 0.16 : 0.08);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.56,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMessageEntry extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedMessageEntry({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiMessage message;
  final AiInsightSnapshot? insight;

  const _MessageBubble({required this.message, required this.insight});

  @override
  Widget build(BuildContext context) {
    return switch (message.role) {
      MessageRole.user => _UserMessageBubble(message: message),
      MessageRole.system => _SystemMessageBubble(message: message),
      MessageRole.assistant => _AssistantMessageBubble(
        message: message,
        insight: insight,
      ),
    };
  }
}

class _UserMessageBubble extends StatelessWidget {
  final AiMessage message;

  const _UserMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.neuFlat,
          ),
          child: Text(
            message.content,
            style: AppTextStyle.body.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessageBubble extends StatelessWidget {
  final AiMessage message;
  final AiInsightSnapshot? insight;

  const _AssistantMessageBubble({required this.message, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: _AiAvatar(size: 28),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.neuFlat,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content, style: AppTextStyle.body),
                  if (insight != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    _AiInsightCard(insight: insight!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemMessageBubble extends StatelessWidget {
  final AiMessage message;

  const _SystemMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          message.content,
          style: AppTextStyle.caption.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _TypingMessageRow extends StatelessWidget {
  const _TypingMessageRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: _AiAvatar(size: 28),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: AppTheme.border),
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final double size;

  const _AiAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: AppTheme.border),
        boxShadow: size > 30 ? AppTheme.neuFlat : null,
      ),
      child: Center(
        child: PixelAvatar(
          config: _kAiCompanionAvatarConfig,
          size: size * 0.84,
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value * 3 - index).clamp(0.0, 1.0);
            final jump = math.sin(phase * math.pi) * 4;

            return Padding(
              padding: EdgeInsets.only(
                right: index == 2 ? 0 : 6,
                top: 4 - jump,
                bottom: jump,
              ),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.textSecondary.withValues(
                    alpha: 0.4 + phase * 0.5,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AiInsightCard extends StatefulWidget {
  final AiInsightSnapshot insight;

  const _AiInsightCard({required this.insight});

  @override
  State<_AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<_AiInsightCard> {
  bool _expanded = false;

  String _summaryText() {
    final streakText = widget.insight.longestStreak > 0
        ? '连续 ${widget.insight.longestStreak} 天'
        : '刚开始积累';
    final completionRate = (widget.insight.averageGoalProgress * 100).round();
    return '$streakText · 完成率 $completionRate%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _summaryText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingM),
                    child: _AiInsightDetails(insight: widget.insight),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeOutCubic,
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiInsightDetails extends StatelessWidget {
  final AiInsightSnapshot insight;

  const _AiInsightDetails({required this.insight});

  @override
  Widget build(BuildContext context) {
    final streakTarget = _nextStreakMilestone(insight.longestStreak);
    final streakProgress = streakTarget == 0
        ? 0.0
        : (insight.longestStreak / streakTarget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _InsightMetric(
                label: '活跃目标',
                value: '${insight.activeGoalCount}',
              ),
            ),
            Expanded(
              child: _InsightMetric(
                label: '今日推进',
                value: '${insight.checkedTodayCount}',
              ),
            ),
            Expanded(
              child: _InsightMetric(
                label: '专注时长',
                value: _focusLabel(insight.todayFocusMinutes),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        _InsightProgressRow(
          label: '步骤推进',
          value:
              '${insight.completedSteps}/${insight.totalSteps == 0 ? insight.completedSteps : insight.totalSteps}',
        ),
        const SizedBox(height: 8),
        PixelProgressBar(
          progress: insight.averageGoalProgress,
          height: 8,
          blockCount: 12,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.surfaceDeep,
        ),
        const SizedBox(height: AppTheme.spacingM),
        _InsightProgressRow(
          label: '连续势能',
          value: '${insight.longestStreak} / $streakTarget 天',
        ),
        const SizedBox(height: 8),
        PixelProgressBar(
          progress: streakProgress,
          height: 8,
          blockCount: 12,
          activeColor: AppTheme.accentStrong,
          inactiveColor: AppTheme.surfaceDeep,
        ),
        if (insight.moodSeries7d.any((item) => item != null)) ...[
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: Text(
                  '近 7 天心情',
                  style: AppTextStyle.label.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                _moodSummaryText(insight),
                style: AppTextStyle.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: _MoodSparkline(series: insight.moodSeries7d),
          ),
        ],
      ],
    );
  }

  int _nextStreakMilestone(int streak) {
    return AppConstants.streakMilestones.firstWhere(
      (value) => value > streak,
      orElse: () => AppConstants.streakMilestones.last,
    );
  }

  String _focusLabel(int minutes) {
    if (minutes <= 0) return '0 分钟';
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours 小时';
    return '$hours 小时 $remainingMinutes 分';
  }

  String _moodSummaryText(AiInsightSnapshot insight) {
    final avg = insight.moodAverage7d;
    final trend = switch (insight.moodTrend) {
      AiMoodTrendDirection.rising => '慢慢回升',
      AiMoodTrendDirection.falling => '有些疲惫',
      AiMoodTrendDirection.stable => '比较平稳',
      AiMoodTrendDirection.unknown => '继续观察',
    };

    if (avg == null) return trend;
    return '${avg.toStringAsFixed(1)} / 5 · $trend';
  }
}

class _InsightMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InsightMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.caption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InsightProgressRow extends StatelessWidget {
  final String label;
  final String value;

  const _InsightProgressRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.label.copyWith(color: AppTheme.textPrimary),
          ),
        ),
        Text(
          value,
          style: AppTextStyle.caption.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _MoodSparkline extends StatelessWidget {
  final List<double?> series;

  const _MoodSparkline({required this.series});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MoodSparklinePainter(series: series),
      child: const SizedBox.expand(),
    );
  }
}

class _MoodSparklinePainter extends CustomPainter {
  final List<double?> series;

  const _MoodSparklinePainter({required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    final available = <Offset>[];

    for (var index = 0; index < series.length; index++) {
      final value = series[index];
      if (value == null) continue;
      final x = series.length == 1
          ? size.width / 2
          : index / (series.length - 1) * size.width;
      final normalized = ((value - 1) / 4).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;
      available.add(Offset(x, y));
    }

    final gridPaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1;
    for (var row = 1; row <= 2; row++) {
      final y = size.height / 3 * row;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (available.isEmpty) return;

    if (available.length == 1) {
      final point = available.first;
      final dotPaint = Paint()..color = AppTheme.accentStrong;
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = AppTheme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    final path = Path()..moveTo(available.first.dx, available.first.dy);
    for (var index = 1; index < available.length; index++) {
      path.lineTo(available[index].dx, available[index].dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.accentStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = AppTheme.accentStrong;
    for (final point in available) {
      canvas.drawCircle(point, 3.5, dotPaint);
      canvas.drawCircle(
        point,
        3.5,
        Paint()
          ..color = AppTheme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodSparklinePainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

enum _ChatTimelineItemType { message, typing }

class _ChatTimelineItem {
  final _ChatTimelineItemType type;
  final AiMessage? message;
  final AiInsightSnapshot? insight;

  const _ChatTimelineItem._({required this.type, this.message, this.insight});

  const _ChatTimelineItem.message(
    AiMessage message, {
    AiInsightSnapshot? insight,
  }) : this._(
         type: _ChatTimelineItemType.message,
         message: message,
         insight: insight,
       );

  const _ChatTimelineItem.typing() : this._(type: _ChatTimelineItemType.typing);

  String get _identity => switch (type) {
    _ChatTimelineItemType.message => message!.id,
    _ChatTimelineItemType.typing => '__typing__',
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _ChatTimelineItem && _identity == other._identity;
  }

  @override
  int get hashCode => _identity.hashCode;
}
