import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Authentication Methods
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(loginMethod: 'email');
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createUserDocument(userCredential.user!.uid);
      await _analytics.logSignUp(signUpMethod: 'email');
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _analytics.logEvent(name: 'user_sign_out');
  }

  // User Data Methods
  Future<void> _createUserDocument(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'createdAt': FieldValue.serverTimestamp(),
      'balance': 0,
      'totalEarned': 0,
      'gamesPlayed': 0,
      'adsWatched': 0,
      'lastDailyBonus': null,
      'streakCount': 0,
    });
  }

  Future<void> updateUserBalance(String uid, int amount) async {
    await _firestore.collection('users').doc(uid).update({
      'balance': FieldValue.increment(amount),
      'totalEarned': FieldValue.increment(amount),
    });
  }

  Future<void> recordGamePlay(String uid, int score, int coinsEarned) async {
    await _firestore.collection('users').doc(uid).update({
      'gamesPlayed': FieldValue.increment(1),
      'balance': FieldValue.increment(coinsEarned),
      'totalEarned': FieldValue.increment(coinsEarned),
    });

    await _firestore.collection('game_history').add({
      'userId': uid,
      'score': score,
      'coinsEarned': coinsEarned,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordAdWatch(String uid, int coinsEarned) async {
    await _firestore.collection('users').doc(uid).update({
      'adsWatched': FieldValue.increment(1),
      'balance': FieldValue.increment(coinsEarned),
      'totalEarned': FieldValue.increment(coinsEarned),
    });

    await _firestore.collection('ad_history').add({
      'userId': uid,
      'coinsEarned': coinsEarned,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> claimDailyBonus(String uid, int bonusAmount) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data() as Map<String, dynamic>;
    final lastBonus = data['lastDailyBonus'] as Timestamp?;
    final streakCount = data['streakCount'] as int;

    final now = DateTime.now();
    final newStreak = _calculateNewStreak(lastBonus, streakCount, now);

    await _firestore.collection('users').doc(uid).update({
      'lastDailyBonus': FieldValue.serverTimestamp(),
      'streakCount': newStreak,
      'balance': FieldValue.increment(bonusAmount),
      'totalEarned': FieldValue.increment(bonusAmount),
    });

    await _firestore.collection('bonus_history').add({
      'userId': uid,
      'amount': bonusAmount,
      'streak': newStreak,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  int _calculateNewStreak(
      Timestamp? lastBonus, int currentStreak, DateTime now) {
    if (lastBonus == null) return 1;

    final lastDate = lastBonus.toDate();
    final difference = now.difference(lastDate).inDays;

    if (difference == 1) {
      return currentStreak + 1;
    } else if (difference == 0) {
      return currentStreak;
    } else {
      return 1;
    }
  }

  // Analytics Methods
  Future<void> logGameStart(String gameType) async {
    await _analytics.logEvent(
      name: 'game_start',
      parameters: {'game_type': gameType},
    );
  }

  Future<void> logGameEnd(String gameType, int score, int coinsEarned) async {
    await _analytics.logEvent(
      name: 'game_end',
      parameters: {
        'game_type': gameType,
        'score': score,
        'coins_earned': coinsEarned,
      },
    );
  }

  Future<void> logAdWatch(String adType, int coinsEarned) async {
    await _analytics.logEvent(
      name: 'ad_watch',
      parameters: {
        'ad_type': adType,
        'coins_earned': coinsEarned,
      },
    );
  }

  // Get high scores for a specific game type
  Future<QuerySnapshot<Map<String, dynamic>>> getHighScores(
      String gameType) async {
    return await _firestore
        .collection('game_history')
        .where('gameType', isEqualTo: gameType)
        .orderBy('score', descending: true)
        .limit(10)
        .get();
  }

  // Get user statistics
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserStats(
      String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  // Record a transaction
  Future<void> recordTransaction(
    String userId,
    int amount,
    String type,
    String description,
  ) async {
    await _firestore.collection('transactions').add({
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (type == 'credit') {
      await _firestore.collection('users').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'totalEarned': FieldValue.increment(amount),
      });
    } else if (type == 'debit') {
      await _firestore.collection('users').doc(userId).update({
        'balance': FieldValue.increment(-amount),
      });
    }
  }

  // Request withdrawal
  Future<void> requestWithdrawal(
    String userId,
    int amount,
    String withdrawalMethod,
  ) async {
    await _firestore.collection('withdrawal_requests').add({
      'userId': userId,
      'amount': amount,
      'method': withdrawalMethod,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(userId).update({
      'balance': FieldValue.increment(-amount),
    });
  }

  // Get transaction history
  Future<QuerySnapshot<Map<String, dynamic>>> getTransactionHistory(
      String userId) async {
    return await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
  }

  // Spin game methods
  Future<void> recordSpinResult(
    String userId,
    int amount,
    bool isJackpot,
  ) async {
    final spinRef =
        _firestore.collection('users').doc(userId).collection('spins');
    await spinRef.add({
      'amount': amount,
      'isJackpot': isJackpot,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getSpinHistory(
      String userId) async {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('spins')
        .orderBy('timestamp', descending: true)
        .get();
  }

  // Update user data
  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(userId).update(data);
  }
}
