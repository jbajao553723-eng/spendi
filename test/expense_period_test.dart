import 'package:final_project/models/expense_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today, week, and month use local calendar boundaries', () {
    final now = DateTime(2026, 1, 1, 12);

    expect(
      ExpensePeriod.today.includes(DateTime(2026, 1, 1), now: now),
      isTrue,
    );
    expect(
      ExpensePeriod.today.includes(DateTime(2026, 1, 2), now: now),
      isFalse,
    );

    expect(
      ExpensePeriod.thisWeek.includes(DateTime(2025, 12, 29), now: now),
      isTrue,
    );
    expect(
      ExpensePeriod.thisWeek.includes(DateTime(2026, 1, 4, 23, 59), now: now),
      isTrue,
    );
    expect(
      ExpensePeriod.thisWeek.includes(DateTime(2026, 1, 5), now: now),
      isFalse,
    );

    expect(
      ExpensePeriod.thisMonth.includes(DateTime(2026, 1, 31), now: now),
      isTrue,
    );
    expect(
      ExpensePeriod.thisMonth.includes(DateTime(2025, 12, 31), now: now),
      isFalse,
    );
    expect(ExpensePeriod.allTime.includes(DateTime(2020), now: now), isTrue);
  });
}
