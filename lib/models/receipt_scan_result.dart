import 'dart:typed_data';

class ReceiptScanResult {
  const ReceiptScanResult({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.currencyCode = 'PHP',
    this.imageBytes,
    this.imageMimeType,
  });

  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String currencyCode;
  final Uint8List? imageBytes;
  final String? imageMimeType;

  ReceiptScanResult copyWith({Uint8List? imageBytes, String? imageMimeType}) {
    return ReceiptScanResult(
      title: title,
      amount: amount,
      category: category,
      date: date,
      note: note,
      currencyCode: currencyCode,
      imageBytes: imageBytes ?? this.imageBytes,
      imageMimeType: imageMimeType ?? this.imageMimeType,
    );
  }

  factory ReceiptScanResult.fromMap(Map<Object?, Object?> map) {
    const categories = {
      'Food',
      'Transportation',
      'Shopping',
      'Bills',
      'Education',
      'Entertainment',
      'Health',
      'Other',
    };
    final currencyCode = _normalizeCurrencyCode(
      map['currencyCode']?.toString(),
    );
    final amount =
        _parseAmount(map['totalAmountText'], currencyCode) ??
        _parseAmount(map['totalAmount'] ?? map['amount'], currencyCode);
    final parsedDate = DateTime.tryParse(
      (map['purchaseDate'] ?? map['date'])?.toString() ?? '',
    );
    final now = DateTime.now();
    final earliestDate = DateTime(2020);
    final date =
        parsedDate == null ||
            parsedDate.isAfter(now) ||
            parsedDate.isBefore(earliestDate)
        ? now
        : parsedDate;

    if (amount == null || amount <= 0) {
      throw const FormatException('The receipt response is incomplete.');
    }

    final rawCategory = map['category']?.toString() ?? 'Other';

    return ReceiptScanResult(
      title: map['title']?.toString().trim().isNotEmpty == true
          ? map['title'].toString().trim()
          : 'Receipt',
      amount: amount,
      category: _normalizeCategory(rawCategory, categories),
      date: date,
      note: map['note']?.toString().trim().isNotEmpty == true
          ? map['note'].toString().trim()
          : 'Scanned with NVIDIA AI',
      currencyCode: currencyCode,
    );
  }

  static double? _parseAmount(Object? rawAmount, String currencyCode) {
    if (rawAmount == null) return null;

    var value = rawAmount.toString().trim().replaceAll(
      RegExp(r'[^0-9,.-]'),
      '',
    );
    if (value.isEmpty) return null;

    final isNegative = value.startsWith('-');
    value = value.replaceAll('-', '');
    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');
    final decimalPlaces = _decimalPlacesFor(currencyCode);

    if (lastComma >= 0 && lastDot >= 0) {
      final decimalSeparator = lastComma > lastDot ? ',' : '.';
      final thousandsSeparator = decimalSeparator == ',' ? '.' : ',';
      value = value.replaceAll(thousandsSeparator, '');
      if (decimalSeparator == ',') value = value.replaceAll(',', '.');
    } else {
      final separator = lastComma >= 0 ? ',' : (lastDot >= 0 ? '.' : null);
      if (separator != null) {
        final separatorCount = separator.allMatches(value).length;
        final lastSeparator = value.lastIndexOf(separator);
        final digitsAfter = value.length - lastSeparator - 1;
        final hasDecimalPart =
            decimalPlaces > 0 &&
            digitsAfter > 0 &&
            digitsAfter <= decimalPlaces;

        if (separatorCount == 1 && hasDecimalPart) {
          if (separator == ',') value = value.replaceAll(',', '.');
        } else if (separatorCount > 1 && hasDecimalPart) {
          final whole = value
              .substring(0, lastSeparator)
              .replaceAll(separator, '');
          value = '$whole.${value.substring(lastSeparator + 1)}';
        } else {
          value = value.replaceAll(separator, '');
        }
      }
    }

    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return isNegative ? -parsed : parsed;
  }

  static int _decimalPlacesFor(String currencyCode) {
    if (const {'JPY', 'KRW', 'IDR', 'VND'}.contains(currencyCode)) return 0;
    if (const {
      'BHD',
      'IQD',
      'JOD',
      'KWD',
      'OMR',
      'TND',
    }.contains(currencyCode)) {
      return 3;
    }
    return 2;
  }

  static String _normalizeCurrencyCode(String? rawCode) {
    final code = rawCode?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{3}$').hasMatch(code) ? code : 'PHP';
  }

  static String _normalizeCategory(String rawCategory, Set<String> categories) {
    final normalized = rawCategory.trim().toLowerCase();
    for (final category in categories) {
      if (category.toLowerCase() == normalized) return category;
    }

    if (RegExp(r'food|grocer|restaurant|dining|meal').hasMatch(normalized)) {
      return 'Food';
    }
    if (RegExp(r'transport|fuel|gas|taxi|fare|parking').hasMatch(normalized)) {
      return 'Transportation';
    }
    if (RegExp(r'shop|retail|clothing|general merchandise')
        .hasMatch(normalized)) {
      return 'Shopping';
    }
    if (RegExp(r'bill|utilit|electric|water|internet|phone')
        .hasMatch(normalized)) {
      return 'Bills';
    }
    if (RegExp(r'education|school|tuition|book').hasMatch(normalized)) {
      return 'Education';
    }
    if (RegExp(r'entertain|movie|cinema|game').hasMatch(normalized)) {
      return 'Entertainment';
    }
    if (RegExp(r'health|medical|pharmacy|medicine|clinic')
        .hasMatch(normalized)) {
      return 'Health';
    }
    return 'Other';
  }
}
