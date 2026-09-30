import '../models/expense.dart';

class DashboardController {
  List<Expense> _expenses = const [];
  List<Expense> _recentExpenses = const [];

  List<Expense> get expenses => _expenses;

  List<Expense> get recentExpenses => _recentExpenses;

  void replaceExpenses(Iterable<Expense> updatedExpenses) {
    final sortedExpenses = List<Expense>.of(updatedExpenses);
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    _expenses = List.unmodifiable(sortedExpenses);
    _recentExpenses = List.unmodifiable(sortedExpenses.take(5));
  }
}
