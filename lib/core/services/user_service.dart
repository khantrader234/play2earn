import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  UserService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData(String uid) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      } else {
        final user = _auth.currentUser;
        if (user == null) {
          _currentUser = null;
          notifyListeners();
          return;
        }

        final newUser = UserModel(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          referralCode: user.uid.substring(0, 8).toUpperCase(),
          coins: 0,
          gamesPlayed: 0,
          powerUps: [],
          lastLoginDate: DateTime.now(),
          lastWatchTime: null,
          loginStreak: 0,
          highScore: 0,
          totalEarned: 0,
          totalSpent: 0,
          achievements: {},
          missions: {},
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toFirestore());
        _currentUser = newUser;
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> saveFcmToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(uid).update({'fcmToken': token});
    }
  }

  Future<Map<String, int>?> handleDailyLoginReward(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);
    final doc = await userDoc.get();
    final user = UserModel.fromFirestore(doc);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    if (user.lastLoginDate == null ||
        DateFormat('yyyy-MM-dd').format(user.lastLoginDate!) != today) {
      int newStreak = user.loginStreak;
      if (user.lastLoginDate != null) {
        final last = user.lastLoginDate!;
        if (now.difference(last).inDays == 1) {
          newStreak += 1;
        } else {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final reward = 20 + (newStreak - 1) * 5;
      await userDoc.update({
        'lastLoginDate': Timestamp.fromDate(now),
        'loginStreak': newStreak,
        'coins': user.coins + reward,
      });

      return {'streak': newStreak, 'reward': reward};
    }
    return null;
  }

  Future<void> createUserIfNotExists(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      final referralCode = user.uid.substring(0, 8).toUpperCase();
      final newUser = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        referralCode: referralCode,
        coins: 0,
        gamesPlayed: 0,
        powerUps: [],
        lastLoginDate: DateTime.now(),
        lastWatchTime: null,
        loginStreak: 0,
        highScore: 0,
        totalEarned: 0,
        totalSpent: 0,
        achievements: {},
        missions: {},
      );
      await userDoc.set(newUser.toFirestore());
    }
  }

  Future<void> addCoins(int amount) async {
    if (_currentUser == null) return;

    try {
      final newCoins = _currentUser!.coins + amount;
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'coins': newCoins,
      });
      _currentUser = _currentUser!.copyWith(coins: newCoins);
      notifyListeners();
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  Future<void> spendCoins(int amount) async {
    if (_currentUser == null) return;

    try {
      final newCoins = _currentUser!.coins - amount;
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'coins': newCoins,
      });
      _currentUser = _currentUser!.copyWith(coins: newCoins);
      notifyListeners();
    } catch (e) {
      print('Error spending coins: $e');
    }
  }

  Future<void> checkAchievements() async {
    final user = _currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final achievementsQuery = await _firestore.collection('achievements').get();

    for (final doc in achievementsQuery.docs) {
      final achievement = AchievementModel.fromFirestore(doc);
      if (!user.achievements.containsKey(achievement.id) &&
          achievement.isUnlocked(user)) {
        await userDoc.update({
          'achievements.${achievement.id}': true,
          'coins': user.coins + achievement.rewardCoins,
        });

        _currentUser = user.copyWith(
          achievements: {
            ...user.achievements,
            achievement.id: true,
          },
          coins: user.coins + achievement.rewardCoins,
        );
        notifyListeners();
      }
    }
  }

  Future<void> updateHighScore(String userId, int score) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final user = UserModel.fromFirestore(doc);

    if (score > user.highScore) {
      await _firestore.collection('users').doc(userId).update({
        'highScore': score,
      });
      await checkAchievements();
      notifyListeners();
    }
  }

  Future<List<UserModel>> getLeaderboard() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('highScore', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<void> updateMissionProgress(
    String userId,
    String missionType,
    int progress,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.update({'missions.$missionType': progress});
    notifyListeners();
  }

  Future<void> incrementGamesPlayed() async {
    if (_currentUser == null) return;

    try {
      final newGamesPlayed = _currentUser!.gamesPlayed + 1;
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'gamesPlayed': newGamesPlayed,
      });
      _currentUser = _currentUser!.copyWith(gamesPlayed: newGamesPlayed);
      notifyListeners();
    } catch (e) {
      print('Error incrementing games played: $e');
    }
  }

  Future<void> usePowerUp(String powerUpId) async {
    if (_currentUser == null) return;

    try {
      final updatedPowerUps = List<String>.from(_currentUser!.powerUps)
        ..remove(powerUpId);
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'powerUps': updatedPowerUps,
      });
      _currentUser = _currentUser!.copyWith(powerUps: updatedPowerUps);
      notifyListeners();
    } catch (e) {
      print('Error using power up: $e');
    }
  }

  Future<void> purchasePowerUp(
      String userId, String powerUpType, int cost) async {
    if (_currentUser == null) return;

    try {
      if (_currentUser!.coins < cost) {
        throw Exception('Not enough coins');
      }

      final updatedPowerUps = List<String>.from(_currentUser!.powerUps)
        ..add(powerUpType);
      final newCoins = _currentUser!.coins - cost;

      await _firestore.collection('users').doc(userId).update({
        'powerUps': updatedPowerUps,
        'coins': newCoins,
      });

      _currentUser = _currentUser!.copyWith(
        powerUps: updatedPowerUps,
        coins: newCoins,
      );
      notifyListeners();
    } catch (e) {
      print('Error purchasing power up: $e');
      rethrow;
    }
  }
}
