import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/category_style.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_components.dart';
import '../widgets/motion_reveal.dart';

class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({
    super.key,
    required this.expenses,
    required this.recentExpenses,
    required this.currencyCode,
    required this.convertedAmounts,
    required this.isConverting,
    required this.conversionUnavailable,
    required this.onAddManually,
    required this.onScanReceipt,
    required this.onViewAll,
    required this.onRefresh,
  });

  final List<Expense> expenses;
  final List<Expense> recentExpenses;
  final String currencyCode;
  final Map<String, double> convertedAmounts;
  final bool isConverting;
  final bool conversionUnavailable;
  final VoidCallback onAddManually;
  final VoidCallback onScanReceipt;
  final VoidCallback onViewAll;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 68,
                20,
                112,
              ),
              sliver: SliverToBoxAdapter(
                child: AppContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MotionReveal(child: _buildHero(context)),
                      const SizedBox(height: 12),
                      MotionReveal(
                        delay: const Duration(milliseconds: 70),
                        child: _buildPeriodSummary(context),
                      ),
                      const SizedBox(height: 18),
                      MotionReveal(
                        delay: const Duration(milliseconds: 140),
                        child: _buildQuickActions(context),
                      ),
                      const SizedBox(height: 26),
                      MotionReveal(
                        delay: const Duration(milliseconds: 210),
                        child: _buildRecentExpenses(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final label = _formattedTotal(expenses);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -54,
            child: _DecorativeOrb(
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 72,
            bottom: -70,
            child: _DecorativeOrb(
              size: 130,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TOTAL SPENDING',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'All time',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: _animationDuration(context),
                  child: FittedBox(
                    key: ValueKey(label),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 39,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expenses.isEmpty
                      ? 'Your spending overview will appear here.'
                      : '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'} across your categories',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _PeriodCard(
            title: 'Today',
            value: _formattedTotal(expenses.where(_isToday)),
            icon: Icons.today_rounded,
            color: AppColors.warning,
          ),
          _PeriodCard(
            title: 'This Month',
            value: _formattedTotal(expenses.where(_isThisMonth)),
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF0EA5E9),
          ),
        ];
        if (constraints.maxWidth < 360) {
          return Column(
            children: [cards.first, const SizedBox(height: 12), cards.last],
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
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Expense', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.edit_note_rounded,
                title: 'Manual',
                subtitle: 'Enter details',
                color: AppColors.primary,
                onTap: onAddManually,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.document_scanner_outlined,
                title: 'AI Scan',
                subtitle: 'Scan a receipt',
                color: AppColors.secondary,
                onTap: onScanReceipt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentExpenses(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent Expenses', style: theme.textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: onViewAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: _animationDuration(context),
          child: recentExpenses.isEmpty
              ? const AppEmptyState(
                  key: ValueKey('empty'),
                  icon: Icons.receipt_long_outlined,
                  title: 'No expenses yet',
                  message: 'Add your first expense to start building a clearer money picture.',
                )
              : AppCard(
                  key: ValueKey(
                    recentExpenses.map((item) => item.id).join('|'),
                  ),
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < recentExpenses.length;
                        index++
                      ) ...[
                        _RecentExpenseRow(
                          expense: recentExpenses[index],
                          amount: _formattedExpense(recentExpenses[index]),
                        ),
                        if (index != recentExpenses.length - 1)
                          const Divider(indent: 76, endIndent: 18),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  String _formattedExpense(Expense expense) {
    final converted = convertedAmounts[expense.id];
    if (converted != null) {
      return '-${CurrencyFormatter.format(converted, currencyCode)}';
    }
    return isConverting ? 'Converting…' : 'Rate unavailable';
  }

  String _formattedTotal(Iterable<Expense> selectedExpenses) {
    if (isConverting) return 'Converting…';
    if (conversionUnavailable) return 'Rate unavailable';
    final total = selectedExpenses.fold<double>(
      0,
      (sum, expense) => sum + (convertedAmounts[expense.id] ?? 0),
    );
    return CurrencyFormatter.format(total, currencyCode);
  }

  bool _isToday(Expense expense) {
    final now = DateTime.now();
    return expense.date.year == now.year &&
        expense.date.month == now.month &&
        expense.date.day == now.day;
  }

  bool _isThisMonth(Expense expense) {
    final now = DateTime.now();
    return expense.date.year == now.year && expense.date.month == now.month;
  }

  Duration _animationDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 220);
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          AppIconTile(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, color: color),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseRow extends StatelessWidget {
  const _RecentExpenseRow({required this.expense, required this.amount});

  final Expense expense;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = CategoryStyle.forName(expense.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppIconTile(icon: category.icon, color: category.color, size: 44),
          const SizedBox(width: 14),
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
                const SizedBox(height: 3),
                Text(
                  expense.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
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
        ],
      ),
    );
  }
}
