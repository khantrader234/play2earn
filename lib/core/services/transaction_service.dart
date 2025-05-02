import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordTransaction({
    required String userId,
    required int amount,
    required TransactionType type,
    required String source,
    required String description,
  }) async {
    final transaction = TransactionModel(
      id: _firestore.collection('transactions').doc().id,
      userId: userId,
      amount: amount,
      type: type,
      source: source,
      description: description,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  Future<List<TransactionModel>> getRecentTransactions(String userId,
      {int limit = 10}) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  Stream<int> getTotalEarned(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: TransactionType.earned.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.fold<int>(
            0, (total, doc) => total + (doc.data()['amount'] as int? ?? 0)));
  }

  Stream<int> getTotalSpent(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: TransactionType.spent.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.fold<int>(
            0, (total, doc) => total + (doc.data()['amount'] as int? ?? 0)));
  }
}
