import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/category_style.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_components.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({
    super.key,
    required this.expenses,
    required this.currencyCode,
    required this.convertedAmounts,
  });

  final List<Expense> expenses;
  final String currencyCode;
  final Map<String, double> convertedAmounts;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + (convertedAmounts[expense.id] ?? 0),
    );
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + (convertedAmounts[expense.id] ?? 0),
        ifAbsent: () => convertedAmounts[expense.id] ?? 0,
      );
    }
    final categories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 116),
          children: [
            const AppPageHeader(
              title: 'Insights',
              subtitle: 'Understand your spending at a glance.',
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _StatCard(
                    label: 'Total spent',
                    value: CurrencyFormatter.format(total, currencyCode),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Average expense',
                    value: CurrencyFormatter.format(
                      expenses.isEmpty ? 0 : total / expenses.length,
                      currencyCode,
                    ),
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF0EA5E9),
                  ),
                ];
                if (constraints.maxWidth < 360) {
                  return Column(
                    children: [
                      cards.first,
                      const SizedBox(height: 12),
                      cards.last,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cards.first),
                    const SizedBox(width: 12),
                    Expanded(child: cards.last),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spending by category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (categories.isNotEmpty)
                  Text(
                    '${categories.length} categories',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (categories.isEmpty)
              const AppEmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'No insights yet',
                message: 'Add an expense to see your spending breakdown.',
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var index = 0; index < categories.length; index++) ...[
                      _CategoryBar(
                        category: categories[index].key,
                        currencyCode: currencyCode,
                        amount: categories[index].value,
                        fraction: total == 0
                            ? 0
                            : categories[index].value / total,
                      ),
                      if (index != categories.length - 1)
                        const Divider(indent: 68, endIndent: 18),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, color: color),
          const SizedBox(height: 16),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.fraction,
    required this.currencyCode,
  });

  final String category;
  final double amount;
  final double fraction;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = CategoryStyle.forName(category);
    final percentage = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppIconTile(icon: visual.icon, color: visual.color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0, 1),
                          minHeight: 7,
                          backgroundColor: visual.color.withValues(alpha: 0.12),
                          color: visual.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyFormatter.format(amount, currencyCode),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
