import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/dashboard_controller.dart';
import '../models/expense.dart';
import '../models/expense_period.dart';
import '../services/cloudinary_service.dart';
import '../services/currency_conversion_service.dart';
import '../services/expense_service.dart';
import '../services/receipt_scan_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_components.dart';
import 'dashboard_home_view.dart';
import 'expenses_view.dart';
import 'insights_view.dart';
import 'manual_expense_view.dart';
import 'settings_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.userId,
    required this.onSignOut,
    required this.isDarkMode,
    required this.userEmail,
    this.onDarkModeChanged,
    this.receiptScanService,
    this.initialCurrencyCode = 'PHP',
    this.currencyConversionService,
    this.expenseService,
    this.cloudinaryService,
  });

  final String userId;
  final Future<void> Function() onSignOut;
  final bool isDarkMode;
  final String userEmail;
  final ValueChanged<bool>? onDarkModeChanged;
  final ReceiptScanService? receiptScanService;
  final String initialCurrencyCode;
  final CurrencyConversionService? currencyConversionService;
  final ExpenseService? expenseService;
  final CloudinaryService? cloudinaryService;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardController _controller = DashboardController();
  late final ReceiptScanService _receiptScanService =
      widget.receiptScanService ?? ReceiptScanService();
  late final ExpenseService _expenseService =
      widget.expenseService ?? ExpenseService();
  late final CloudinaryService _cloudinaryService =
      widget.cloudinaryService ?? CloudinaryService();
  late final CurrencyConversionService _conversionService =
      widget.currencyConversionService ?? CurrencyConversionService();

  StreamSubscription<List<Expense>>? _expensesSubscription;
  int _selectedIndex = 0;
  ExpensePeriod _expensePeriod = ExpensePeriod.allTime;
  bool _isScanning = false;
  bool _isSigningOut = false;
  late String _currencyCode;
  Map<String, double> _convertedAmounts = const {};
  bool _isConvertingCurrencies = false;
  String? _currencyConversionError;
  int _conversionGeneration = 0;

  String get _activeCurrencyCode => CurrencyFormatter.normalize(_currencyCode);

  @override
  void initState() {
    super.initState();
    _currencyCode = CurrencyFormatter.normalize(widget.initialCurrencyCode);
    _expensesSubscription = _expenseService
        .watchExpenses(widget.userId)
        .listen(_handleExpensesChanged, onError: _handleExpensesError);
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: _selectedIndex == 0,
      extendBody: true,
      appBar: _selectedIndex == 0 ? _buildAppBar(context) : null,
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildSelectedPage(),
        ),
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSelectedPage() {
    return switch (_selectedIndex) {
      1 => ExpensesView(
        expenses: _controller.expenses,
        currencyCode: _activeCurrencyCode,
        convertedAmounts: _convertedAmounts,
        conversionUnavailable: _currencyConversionError != null,
        period: _expensePeriod,
        onPeriodChanged: (period) => setState(() => _expensePeriod = period),
        onAdd: _openManualExpense,
        onDelete: _deleteExpense,
      ),
      2 => InsightsView(
        expenses: _controller.expenses,
        currencyCode: _activeCurrencyCode,
        convertedAmounts: _convertedAmounts,
      ),
      3 => SettingsView(
        userEmail: widget.userEmail,
        signingOut: _isSigningOut,
        onSignOut: _signOut,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        currencyCode: _activeCurrencyCode,
        onCurrencyChanged: _changeCurrency,
      ),
      _ => DashboardHomeView(
        expenses: _controller.expenses,
        recentExpenses: _controller.recentExpenses,
        currencyCode: _activeCurrencyCode,
        convertedAmounts: _convertedAmounts,
        isConverting: _isConvertingCurrencies,
        conversionUnavailable: _currencyConversionError != null,
        onAddManually: _openManualExpense,
        onScanReceipt: _scanReceipt,
        onViewAll: () => setState(() => _selectedIndex = 1),
        onRefresh: _refreshCurrencyConversions,
      ),
    };
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      foregroundColor: theme.colorScheme.onSurface,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _greetingForNow(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text('Spendi', style: theme.textTheme.titleLarge),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton.filledTonal(
            tooltip: 'Log out',
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, size: 21),
          ),
        ),
      ],
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.onSignOut();
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _changeCurrency(String currencyCode) {
    final normalized = CurrencyFormatter.normalize(currencyCode);
    if (normalized == _currencyCode) return;
    setState(() => _currencyCode = normalized);
    _refreshCurrencyConversions();
  }

  Future<void> _openManualExpense() async {
    final expense = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        builder: (_) =>
            ManualExpenseView(initialCurrencyCode: _activeCurrencyCode),
      ),
    );
    if (expense != null && mounted) await _saveExpense(expense);
  }

  Future<ImageSource?> _chooseReceiptSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: AppContentWidth(
          maxWidth: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scan receipt or invoice',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReceiptSourceTile(
                icon: Icons.camera_alt_rounded,
                title: 'Take a photo',
                subtitle: 'Capture a clear, well-lit receipt or invoice',
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _ReceiptSourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'Use an existing photo from your device',
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    if (_isScanning) return;
    final source = await _chooseReceiptSource();
    if (source == null || !mounted) return;

    setState(() => _isScanning = true);
    try {
      final result = await _receiptScanService.scan(source);
      if (result == null || !mounted) return;
      final expense = await Navigator.of(context).push<Expense>(
        MaterialPageRoute(
          builder: (_) => ManualExpenseView(
            initialTitle: result.title,
            initialAmount: result.amount,
            initialCategory: result.category,
            initialDate: result.date,
            initialNote: result.note,
            initialCurrencyCode: result.currencyCode,
          ),
        ),
      );
      if (expense != null && mounted) {
        await _saveScannedExpense(
          expense,
          imageBytes: result.imageBytes,
          imageMimeType: result.imageMimeType,
        );
      }
    } on CloudinaryUploadException catch (error) {
      if (mounted) _showMessage(error.message);
    } on ReceiptScanException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Receipt scanning failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveScannedExpense(
    Expense expense, {
    required Uint8List? imageBytes,
    required String? imageMimeType,
  }) async {
    if (imageBytes == null || imageMimeType == null) {
      await _saveExpense(expense);
      return;
    }
    final receiptImageUrl = await _cloudinaryService.uploadReceipt(
      bytes: imageBytes,
      mimeType: imageMimeType,
    );
    await _saveExpense(expense.copyWith(receiptImageUrl: receiptImageUrl));
  }

  void _handleExpensesChanged(List<Expense> expenses) {
    if (!mounted) return;
    setState(() => _controller.replaceExpenses(expenses));
    _refreshCurrencyConversions();
  }

  void _handleExpensesError(Object error, StackTrace stackTrace) {
    if (mounted) {
      _showMessage('Could not load expenses from Firestore. Please try again.');
    }
  }

  Future<void> _saveExpense(Expense expense) async {
    try {
      await _expenseService.addExpense(widget.userId, expense);
      if (mounted) _showMessage('Expense saved.');
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save the expense. Please try again.');
      }
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await _expenseService.deleteExpense(widget.userId, id);
      if (mounted) _showMessage('Expense deleted.');
    } catch (_) {
      if (mounted) {
        _showMessage('Could not delete the expense. Please try again.');
      }
    }
  }

  Future<void> _refreshCurrencyConversions() async {
    final generation = ++_conversionGeneration;
    if (_controller.expenses.isEmpty) {
      if (mounted) {
        setState(() {
          _convertedAmounts = const {};
          _isConvertingCurrencies = false;
          _currencyConversionError = null;
        });
      }
      return;
    }

    setState(() {
      _convertedAmounts = const {};
      _isConvertingCurrencies = true;
      _currencyConversionError = null;
    });
    try {
      final converted = await _conversionService.convertExpenses(
        _controller.expenses,
        _activeCurrencyCode,
      );
      if (!mounted || generation != _conversionGeneration) return;
      setState(() {
        _convertedAmounts = Map.unmodifiable(converted);
        _isConvertingCurrencies = false;
      });
    } on CurrencyConversionException catch (error) {
      if (!mounted || generation != _conversionGeneration) return;
      setState(() {
        _isConvertingCurrencies = false;
        _currencyConversionError = error.message;
      });
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFab() {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        tooltip: 'Scan receipt or invoice',
        onPressed: _isScanning ? null : _scanReceipt,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledElevation: 0,
        elevation: 0,
        child: _isScanning
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.document_scanner_rounded, size: 27),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: 72,
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavigationItem(
              icon: Icons.space_dashboard_outlined,
              selectedIcon: Icons.space_dashboard_rounded,
              label: 'Dashboard',
              selected: _selectedIndex == 0,
              onTap: () => _selectPage(0),
            ),
            _NavigationItem(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
              label: 'Expenses',
              selected: _selectedIndex == 1,
              onTap: () => _selectPage(1),
            ),
            const SizedBox(width: 62),
            _NavigationItem(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart_rounded,
              label: 'Insights',
              selected: _selectedIndex == 2,
              onTap: () => _selectPage(2),
            ),
            _NavigationItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: 'Settings',
              selected: _selectedIndex == 3,
              onTap: () => _selectPage(3),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPage(int index) {
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }
}

class _ReceiptSourceTile extends StatelessWidget {
  const _ReceiptSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconTile(icon: icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                width: 36,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 22,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
