import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_period.dart';
import '../theme/app_theme.dart';
import '../utils/category_style.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_components.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({
    super.key,
    required this.expenses,
    required this.onAdd,
    required this.onDelete,
    required this.currencyCode,
    required this.convertedAmounts,
    required this.conversionUnavailable,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<Expense> expenses;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final String currencyCode;
  final Map<String, double> convertedAmounts;
  final bool conversionUnavailable;
  final ExpensePeriod period;
  final ValueChanged<ExpensePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = expenses.where((item) => period.includes(item.date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = _formattedTotal(sorted);

    return SafeArea(
      child: AppContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Expenses',
                subtitle:
                    '${sorted.length} ${sorted.length == 1 ? 'entry' : 'entries'}',
                trailing: IconButton.filledTonal(
                  tooltip: 'Add expense',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ExpensePeriod.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final option = ExpensePeriod.values[index];
                    return ChoiceChip(
                      label: Text(option.label),
                      selected: option == period,
                      onSelected: (_) => onPeriodChanged(option),
                      showCheckmark: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _TotalCard(periodLabel: period.label, total: total),
              const SizedBox(height: 18),
              Expanded(
                child: sorted.isEmpty
                    ? _EmptyExpenses(
                        onAdd: onAdd,
                        period: period,
                        hasAnyExpenses: expenses.isNotEmpty,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 116),
                        itemCount: sorted.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final expense = sorted[index];
                          return _ExpenseCard(
                            expense: expense,
                            currencyCode: currencyCode,
                            convertedAmount: convertedAmounts[expense.id],
                            conversionUnavailable: conversionUnavailable,
                            onDelete: () => onDelete(expense.id),
                            onViewReceipt: expense.receiptImageUrl == null
                                ? null
                                : () => _showReceipt(context, expense),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedTotal(List<Expense> selected) {
    if (selected.isEmpty) return CurrencyFormatter.format(0, currencyCode);
    if (conversionUnavailable) return 'Rate unavailable';
    if (selected.any((item) => !convertedAmounts.containsKey(item.id))) {
      return 'Converting…';
    }
    final total = selected.fold<double>(
      0,
      (sum, item) => sum + convertedAmounts[item.id]!,
    );
    return CurrencyFormatter.format(total, currencyCode);
  }

  void _showReceipt(BuildContext context, Expense expense) {
    final imageUrl = expense.receiptImageUrl;
    if (imageUrl == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${expense.title} receipt',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close receipt',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const SizedBox(
                            height: 320,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Could not load the saved receipt image.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.periodLabel, required this.total});

  final String periodLabel;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const AppIconTile(
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$periodLabel total',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.76)),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    total,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({
    required this.onAdd,
    required this.period,
    required this.hasAnyExpenses,
  });

  final VoidCallback onAdd;
  final ExpensePeriod period;
  final bool hasAnyExpenses;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: hasAnyExpenses
            ? 'No expenses for ${period.label.toLowerCase()}'
            : 'No expenses yet',
        message: hasAnyExpenses
            ? 'Choose another period or add an expense.'
            : 'Your added expenses will appear here.',
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add expense'),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onDelete,
    required this.currencyCode,
    required this.convertedAmount,
    required this.conversionUnavailable,
    required this.onViewReceipt,
  });

  final Expense expense;
  final VoidCallback onDelete;
  final String currencyCode;
  final double? convertedAmount;
  final bool conversionUnavailable;
  final VoidCallback? onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = CategoryStyle.forName(expense.category);
    final date = expense.date;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final amount = convertedAmount != null
        ? '-${CurrencyFormatter.format(convertedAmount!, currencyCode)}'
        : (conversionUnavailable ? 'Rate unavailable' : 'Converting…');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Row(
        children: [
          Tooltip(
            message: onViewReceipt == null
                ? expense.category
                : 'View saved receipt',
            child: InkWell(
              onTap: onViewReceipt,
              borderRadius: BorderRadius.circular(14),
              child: AppIconTile(
                icon: onViewReceipt == null
                    ? visual.icon
                    : Icons.receipt_long_outlined,
                color: visual.color,
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category} • $formattedDate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 124),
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete expense',
            onPressed: onDelete,
            color: theme.colorScheme.onSurfaceVariant,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
