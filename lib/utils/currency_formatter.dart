class CurrencyFormatter {
  const CurrencyFormatter._();

  static const supportedCodes = <String>[
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CNY',
    'KRW',
    'INR',
    'AUD',
    'CAD',
    'SGD',
    'HKD',
    'MYR',
    'THB',
    'IDR',
    'VND',
    'NZD',
    'AED',
    'SAR',
    'CHF',
  ];

  static const _symbols = <String, String>{
    'PHP': '₱',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': 'CN¥',
    'KRW': '₩',
    'INR': '₹',
    'AUD': r'A$',
    'CAD': r'C$',
    'SGD': r'S$',
    'HKD': r'HK$',
    'MYR': 'RM',
    'THB': '฿',
    'IDR': 'Rp',
    'VND': '₫',
    'NZD': r'NZ$',
    'AED': 'AED ',
    'SAR': 'SAR ',
    'CHF': 'CHF ',
  };

  static const _zeroDecimalCodes = {'JPY', 'KRW', 'IDR', 'VND'};

  static String normalize(String? code, {String fallback = 'PHP'}) {
    final normalized = code?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{3}$').hasMatch(normalized) ? normalized : fallback;
  }

  static String symbol(String code) {
    final normalized = normalize(code);
    return _symbols[normalized] ?? '$normalized ';
  }

  static String format(double amount, String code) {
    final normalized = normalize(code);
    final decimalPlaces = _zeroDecimalCodes.contains(normalized) ? 0 : 2;
    final fixed = amount.toStringAsFixed(decimalPlaces);
    final parts = fixed.split('.');
    final whole = parts.first;
    final isNegative = whole.startsWith('-');
    final digits = isNegative ? whole.substring(1) : whole;
    final firstGroupLength = digits.length % 3 == 0 ? 3 : digits.length % 3;
    final buffer = StringBuffer(isNegative ? '-' : '')
      ..write(digits.substring(0, firstGroupLength));
    for (var index = firstGroupLength; index < digits.length; index += 3) {
      buffer
        ..write(',')
        ..write(digits.substring(index, index + 3));
    }
    if (parts.length > 1) buffer.write('.${parts.last}');
    return '${symbol(normalized)}$buffer';
  }
}
