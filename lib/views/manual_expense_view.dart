import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/category_style.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_components.dart';

class ManualExpenseView extends StatefulWidget {
  const ManualExpenseView({
    super.key,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
    this.initialDate,
    this.initialNote,
    this.initialCurrencyCode,
  });

  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;
  final DateTime? initialDate;
  final String? initialNote;
  final String? initialCurrencyCode;

  @override
  State<ManualExpenseView> createState() => _ManualExpenseViewState();
}

class _ManualExpenseViewState extends State<ManualExpenseView> {
  static const _categories = [
    'Food',
    'Transportation',
    'Shopping',
    'Bills',
    'Education',
    'Entertainment',
    'Health',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _selectedCurrencyCode;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  bool get _isReviewingScan => widget.initialAmount != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.initialNote);
    if (_categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedCurrencyCode = CurrencyFormatter.normalize(
      widget.initialCurrencyCode,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        currencyCode: _selectedCurrencyCode,
      ),
    );
  }

  InputDecoration _decoration({required String hint, required IconData icon}) {
    return InputDecoration(hintText: hint, prefixIcon: Icon(icon));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReviewingScan ? 'Review Scan' : 'Add Expense'),
      ),
      body: SafeArea(
        child: AppContentWidth(
          maxWidth: 680,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: _isReviewingScan
                        ? 'Check scanned details'
                        : 'Manual Expense',
                    subtitle: _isReviewingScan
                        ? 'AI can make mistakes. Confirm everything before saving.'
                        : 'Add the details now and keep your spending organized.',
                  ),
                  if (_isReviewingScan) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Review the merchant, amount, category, and date before saving.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(text: 'Expense name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(
                            hint: 'e.g. Lunch',
                            icon: Icons.edit_note_rounded,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter an expense name'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel(text: 'Amount'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration:
                              _decoration(
                                hint: '0.00',
                                icon: Icons.payments_rounded,
                              ).copyWith(
                                prefixText:
                                    '${CurrencyFormatter.symbol(_selectedCurrencyCode)} ',
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Center(
                                    widthFactor: 1,
                                    child: Text(
                                      _selectedCurrencyCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an amount';
                            }
                            final amount = double.tryParse(value.trim());
                            if (amount == null) {
                              return 'Please enter a valid amount';
                            }
                            if (amount <= 0) {
                              return 'Amount must be greater than zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel(text: 'Category'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: _decoration(
                            hint: 'Select category',
                            icon: Icons.category_rounded,
                          ),
                          items: _categories.map((category) {
                            final visual = CategoryStyle.forName(category);
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    visual.icon,
                                    size: 18,
                                    color: visual.color,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel(text: 'Date'),
                        const SizedBox(height: 8),
                        _DateField(date: _selectedDate, onTap: _selectDate),
                        const SizedBox(height: 20),
                        _FieldLabel(text: 'Note (optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(
                            hint: 'Add a note…',
                            icon: Icons.notes_rounded,
                          ).copyWith(alignLabelWithHint: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: _saveExpense,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save Expense'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
