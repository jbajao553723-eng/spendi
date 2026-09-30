enum ExpensePeriod {
  today('Today'),
  thisWeek('This week'),
  thisMonth('This month'),
  allTime('All time');

  const ExpensePeriod(this.label);

  final String label;

  bool includes(DateTime date, {DateTime? now}) {
    if (this == ExpensePeriod.allTime) return true;

    final current = (now ?? DateTime.now()).toLocal();
    final expenseDate = date.toLocal();
    late final DateTime start;
    late final DateTime end;

    switch (this) {
      case ExpensePeriod.today:
        start = DateTime(current.year, current.month, current.day);
        end = DateTime(current.year, current.month, current.day + 1);
        break;
      case ExpensePeriod.thisWeek:
        start = DateTime(
          current.year,
          current.month,
          current.day - (current.weekday - DateTime.monday),
        );
        end = DateTime(start.year, start.month, start.day + 7);
        break;
      case ExpensePeriod.thisMonth:
        start = DateTime(current.year, current.month);
        end = DateTime(current.year, current.month + 1);
        break;
      case ExpensePeriod.allTime:
        return true;
    }

    return !expenseDate.isBefore(start) && expenseDate.isBefore(end);
  }
}
