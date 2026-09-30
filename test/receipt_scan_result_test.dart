import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/models/receipt_scan_result.dart';

void main() {
  test('parses NVIDIA receipt fields and normalizes category synonyms', () {
    final result = ReceiptScanResult.fromMap({
      'title': 'SPENDI TEST MART',
      'totalAmount': 'PHP 223.44',
      'currencyCode': 'php',
      'category': 'Groceries',
      'purchaseDate': '2026-09-14',
      'note': 'Groceries and tax',
    });

    expect(result.title, 'SPENDI TEST MART');
    expect(result.amount, 223.44);
    expect(result.category, 'Food');
    expect(result.date, DateTime(2026, 9, 14));
    expect(result.note, 'Groceries and tax');
    expect(result.currencyCode, 'PHP');
  });

  test('uses safe defaults for optional model fields', () {
    final result = ReceiptScanResult.fromMap({
      'totalAmount': 25,
      'category': 'unknown category',
      'purchaseDate': '2026-09-14',
      'note': '',
    });

    expect(result.title, 'Receipt');
    expect(result.category, 'Other');
    expect(result.note, 'Scanned with NVIDIA AI');
    expect(result.currencyCode, 'PHP');
  });

  test('preserves a valid three-letter currency code', () {
    final result = ReceiptScanResult.fromMap({
      'title': 'Tokyo Shop',
      'totalAmount': 1200,
      'currencyCode': 'JPY',
      'category': 'Shopping',
      'purchaseDate': '2026-09-14',
    });

    expect(result.currencyCode, 'JPY');
  });

  test('preserves a Philippine thousands separator in the scanned total', () {
    final result = ReceiptScanResult.fromMap({
      'title': 'Watsons',
      'totalAmount': 10.124,
      'totalAmountText': '10,124.00',
      'currencyCode': 'PHP',
      'category': 'Shopping',
      'purchaseDate': '2026-04-18',
    });

    expect(result.amount, 10124.00);
  });

  test('repairs a three-digit separator returned as a PHP decimal', () {
    final result = ReceiptScanResult.fromMap({
      'title': 'Watsons',
      'totalAmount': 10.124,
      'currencyCode': 'PHP',
      'category': 'Shopping',
      'purchaseDate': '2026-04-18',
    });

    expect(result.amount, 10124.00);
  });

  test('supports European thousands and decimal separators', () {
    final result = ReceiptScanResult.fromMap({
      'title': 'European Store',
      'totalAmountText': '€ 10.124,50',
      'currencyCode': 'EUR',
      'category': 'Shopping',
      'purchaseDate': '2026-04-18',
    });

    expect(result.amount, 10124.50);
  });
}
