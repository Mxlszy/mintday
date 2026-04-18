import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/neumorphic.dart';
import '../core/pixel_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/utils.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';

class TodoChecklist extends StatefulWidget {
  const TodoChecklist({super.key, required this.goalId, required this.date});

  final String goalId;
  final DateTime date;

  @override
  State<TodoChecklist> createState() => _TodoChecklistState();
}

class _TodoChecklistState extends State<TodoChecklist> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _composerOpen = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus &&
            _controller.text.trim().isEmpty &&
            mounted) {
          setState(() => _composerOpen = false);
        }
      });
    _loadTodos();
  }

  @override
  void didUpdateWidget(covariant TodoChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dateChanged = !AppUtils.isSameDay(oldWidget.date, widget.date);
    if (oldWidget.goalId != widget.goalId || dateChanged) {
      _controller.clear();
      _composerOpen = false;
      _loadTodos();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadTodos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TodoProvider>().loadTodos(widget.goalId, widget.date);
    });
  }

  Future<void> _submitTodo() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final created = await context.read<TodoProvider>().addTodo(
      widget.goalId,
      text,
    );
    if (!mounted) return;

    setState(() => _submitting = false);
    if (created == null) {
      AppUtils.showSnackBar(context, '添加待办失败，请稍后重试', isError: true);
      return;
    }

    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _toggleTodo(TodoItem todo) async {
    final updated = await context.read<TodoProvider>().toggleTodo(todo.id);
    if (!mounted || updated != null) return;
    AppUtils.showSnackBar(context, '更新待办失败，请稍后重试', isError: true);
  }

  Future<void> _reorderTodos(
    List<TodoItem> todos,
    int oldIndex,
    int newIndex,
  ) async {
    final updated = List<TodoItem>.from(todos);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    final success = await context.read<TodoProvider>().reorderTodos(
      widget.goalId,
      widget.date,
      updated,
    );
    if (!mounted || success) return;
    AppUtils.showSnackBar(context, '排序保存失败，请稍后重试', isError: true);
  }

  void _openComposer() {
    if (_composerOpen) return;
    setState(() => _composerOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, _) {
        final todos = todoProvider.getTodos(widget.goalId, widget.date);
        final progress = todoProvider.progressFor(widget.goalId, widget.date);
        final isLoading =
            todoProvider.isLoadingGoalDate(widget.goalId, widget.date) &&
            todos.isEmpty;

        return NeuContainer(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          borderRadius: AppTheme.radiusXL,
          isSubtle: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChecklistHeader(date: widget.date, progress: progress),
              const SizedBox(height: AppTheme.spacingL),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (todos.isEmpty)
                const _ChecklistEmptyState()
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: todos.length,
                  proxyDecorator: (child, index, animation) {
                    return FadeTransition(
                      opacity: animation.drive(
                        Tween<double>(begin: 0.92, end: 1),
                      ),
                      child: ScaleTransition(
                        scale: animation.drive(
                          Tween<double>(begin: 0.98, end: 1),
                        ),
                        child: child,
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) =>
                      _reorderTodos(todos, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    final tile = _TodoTile(
                      todo: todo,
                      showDragHint: !todo.isCompleted && todos.length > 1,
                      onToggle: () => _toggleTodo(todo),
                    );

                    final child = todo.isCompleted
                        ? tile
                        : ReorderableDelayedDragStartListener(
                            index: index,
                            child: tile,
                          );

                    return Padding(
                      key: ValueKey(todo.id),
                      padding: EdgeInsets.only(
                        bottom: index == todos.length - 1
                            ? 0
                            : AppTheme.spacingS,
                      ),
                      child: Dismissible(
                        key: ValueKey('dismiss-${todo.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async => true,
                        onDismissed: (_) async {
                          final todoProvider = context.read<TodoProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await todoProvider.deleteTodo(
                            todo.id,
                          );
                          if (!mounted || success) return;
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: const Text('删除待办失败，请稍后重试'),
                                backgroundColor: AppTheme.bonusRose,
                              ),
                            );
                          todoProvider.loadTodos(
                            widget.goalId,
                            widget.date,
                            force: true,
                          );
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(
                              alpha: AppTheme.isDarkMode ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingL,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.error,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                ),
              const SizedBox(height: AppTheme.spacingL),
              _ComposerBar(
                controller: _controller,
                focusNode: _focusNode,
                isOpen: _composerOpen,
                isSubmitting: _submitting,
                onOpen: _openComposer,
                onSubmit: _submitTodo,
                onCancel: () {
                  _controller.clear();
                  _focusNode.unfocus();
                  setState(() => _composerOpen = false);
                },
                date: widget.date,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChecklistHeader extends StatelessWidget {
  const _ChecklistHeader({required this.date, required this.progress});

  final DateTime date;
  final TodoProgress progress;

  @override
  Widget build(BuildContext context) {
    final progressColor = progress.isCompleted
        ? AppTheme.bonusMint
        : AppTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelIcon(
                    icon: PixelIcons.calendar,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppUtils.fullFriendlyDate(date),
                    style: AppTextStyle.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: progressColor.withValues(
                  alpha: AppTheme.isDarkMode ? 0.2 : 0.12,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                progress.label,
                style: AppTextStyle.caption.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: AppTheme.surfaceDeep,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.ratio),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor,
                            progressColor.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (!progress.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            progress.isCompleted
                ? '今天的计划已经全部点亮。'
                : '还剩 ${progress.remaining} 项，慢慢划掉就好。',
            style: AppTextStyle.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.showDragHint,
  });

  final TodoItem todo;
  final VoidCallback onToggle;
  final bool showDragHint;

  @override
  Widget build(BuildContext context) {
    final foreground = todo.isCompleted
        ? AppTheme.textSecondary.withValues(alpha: 0.68)
        : AppTheme.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? AppTheme.primaryMuted.withValues(
                alpha: AppTheme.isDarkMode ? 0.26 : 0.9,
              )
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: todo.isCompleted
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TodoCheckbox(isChecked: todo.isCompleted, onTap: onToggle),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: _AnimatedStrikeText(
              text: todo.content,
              isCompleted: todo.isCompleted,
              color: foreground,
            ),
          ),
          if (showDragHint) ...[
            const SizedBox(width: AppTheme.spacingS),
            Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: AppTheme.textHint,
            ),
          ],
        ],
      ),
    );
  }
}

class _TodoCheckbox extends StatelessWidget {
  const _TodoCheckbox({required this.isChecked, required this.onTap});

  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isChecked ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color.lerp(AppTheme.surface, AppTheme.primary, value),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Color.lerp(AppTheme.border, AppTheme.primary, value)!,
                width: 1.4,
              ),
              boxShadow: value > 0.5 ? AppTheme.neuFlat : AppTheme.neuSubtle,
            ),
            child: Center(
              child: Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.7 + (value * 0.3),
                  child: const PixelIcon(
                    icon: PixelIcons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedStrikeText extends StatelessWidget {
  const _AnimatedStrikeText({
    required this.text,
    required this.isCompleted,
    required this.color,
  });

  final String text;
  final bool isCompleted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lineColor = AppTheme.textSecondary.withValues(alpha: 0.8);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          opacity: isCompleted ? 0.4 : 1,
          child: Text(
            text,
            style: AppTextStyle.body.copyWith(color: color, height: 1.45),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: isCompleted ? 1 : 0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.isOpen,
    required this.isSubmitting,
    required this.onOpen,
    required this.onSubmit,
    required this.onCancel,
    required this.date,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isOpen;
  final bool isSubmitting;
  final VoidCallback onOpen;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final placeholder = AppUtils.isSameDay(date, DateTime.now())
        ? '添加待办'
        : '为这一天补记待办';

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: NeuInset(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        child: isOpen
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration(
                        hintText: '输入一条具体的小计划',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  IconButton(
                    onPressed: isSubmitting ? null : onCancel,
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textHint,
                  ),
                  FilledButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(56, 44),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('添加'),
                  ),
                ],
              )
            : InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMuted,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: PixelIcon(
                            icon: PixelIcons.plus,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          placeholder,
                          style: AppTextStyle.body.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
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

class _ChecklistEmptyState extends StatelessWidget {
  const _ChecklistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingXL,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.border),
                  ),
                ),
                const Positioned(
                  top: 12,
                  child: PixelIcon(icon: PixelIcons.calendar, size: 30),
                ),
                Positioned(
                  right: 4,
                  bottom: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.neuSubtle,
                    ),
                    child: const Center(
                      child: PixelIcon(icon: PixelIcons.plus, size: 14),
                    ),
                  ),
                ),
                const Positioned(
                  left: 6,
                  bottom: 0,
                  child: PixelIcon(icon: PixelIcons.sprout, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            '今天还没有计划，添加一个吧',
            style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '把目标拆成今天能完成的小动作，会更容易开始。',
            style: AppTextStyle.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
