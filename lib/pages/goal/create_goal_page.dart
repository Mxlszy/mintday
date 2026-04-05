import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/goal.dart';
import '../../providers/goal_provider.dart';

class CreateGoalPage extends StatefulWidget {
  const CreateGoalPage({super.key});

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final _visionController = TextEditingController();

  GoalCategory _selectedCategory = GoalCategory.habit;
  final List<TextEditingController> _stepControllers = [];
  DateTime? _deadline;
  bool _isSubmitting = false;

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
      appBar: AppBar(
        title: const Text('新建旅程'),
      ),
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
              title: '定义这段旅程',
              subtitle: '先写下你想推进什么，再决定它会以怎样的节奏展开。',
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              label: '目标名称',
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例如：30 天英语口语提升计划',
                ),
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
            _SectionCard(
              label: '类别',
              child: _buildCategorySelector(),
            ),
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
            _SectionCard(
              label: '拆解步骤',
              hint: '选填',
              child: _buildStepsEditor(),
            ),
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
                  : const Text('创建旅程'),
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
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _deadline ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppTheme.primary),
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
            const PixelIcon(
              icon: PixelIcons.clock,
              size: 16,
              color: AppTheme.primary,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                _deadline == null ? '选择截止日期' : AppUtils.friendlyDate(_deadline!),
                style: AppTextStyle.body.copyWith(
                  color:
                      _deadline == null ? AppTheme.textHint : AppTheme.textPrimary,
                ),
              ),
            ),
            if (_deadline != null)
              GestureDetector(
                onTap: () => setState(() => _deadline = null),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.textHint,
                ),
              ),
          ],
        ),
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
                    decoration: InputDecoration(
                      hintText: '第 ${index + 1} 步',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
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

    final goal = await context.read<GoalProvider>().createGoal(
          title: _titleController.text.trim(),
          category: _selectedCategory,
          reason: _reasonController.text.trim(),
          vision: _visionController.text.trim(),
          deadline: _deadline,
          steps: steps,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (goal != null) {
      AppUtils.showSnackBar(context, '新旅程已创建');
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(context, '创建失败，请稍后重试', isError: true);
    }
  }
}

class _IntroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _IntroCard({
    required this.title,
    required this.subtitle,
  });

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

  const _SectionCard({
    required this.label,
    this.hint,
    required this.child,
  });

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
