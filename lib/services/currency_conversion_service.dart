import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';
import '../utils/currency_formatter.dart';

class CurrencyConversionException implements Exception {
  const CurrencyConversionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CurrencyConversionService {
  CurrencyConversionService([this._client]);

  static const _endpoint = 'https://api.frankfurter.dev/v2/rate';
  static const _cacheDuration = Duration(hours: 6);

  final http.Client? _client;
  final Map<String, ({double rate, DateTime fetchedAt})> _rateCache = {};

  Future<double> convert(
    double amount, {
    required String from,
    required String to,
  }) async {
    final source = CurrencyFormatter.normalize(from);
    final target = CurrencyFormatter.normalize(to);
    if (source == target) return amount;
    return amount * await _getRate(source, target);
  }

  Future<Map<String, double>> convertExpenses(
    Iterable<Expense> expenses,
    String targetCurrency,
  ) async {
    final expenseList = expenses.toList(growable: false);
    final target = CurrencyFormatter.normalize(targetCurrency);
    final sourceCurrencies = expenseList
        .map((expense) => CurrencyFormatter.normalize(expense.currencyCode))
        .toSet();
    final rates = <String, double>{};

    await Future.wait(
      sourceCurrencies.map((source) async {
        rates[source] = source == target
            ? 1
            : await convert(1, from: source, to: target);
      }),
    );

    final converted = <String, double>{};
    for (final expense in expenseList) {
      final source = CurrencyFormatter.normalize(expense.currencyCode);
      converted[expense.id] = expense.amount * rates[source]!;
    }
    return converted;
  }

  Future<double> _getRate(String from, String to) async {
    final cacheKey = '$from/$to';
    final cached = _rateCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheDuration) {
      return cached.rate;
    }

    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_endpoint/${from.toLowerCase()}/${to.toLowerCase()}'),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const CurrencyConversionException(
          'The exchange rate is unavailable right now.',
        );
      }
      final body = jsonDecode(response.body);
      final rate = body is Map ? body['rate'] : null;
      if (rate is! num || rate <= 0) {
        throw const CurrencyConversionException(
          'The exchange-rate service returned an invalid rate.',
        );
      }
      final value = rate.toDouble();
      _rateCache[cacheKey] = (rate: value, fetchedAt: DateTime.now());
      return value;
    } on CurrencyConversionException {
      rethrow;
    } on TimeoutException {
      throw const CurrencyConversionException(
        'Exchange-rate loading timed out. Check your connection.',
      );
    } on http.ClientException {
      throw const CurrencyConversionException(
        'Could not load exchange rates. Check your connection.',
      );
    } on FormatException {
      throw const CurrencyConversionException(
        'The exchange-rate service returned an invalid response.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
