import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { earned, spent, bonus, reward }

class TransactionModel {
  final String id;
  final String userId;
  final int amount;
  final TransactionType type;
  final String source;
  final String description;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.source,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'source': source,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: map['amount'] as int,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      source: map['source'] as String,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
