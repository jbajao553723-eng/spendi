import 'package:final_project/controllers/dashboard_controller.dart';
import 'package:final_project/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sorts expenses and exposes immutable recent items', () {
    final source = List.generate(
      7,
      (index) => Expense(
        id: '$index',
        title: 'Expense $index',
        amount: index + 1,
        category: 'Other',
        date: DateTime(2026, 1, index + 1),
      ),
    );
    final controller = DashboardController()..replaceExpenses(source);

    source.clear();

    expect(controller.expenses, hasLength(7));
    expect(controller.expenses.first.id, '6');
    expect(controller.recentExpenses.map((item) => item.id), [
      '6',
      '5',
      '4',
      '3',
      '2',
    ]);
    expect(
      () => controller.expenses.add(controller.expenses.first),
      throwsUnsupportedError,
    );
  });
}
