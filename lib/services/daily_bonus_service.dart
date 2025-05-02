import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class DailyBonusService {
  static final DailyBonusService _instance = DailyBonusService._internal();
  factory DailyBonusService() => _instance;
  DailyBonusService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Bonus configuration
  static const int baseBonus = 50;
  static const int streakMultiplier = 10;
  static const int maxStreakBonus = 200;

  // Calculate bonus amount based on streak
  int calculateBonusAmount(int streak) {
    final streakBonus = streak * streakMultiplier;
    final totalBonus = baseBonus +
        (streakBonus > maxStreakBonus ? maxStreakBonus : streakBonus);
    return totalBonus;
  }

  // Claim daily bonus
  Future<int> claimDailyBonus(String userId) async {
    try {
      final userDoc = await _firebaseService.getUserStats(userId);
      if (!userDoc.exists) {
        throw Exception('User document does not exist');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastBonus = userData['lastDailyBonus'] as Timestamp?;
      final currentStreak = userData['streakCount'] as int? ?? 0;

      final now = DateTime.now();
      final newStreak = _calculateNewStreak(lastBonus, currentStreak, now);
      final bonusAmount = calculateBonusAmount(newStreak);

      await _firebaseService.updateUserData(userId, {
        'lastDailyBonus': FieldValue.serverTimestamp(),
        'streakCount': newStreak,
        'balance': FieldValue.increment(bonusAmount),
        'totalEarned': FieldValue.increment(bonusAmount),
      });

      await _analytics.logEvent(
        name: 'daily_bonus_claimed',
        parameters: {
          'user_id': userId,
          'amount': bonusAmount,
          'streak': newStreak,
        },
      );

      return bonusAmount;
    } catch (e) {
      throw Exception('Failed to claim daily bonus: $e');
    }
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
}

// Daily bonus state provider
final dailyBonusStateProvider =
    StateNotifierProvider<DailyBonusStateNotifier, DailyBonusState>((ref) {
  return DailyBonusStateNotifier();
});

class DailyBonusState {
  final bool hasClaimedToday;
  final int streakCount;
  final DateTime lastClaimDate;
  final int lastBonusAmount;
  final bool isLoading;

  DailyBonusState({
    required this.hasClaimedToday,
    required this.streakCount,
    required this.lastClaimDate,
    required this.lastBonusAmount,
    required this.isLoading,
  });

  DailyBonusState copyWith({
    bool? hasClaimedToday,
    int? streakCount,
    DateTime? lastClaimDate,
    int? lastBonusAmount,
    bool? isLoading,
  }) {
    return DailyBonusState(
      hasClaimedToday: hasClaimedToday ?? this.hasClaimedToday,
      streakCount: streakCount ?? this.streakCount,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      lastBonusAmount: lastBonusAmount ?? this.lastBonusAmount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DailyBonusStateNotifier extends StateNotifier<DailyBonusState> {
  final DailyBonusService _dailyBonusService = DailyBonusService();
  final FirebaseService _firebaseService = FirebaseService();

  DailyBonusStateNotifier()
      : super(DailyBonusState(
          hasClaimedToday: false,
          streakCount: 0,
          lastClaimDate: DateTime.now().subtract(const Duration(days: 1)),
          lastBonusAmount: 0,
          isLoading: false,
        ));

  Future<void> loadDailyBonusState(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final userDoc = await _firebaseService.getUserStats(userId);
      final userData = userDoc.data() as Map<String, dynamic>;
      final lastBonus = userData['lastDailyBonus'] as Timestamp?;
      final streakCount = userData['streakCount'] as int;

      state = state.copyWith(
        hasClaimedToday: lastBonus != null &&
            DateTime.now().difference(lastBonus.toDate()).inDays == 0,
        streakCount: streakCount,
        lastClaimDate: lastBonus?.toDate() ??
            DateTime.now().subtract(const Duration(days: 1)),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<int> claimBonus(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final bonusAmount = await _dailyBonusService.claimDailyBonus(userId);
      await loadDailyBonusState(userId);
      return bonusAmount;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}
