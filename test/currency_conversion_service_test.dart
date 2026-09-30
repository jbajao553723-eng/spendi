import 'dart:convert';

import 'package:final_project/models/expense.dart';
import 'package:final_project/services/currency_conversion_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('converts foreign expenses before calculating a PHP total', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(
        request.url.toString(),
        'https://api.frankfurter.dev/v2/rate/usd/php',
      );
      return http.Response(
        jsonEncode({
          'date': '2026-09-18',
          'base': 'USD',
          'quote': 'PHP',
          'rate': 62.735,
        }),
        200,
      );
    });
    final service = CurrencyConversionService(client);
    final expenses = [
      Expense(
        id: 'php-expense',
        title: 'Watsons',
        amount: 10124.50,
        category: 'Shopping',
        date: DateTime(2026, 4, 18),
        currencyCode: 'PHP',
      ),
      Expense(
        id: 'usd-expense',
        title: 'Other expense',
        amount: 176.74,
        category: 'Other',
        date: DateTime(2026, 4, 18),
        currencyCode: 'USD',
      ),
      Expense(
        id: 'another-usd-expense',
        title: 'Coffee',
        amount: 10,
        category: 'Food',
        date: DateTime(2026, 4, 18),
        currencyCode: 'USD',
      ),
    ];

    final converted = await service.convertExpenses(expenses, 'PHP');
    final total = converted.values.fold<double>(0, (sum, value) => sum + value);

    expect(converted['php-expense'], 10124.50);
    expect(converted['usd-expense'], closeTo(11087.7839, 0.0001));
    expect(converted['another-usd-expense'], closeTo(627.35, 0.0001));
    expect(total, closeTo(21839.6339, 0.0001));
    expect(requests, 1);
  });

  test('reuses a recently fetched rate', () async {
    var requests = 0;
    final service = CurrencyConversionService(
      MockClient((request) async {
        requests++;
        return http.Response(jsonEncode({'rate': 50}), 200);
      }),
    );

    expect(await service.convert(2, from: 'USD', to: 'PHP'), 100);
    expect(await service.convert(3, from: 'USD', to: 'PHP'), 150);
    expect(requests, 1);
  });
}
