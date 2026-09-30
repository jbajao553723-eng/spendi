import 'dart:async';

import 'package:final_project/models/expense.dart';
import 'package:final_project/views/dashboard_view.dart';
import 'package:final_project/models/receipt_scan_result.dart';
import 'package:final_project/services/currency_conversion_service.dart';
import 'package:final_project/services/expense_service.dart';
import 'package:final_project/services/receipt_scan_service.dart';
import 'package:final_project/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeReceiptScanService extends ReceiptScanService {
  ImageSource? selectedSource;

  @override
  Future<ReceiptScanResult?> scan(ImageSource source) async {
    selectedSource = source;
    return ReceiptScanResult(
      title: 'Corner Cafe',
      amount: 245.75,
      category: 'Food',
      date: DateTime(2026, 9, 14),
      note: 'Lunch receipt',
      currencyCode: 'USD',
    );
  }
}

class _FakeCurrencyConversionService extends CurrencyConversionService {
  @override
  Future<double> convert(
    double amount, {
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;
    if (from == 'PHP' && to == 'USD') return amount * 0.02;
    if (from == 'USD' && to == 'PHP') return amount * 50;
    throw const CurrencyConversionException('Unsupported test currency pair.');
  }
}

class _FakeExpenseService extends ExpenseService {
  _FakeExpenseService([Iterable<Expense> initialExpenses = const []])
    : _expenses = List<Expense>.from(initialExpenses);

  final List<Expense> _expenses;
  final StreamController<List<Expense>> _changes =
      StreamController<List<Expense>>.broadcast();

  @override
  Stream<List<Expense>> watchExpenses(String userId) async* {
    yield List<Expense>.unmodifiable(_expenses);
    yield* _changes.stream;
  }

  @override
  Future<void> addExpense(String userId, Expense expense) async {
    _expenses.add(expense);
    _emit();
  }

  @override
  Future<void> deleteExpense(String userId, String id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    _emit();
  }

  void _emit() => _changes.add(List<Expense>.unmodifiable(_expenses));
}

void main() {
  testWidgets('expense filters update the list and total and keep selection', (
    tester,
  ) async {
    final now = DateTime.now();
    final expenseService = _FakeExpenseService([
      Expense(
        id: 'today',
        title: 'Today purchase',
        amount: 10,
        category: 'Food',
        date: now,
      ),
      Expense(
        id: 'old-month',
        title: 'Previous month purchase',
        amount: 20,
        category: 'Food',
        date: DateTime(now.year, now.month - 1, 1),
      ),
      Expense(
        id: 'old-year',
        title: 'Previous year purchase',
        amount: 30,
        category: 'Food',
        date: DateTime(now.year - 1, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardView(
          userId: 'test-user',
          userEmail: 'person@example.com',
          onSignOut: () async {},
          isDarkMode: false,
          currencyConversionService: _FakeCurrencyConversionService(),
          expenseService: expenseService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    expect(find.text('3 entries'), findsOneWidget);
    expect(find.text('All time total'), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(60, 'PHP')), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('1 entry'), findsOneWidget);
    expect(find.text('Today purchase'), findsOneWidget);
    expect(find.text('Previous month purchase'), findsNothing);
    expect(find.text(CurrencyFormatter.format(10, 'PHP')), findsOneWidget);

    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(find.text('This week total'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(find.text('This month total'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('This month total'), findsOneWidget);

    await tester.ensureVisible(find.text('All time'));
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.text('3 entries'), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(60, 'PHP')), findsOneWidget);
  });

  testWidgets('new dashboard starts empty and adds an expense from the FAB', (
    tester,
  ) async {
    bool darkModeEnabled = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: DashboardView(
            userId: 'test-user',
            userEmail: 'person@example.com',
            onSignOut: () async {},
            isDarkMode: darkModeEnabled,
            onDarkModeChanged: (enabled) {
              setState(() => darkModeEnabled = enabled);
            },
            currencyConversionService: _FakeCurrencyConversionService(),
            expenseService: _FakeExpenseService(),
          ),
        ),
      ),
    );

    expect(find.text('Spendi'), findsOneWidget);
    expect(find.text('₱0.00'), findsNWidgets(3));
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_rounded), findsOneWidget);
    expect(
      tester
          .widget<Scaffold>(find.byType(Scaffold).first)
          .floatingActionButtonLocation,
      FloatingActionButtonLocation.centerDocked,
    );
    await tester.tap(find.byIcon(Icons.document_scanner_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsNothing);

    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lunch');
    await tester.enterText(fields.at(1), '125.50');
    await tester.ensureVisible(find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(find.text('₱125.50'), findsNWidgets(3));
    expect(find.text('Lunch'), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('1 entry'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Totals converted using current rates'), findsOneWidget);
    await tester.tap(find.text('PHP').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(darkModeEnabled, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text(r'$2.51'), findsNWidgets(3));
  });

  testWidgets('center receipt scanner reviews and saves AI result', (
    tester,
  ) async {
    final scanService = _FakeReceiptScanService();
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardView(
          userId: 'test-user',
          userEmail: 'person@example.com',
          onSignOut: () async {},
          isDarkMode: false,
          receiptScanService: scanService,
          initialCurrencyCode: 'USD',
          currencyConversionService: _FakeCurrencyConversionService(),
          expenseService: _FakeExpenseService(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.document_scanner_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(scanService.selectedSource, ImageSource.gallery);
    expect(find.text('Review Scan'), findsOneWidget);
    expect(find.text('Corner Cafe'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);

    await tester.ensureVisible(find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Corner Cafe'), findsOneWidget);
    expect(find.text(r'-$245.75'), findsOneWidget);
  });

  testWidgets('dashboard and bottom navigation follow dark mode', (
    tester,
  ) async {
    const darkBackground = Color(0xFF11131A);
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: darkTheme,
        home: DashboardView(
          userId: 'test-user',
          userEmail: 'person@example.com',
          onSignOut: () async {},
          isDarkMode: true,
          expenseService: _FakeExpenseService(),
        ),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      darkBackground,
    );
    expect(
      tester.widget<BottomAppBar>(find.byType(BottomAppBar)).color,
      darkTheme.colorScheme.surface,
    );
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).foregroundColor,
      darkTheme.colorScheme.onSurface,
    );
  });
}
