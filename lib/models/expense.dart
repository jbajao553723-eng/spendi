class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String currencyCode;
  final String? receiptImageUrl;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.currencyCode = 'PHP',
    this.receiptImageUrl,
  });

  // Convert Expense to Firebase/Firestore data
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
      'note': note,
      'currencyCode': currencyCode,
      if (receiptImageUrl != null) 'receiptImageUrl': receiptImageUrl,
    };
  }

  // Convert Firestore document into Expense
  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Other',
      date: map['date'] != null
          ? (map['date'] as dynamic).toDate()
          : DateTime.now(),
      note: map['note'],
      currencyCode: _normalizeCurrencyCode(map['currencyCode']?.toString()),
      receiptImageUrl: map['receiptImageUrl']?.toString(),
    );
  }

  Expense copyWith({String? receiptImageUrl}) => Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    note: note,
    currencyCode: currencyCode,
    receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
  );

  static String _normalizeCurrencyCode(String? rawCode) {
    final code = rawCode?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{3}$').hasMatch(code) ? code : 'PHP';
  }
}
