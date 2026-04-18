import 'package:flutter/material.dart';

import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/goal.dart';

typedef GoalFormSubmit = Future<bool> Function(GoalFormData data);

class GoalFormData {
  final String title;
  final GoalCategory category;
  final String? reason;
  final String? vision;
  final DateTime? deadline;
  final List<String> steps;
  final bool isPublic;

  const GoalFormData({
    required this.title,
    required this.category,
    this.reason,
    this.vision,
    this.deadline,
    this.steps = const [],
    this.isPublic = false,
  });
}

class GoalFormPage extends StatefulWidget {
  final String pageTitle;
  final String introTitle;
  final String introSubtitle;
  final String submitLabel;
  final String successMessage;
  final String errorMessage;
  final Goal? initialGoal;
  final GoalFormSubmit onSubmit;

  const GoalFormPage({
    super.key,
    required this.pageTitle,
    required this.introTitle,
    required this.introSubtitle,
    required this.submitLabel,
    required this.successMessage,
    required this.errorMessage,
    required this.onSubmit,
    this.initialGoal,
  });

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _reasonController;
  late final TextEditingController _visionController;

  late GoalCategory _selectedCategory;
  late final List<TextEditingController> _stepControllers;
  DateTime? _deadline;
  bool _isPublic = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.initialGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _reasonController = TextEditingController(text: goal?.reason ?? '');
    _visionController = TextEditingController(text: goal?.vision ?? '');
    _selectedCategory = goal?.category ?? GoalCategory.habit;
    _stepControllers = (goal?.steps ?? const <String>[])
        .map((step) => TextEditingController(text: step))
        .toList();
    _deadline = goal?.deadline;
    _isPublic = goal?.isPublic ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    _visionController.dispose();
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(widget.pageTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            120,
          ),
          children: [
            _IntroCard(
              title: widget.introTitle,
              subtitle: widget.introSubtitle,
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              label: '目标名称',
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '例如：30 天英语口语提升计划'),
                style: AppTextStyle.body,
                maxLength: 40,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请填写目标名称';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(label: '类别', child: _buildCategorySelector()),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              label: '为什么开始',
              hint: '选填',
              child: TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: '例如：想把一直想做的事真正坚持下来',
                ),
                style: AppTextStyle.body,
                maxLines: 3,
                maxLength: 200,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              label: '完成后会成为什么样的人',
              hint: '选填',
              child: TextFormField(
                controller: _visionController,
                decoration: const InputDecoration(
                  hintText: '例如：一个说到做到、能长期执行计划的人',
                ),
                style: AppTextStyle.body,
                maxLength: 100,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              label: '截止日期',
              hint: '选填',
              child: _buildDeadlinePicker(context),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(label: '社交可见性', child: _buildPublicSwitch()),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(label: '拆解步骤', hint: '选填', child: _buildStepsEditor()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            0,
            AppTheme.spacingL,
            AppTheme.spacingL,
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.submitLabel),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppTheme.spacingS,
      runSpacing: AppTheme.spacingS,
      children: GoalCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelIcon(
                  icon: PixelIcons.forCategory(category.value),
                  size: 14,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeadlinePicker(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      onTap: () async {
        final now = DateTime.now();
        final firstDate = DateTime(now.year, now.month, now.day);
        final initialDate = _deadline != null && _deadline!.isBefore(firstDate)
            ? firstDate
            : (_deadline ?? now.add(const Duration(days: 30)));

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: DateTime(now.year + 10),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppTheme.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _deadline = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            PixelIcon(
              icon: PixelIcons.clock,
              size: 16,
              color: AppTheme.primary,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                _deadline == null
                    ? '选择截止日期'
                    : AppUtils.friendlyDate(_deadline!),
                style: AppTextStyle.body.copyWith(
                  color: _deadline == null
                      ? AppTheme.textHint
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            if (_deadline != null)
              GestureDetector(
                onTap: () => setState(() => _deadline = null),
                child: Icon(Icons.close, size: 16, color: AppTheme.textHint),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicSwitch() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '公开这个目标',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('开启后，这个目标的打卡可以分享到成长广场。', style: AppTextStyle.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            activeTrackColor: AppTheme.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStepsEditor() {
    return Column(
      children: [
        ..._stepControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyle.caption.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(hintText: '第 ${index + 1} 步'),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.dispose();
                      _stepControllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _stepControllers.add(TextEditingController());
            });
          },
          child: const Text('添加步骤'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final steps = _stepControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final data = GoalFormData(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      reason: _normalizeOptional(_reasonController.text),
      vision: _normalizeOptional(_visionController.text),
      deadline: _deadline,
      steps: steps,
      isPublic: _isPublic,
    );

    bool success = false;
    try {
      success = await widget.onSubmit(data);
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppUtils.showSnackBar(context, widget.successMessage);
      Navigator.of(context).pop(true);
    } else {
      AppUtils.showSnackBar(context, widget.errorMessage, isError: true);
    }
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _IntroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _IntroCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: const Center(
              child: PixelIcon(
                icon: PixelIcons.flag,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.h3),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTextStyle.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _SectionCard({required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyle.label),
              if (hint != null) ...[
                const SizedBox(width: 6),
                Text(hint!, style: AppTextStyle.caption),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }
}
