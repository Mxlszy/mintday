import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/neumorphic.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/transaction.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';

class WalletLedgerTab extends StatefulWidget {
  const WalletLedgerTab({super.key});

  @override
  State<WalletLedgerTab> createState() => _WalletLedgerTabState();
}

class _WalletLedgerTabState extends State<WalletLedgerTab> {
  static const int _initialPage = 1200;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _selectedMonth = _baseMonth;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final offset = page - _initialPage;
    return DateTime(_baseMonth.year, _baseMonth.month + offset);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, GoalProvider>(
      builder: (context, transactionProvider, goalProvider, _) {
        final month = _selectedMonth;
        final income = transactionProvider.getMonthlyIncome(
          month.year,
          month.month,
        );
        final expense = transactionProvider.getMonthlyExpense(
          month.year,
          month.month,
        );
        final balance = transactionProvider.getMonthlyBalance(
          month.year,
          month.month,
        );
        final monthTransactions = transactionProvider.getTransactionsForMonth(
          month.year,
          month.month,
        );
        final dailyExpenses = transactionProvider.getDailyExpenses(
          month.year,
          month.month,
        );
        final breakdown = transactionProvider.getCategoryBreakdown(
          month.year,
          month.month,
        );
        final recentTransactions = transactionProvider.getRecentTransactions(
          20,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            0,
            AppTheme.spacingL,
            120,
          ),
          children: [
            SizedBox(
              height: 210,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _selectedMonth = _monthForPage(page));
                },
                itemBuilder: (context, index) {
                  final pageMonth = _monthForPage(index);
                  return _MonthOverviewCard(
                    month: pageMonth,
                    income: transactionProvider.getMonthlyIncome(
                      pageMonth.year,
                      pageMonth.month,
                    ),
                    expense: transactionProvider.getMonthlyExpense(
                      pageMonth.year,
                      pageMonth.month,
                    ),
                    balance: transactionProvider.getMonthlyBalance(
                      pageMonth.year,
                      pageMonth.month,
                    ),
                    transactionCount: transactionProvider
                        .getTransactionsForMonth(
                          pageMonth.year,
                          pageMonth.month,
                        )
                        .length,
                    activeExpenseDays: transactionProvider
                        .getDailyExpenses(pageMonth.year, pageMonth.month)
                        .length,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '左右滑动切换月份',
              style: AppTextStyle.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            _LedgerSectionHeader(
              title: '分类支出',
              subtitle:
                  '${AppUtils.monthLabel(month)} 共支出 ${AppUtils.formatCurrency(expense, absolute: true)}',
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (transactionProvider.isLoading &&
                transactionProvider.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _ExpenseBreakdownCard(
                expense: expense,
                breakdown: breakdown,
                transactionCount: monthTransactions.length,
                activeExpenseDays: dailyExpenses.length,
              ),
            const SizedBox(height: AppTheme.spacingL),
            const _LedgerSectionHeader(
              title: '最近记录',
              subtitle: '按时间倒序展示最近 20 条',
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (recentTransactions.isEmpty)
              const _LedgerEmptyState()
            else
              ..._buildTransactionGroups(
                context,
                recentTransactions,
                transactionProvider,
                goalProvider,
              ),
            const SizedBox(height: AppTheme.spacingS),
            if (recentTransactions.isNotEmpty)
              _QuickSummaryStrip(
                income: income,
                expense: expense,
                balance: balance,
                month: month,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildTransactionGroups(
    BuildContext context,
    List<Transaction> transactions,
    TransactionProvider transactionProvider,
    GoalProvider goalProvider,
  ) {
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (final transaction in transactions) {
      final currentDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      final showHeader =
          lastDate == null || !AppUtils.isSameDay(lastDate, currentDate);
      if (showHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.spacingS,
              bottom: AppTheme.spacingS,
            ),
            child: Text(
              AppUtils.fullDateLabel(currentDate),
              style: AppTextStyle.label,
            ),
          ),
        );
        lastDate = currentDate;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: _TransactionListItem(
            transaction: transaction,
            category: transactionProvider.getCategoryById(
              transaction.categoryId,
            ),
            goalTitle: transaction.goalId == null
                ? null
                : goalProvider.getGoalById(transaction.goalId!)?.title,
          ),
        ),
      );
    }

    return widgets;
  }
}

class _MonthOverviewCard extends StatelessWidget {
  final DateTime month;
  final double income;
  final double expense;
  final double balance;
  final int transactionCount;
  final int activeExpenseDays;

  const _MonthOverviewCard({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
    required this.transactionCount,
    required this.activeExpenseDays,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = balance < 0 ? AppTheme.error : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F6FB)],
        ),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.neuSubtle,
                ),
                child: Center(
                  child: PixelIcon(
                    icon: PixelIcons.chart,
                    size: 26,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppUtils.monthLabel(month), style: AppTextStyle.h3),
                    const SizedBox(height: 4),
                    Text(
                      transactionCount == 0
                          ? '这个月还没有记账，随手记一笔吧'
                          : '本月共 $transactionCount 笔记录，$activeExpenseDays 天有支出',
                      style: AppTextStyle.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: '本月收入',
                  value: AppUtils.formatCurrency(income, absolute: true),
                  color: AppTheme.bonusMint,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _OverviewStat(
                  label: '本月支出',
                  value: AppUtils.formatCurrency(expense, absolute: true),
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _OverviewStat(
                  label: '结余',
                  value: AppUtils.formatCurrency(balance),
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LedgerSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyle.h3),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyle.bodySmall),
      ],
    );
  }
}

class _ExpenseBreakdownCard extends StatelessWidget {
  final double expense;
  final List<CategoryExpenseBreakdown> breakdown;
  final int transactionCount;
  final int activeExpenseDays;

  const _ExpenseBreakdownCard({
    required this.expense,
    required this.breakdown,
    required this.transactionCount,
    required this.activeExpenseDays,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: breakdown.isEmpty
          ? Column(
              children: [
                const SizedBox(height: AppTheme.spacingS),
                Text('这个月还没有支出记录', style: AppTextStyle.h3),
                const SizedBox(height: 8),
                Text(
                  '记下餐饮、学习投资或其他花费后，这里会自动汇总占比。',
                  style: AppTextStyle.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),
                _BreakdownMeta(
                  expense: expense,
                  transactionCount: transactionCount,
                  activeExpenseDays: activeExpenseDays,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BreakdownMeta(
                  expense: expense,
                  transactionCount: transactionCount,
                  activeExpenseDays: activeExpenseDays,
                ),
                const SizedBox(height: AppTheme.spacingL),
                ...breakdown.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: _BreakdownRow(item: item),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BreakdownMeta extends StatelessWidget {
  final double expense;
  final int transactionCount;
  final int activeExpenseDays;

  const _BreakdownMeta({
    required this.expense,
    required this.transactionCount,
    required this.activeExpenseDays,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            label: '总支出',
            value: AppUtils.formatCurrency(expense, absolute: true),
            color: AppTheme.error,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _MiniMetric(
            label: '记录笔数',
            value: '$transactionCount 笔',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _MiniMetric(
            label: '支出天数',
            value: '$activeExpenseDays 天',
            color: AppTheme.bonusBlue,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyle.caption),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final CategoryExpenseBreakdown item;

  const _BreakdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * item.share.clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.category.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.category.name,
                    style: AppTextStyle.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppUtils.formatCurrency(item.amount, absolute: true),
                  style: AppTextStyle.body.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${(item.share * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: width,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.error, AppTheme.bonusRose],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final TransactionCategory? category;
  final String? goalTitle;

  const _TransactionListItem({
    required this.transaction,
    required this.category,
    required this.goalTitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = transaction.type == TransactionType.income
        ? AppTheme.bonusMint
        : AppTheme.error;
    final title =
        (transaction.note != null && transaction.note!.trim().isNotEmpty)
        ? transaction.note!.trim()
        : (category?.name ?? '未分类');

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除记录'),
            content: const Text('这笔记录删除后无法恢复，确定继续吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  '删除',
                  style: AppTextStyle.body.copyWith(color: AppTheme.error),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return false;

        final deleted = await context
            .read<TransactionProvider>()
            .deleteTransaction(transaction.id);
        if (!deleted && context.mounted) {
          AppUtils.showSnackBar(context, '删除失败，请稍后重试', isError: true);
        }
        return deleted;
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: NeuContainer(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        borderRadius: AppTheme.radiusL,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Center(
                child: Text(
                  category?.emoji ?? '🧾',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppUtils.formatCurrency(
                          transaction.amount,
                          signed: true,
                        ),
                        style: AppTextStyle.body.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: category?.name ?? '未分类',
                        color: AppTheme.surfaceVariant,
                        textColor: AppTheme.textSecondary,
                      ),
                      if (goalTitle != null)
                        _InfoChip(
                          label: goalTitle!,
                          color: AppTheme.primaryMuted,
                          textColor: AppTheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _InfoChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LedgerEmptyState extends StatelessWidget {
  const _LedgerEmptyState();

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          const Text('🧾', style: TextStyle(fontSize: 42)),
          const SizedBox(height: AppTheme.spacingM),
          Text('还没有账本记录', style: AppTextStyle.h3),
          const SizedBox(height: 8),
          Text(
            '先记下今天的一笔收入或支出，后面就能看到月度概览和分类统计。',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickSummaryStrip extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final DateTime month;

  const _QuickSummaryStrip({
    required this.income,
    required this.expense,
    required this.balance,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '${AppUtils.monthLabel(month)} 收入 ${AppUtils.formatCurrency(income, absolute: true)}，支出 ${AppUtils.formatCurrency(expense, absolute: true)}，结余 ${AppUtils.formatCurrency(balance)}',
        style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
