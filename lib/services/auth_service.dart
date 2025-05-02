import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Initialize user data in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'balance': 0,
        'totalEarned': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastDailyBonus': null,
        'streakCount': 0,
        'lastSpinTime': null,
      });

      return credential;
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
