import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseService {
  ExpenseService([this._firestore]);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _database => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _expenseCollection(String userId) =>
      _database.collection('users').doc(userId).collection('expenses');

  // ------------------------------------------------------------
  // ADD EXPENSE
  // ------------------------------------------------------------

  Future<void> addExpense(String userId, Expense expense) async {
    await _expenseCollection(userId).doc(expense.id).set(expense.toMap());
  }

  // ------------------------------------------------------------
  // GET ALL EXPENSES
  // ------------------------------------------------------------

  Stream<List<Expense>> watchExpenses(String userId) {
    return _expenseCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Expense.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // ------------------------------------------------------------
  // DELETE EXPENSE
  // ------------------------------------------------------------

  Future<void> deleteExpense(String userId, String id) async {
    await _expenseCollection(userId).doc(id).delete();
  }
}
