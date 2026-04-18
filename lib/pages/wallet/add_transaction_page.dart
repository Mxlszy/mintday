import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/neumorphic.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionType initialType;

  const AddTransactionPage({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late TransactionType _selectedType;
  final TextEditingController _noteController = TextEditingController();

  String _amountInput = '0';
  String? _selectedCategoryId;
  String? _selectedGoalId;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final categories = transactionProvider.categoriesForType(_selectedType);
    final activeGoals = goalProvider.activeGoals;

    if (categories.isNotEmpty &&
        !categories.any((item) => item.id == _selectedCategoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedCategoryId = categories.first.id);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('记一笔')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            140,
          ),
          children: [
            _SectionCard(
              title: '收支类型',
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: '收入',
                      isSelected: _selectedType == TransactionType.income,
                      color: AppTheme.bonusMint,
                      onTap: () =>
                          _switchType(TransactionType.income, categories),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _TypeButton(
                      label: '支出',
                      isSelected: _selectedType == TransactionType.expense,
                      color: AppTheme.error,
                      onTap: () =>
                          _switchType(TransactionType.expense, categories),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _AmountPanel(amountInput: _amountInput, onClear: _clearAmount),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              title: '金额输入',
              child: _NumberKeyboard(onKeyTap: _handleKeyboardTap),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              title: '分类',
              child: transactionProvider.isLoading && categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.spacingXL,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _CategoryGrid(
                      categories: categories,
                      selectedCategoryId: _selectedCategoryId,
                      onSelect: (categoryId) {
                        setState(() => _selectedCategoryId = categoryId);
                      },
                    ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              title: '关联目标',
              subtitle: '可选，用于记录你为某个目标投入了多少',
              child: DropdownButtonFormField<String>(
                key: ValueKey(_selectedGoalId ?? ''),
                initialValue: _selectedGoalId ?? '',
                decoration: const InputDecoration(hintText: '选择要关联的目标'),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('暂不关联目标'),
                  ),
                  ...activeGoals.map(
                    (goal) => DropdownMenuItem<String>(
                      value: goal.id,
                      child: Text(goal.title),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(
                    () => _selectedGoalId = value == null || value.isEmpty
                        ? null
                        : value,
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              title: '备注',
              subtitle: '可选',
              child: TextField(
                controller: _noteController,
                maxLength: 40,
                maxLines: 2,
                decoration: const InputDecoration(hintText: '写点备注，比如买书、聚餐、奖金'),
                style: AppTextStyle.body,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _SectionCard(
              title: '日期',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          AppUtils.fullDateLabel(_selectedDate),
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textHint,
                      ),
                    ],
                  ),
                ),
              ),
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
            onPressed: _isSubmitting || categories.isEmpty ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('确认记账'),
            ),
          ),
        ),
      ),
    );
  }

  void _switchType(
    TransactionType type,
    List<TransactionCategory> currentCategories,
  ) {
    if (_selectedType == type) return;

    setState(() {
      _selectedType = type;
      if (currentCategories.any((item) => item.id == _selectedCategoryId)) {
        _selectedCategoryId = null;
      }
    });
  }

  void _handleKeyboardTap(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountInput.length <= 1) {
          _amountInput = '0';
          return;
        }
        _amountInput = _amountInput.substring(0, _amountInput.length - 1);
        if (_amountInput.endsWith('.')) {
          _amountInput = _amountInput.substring(0, _amountInput.length - 1);
        }
        if (_amountInput.isEmpty) {
          _amountInput = '0';
        }
        return;
      }

      if (key == '.') {
        if (_amountInput.contains('.')) return;
        _amountInput = '$_amountInput.';
        return;
      }

      if (_amountInput.contains('.')) {
        final decimals = _amountInput.split('.').last;
        if (decimals.length >= 2) return;
      }

      if (_amountInput == '0') {
        _amountInput = key;
      } else {
        _amountInput += key;
      }
    });
  }

  void _clearAmount() {
    setState(() => _amountInput = '0');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.primary)),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountInput) ?? 0;
    if (amount <= 0) {
      AppUtils.showSnackBar(context, '请输入正确金额', isError: true);
      return;
    }
    if (_selectedCategoryId == null) {
      AppUtils.showSnackBar(context, '请选择分类', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final transaction = await context
        .read<TransactionProvider>()
        .addTransaction(
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId!,
          goalId: _selectedGoalId,
          note: _noteController.text,
          date: _selectedDate,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (transaction == null) {
      AppUtils.showSnackBar(context, '保存失败，请稍后重试', isError: true);
      return;
    }

    AppUtils.showSnackBar(context, '已记录这一笔');
    Navigator.of(context).pop();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.h3),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: AppTextStyle.bodySmall),
          ],
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: isSelected ? color : AppTheme.border),
          boxShadow: isSelected ? AppTheme.neuFlat : AppTheme.neuSubtle,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.body.copyWith(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountPanel extends StatelessWidget {
  final String amountInput;
  final VoidCallback onClear;

  const _AmountPanel({required this.amountInput, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final preview = double.tryParse(amountInput);
    final display = AppUtils.formatCurrency(preview ?? 0, absolute: true);

    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      borderRadius: AppTheme.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('金额', style: AppTextStyle.label),
              const Spacer(),
              TextButton(onPressed: onClear, child: const Text('清空')),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            display,
            style: AppTextStyle.h1.copyWith(
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            preview == null
                ? '请输入有效金额'
                : '将保存为 ${AppUtils.formatCurrency(preview, absolute: true)}',
            style: AppTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NumberKeyboard extends StatelessWidget {
  final ValueChanged<String> onKeyTap;

  const _NumberKeyboard({required this.onKeyTap});

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppTheme.spacingM,
        crossAxisSpacing: AppTheme.spacingM,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final key = _keys[index];
        return GestureDetector(
          onTap: () => onKeyTap(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.neuSubtle,
            ),
            child: Center(
              child: Text(
                key,
                style: AppTextStyle.h2.copyWith(fontSize: key == '⌫' ? 24 : 28),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<TransactionCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          '暂无可用分类',
          style: AppTextStyle.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppTheme.spacingM,
        crossAxisSpacing: AppTheme.spacingM,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category.id == selectedCategoryId;

        return GestureDetector(
          onTap: () => onSelect(category.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryMuted : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
              boxShadow: isSelected ? AppTheme.neuFlat : AppTheme.neuSubtle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 10),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.caption.copyWith(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
