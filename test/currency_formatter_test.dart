import 'package:final_project/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats common currencies with their symbols', () {
    expect(CurrencyFormatter.format(12.5, 'PHP'), '₱12.50');
    expect(CurrencyFormatter.format(12.5, 'USD'), r'$12.50');
    expect(CurrencyFormatter.format(12.5, 'EUR'), '€12.50');
    expect(CurrencyFormatter.format(1200, 'JPY'), '¥1,200');
  });

  test('adds thousands separators to large totals', () {
    expect(CurrencyFormatter.format(10301.24, 'PHP'), '₱10,301.24');
  });
}
