import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class SpinGameService {
  static final SpinGameService _instance = SpinGameService._internal();
  factory SpinGameService() => _instance;
  SpinGameService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Spin game configuration
  static const List<SpinReward> rewards = [
    SpinReward(amount: 10, probability: 0.4), // 40% chance
    SpinReward(amount: 25, probability: 0.3), // 30% chance
    SpinReward(amount: 50, probability: 0.2), // 20% chance
    SpinReward(amount: 100, probability: 0.1), // 10% chance
  ];

  // Spin cost
  static const int spinCost = 20;

  // Calculate spin result
  SpinResult calculateSpinResult() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    double cumulativeProbability = 0;

    for (final reward in rewards) {
      cumulativeProbability += reward.probability;
      if (random <= cumulativeProbability) {
        return SpinResult(
          amount: reward.amount,
          isJackpot: reward.amount == 100,
        );
      }
    }

    // Fallback to lowest reward
    return SpinResult(
      amount: rewards.first.amount,
      isJackpot: false,
    );
  }

  // Record spin result
  Future<void> recordSpinResult(
    String userId,
    int amount,
    bool isJackpot,
  ) async {
    await _firebaseService.recordSpinResult(userId, amount, isJackpot);
    await _analytics.logEvent(
      name: 'spin_completed',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'is_jackpot': isJackpot,
      },
    );
  }

  // Get spin history
  Future<List<Map<String, dynamic>>> getSpinHistory(String userId) async {
    final snapshot = await _firebaseService.getSpinHistory(userId);
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}

class SpinReward {
  final int amount;
  final double probability;

  const SpinReward({
    required this.amount,
    required this.probability,
  });
}

class SpinResult {
  final int amount;
  final bool isJackpot;

  SpinResult({
    required this.amount,
    required this.isJackpot,
  });
}

// Spin game state provider
final spinGameStateProvider =
    StateNotifierProvider<SpinGameStateNotifier, SpinGameState>((ref) {
  return SpinGameStateNotifier();
});

class SpinGameState {
  final bool isSpinning;
  final int? lastSpinAmount;
  final bool? lastSpinWasJackpot;
  final List<SpinHistoryItem> history;
  final bool isLoading;

  SpinGameState({
    required this.isSpinning,
    this.lastSpinAmount,
    this.lastSpinWasJackpot,
    required this.history,
    required this.isLoading,
  });

  SpinGameState copyWith({
    bool? isSpinning,
    int? lastSpinAmount,
    bool? lastSpinWasJackpot,
    List<SpinHistoryItem>? history,
    bool? isLoading,
  }) {
    return SpinGameState(
      isSpinning: isSpinning ?? this.isSpinning,
      lastSpinAmount: lastSpinAmount ?? this.lastSpinAmount,
      lastSpinWasJackpot: lastSpinWasJackpot ?? this.lastSpinWasJackpot,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SpinHistoryItem {
  final String id;
  final int amount;
  final bool isJackpot;
  final DateTime timestamp;

  SpinHistoryItem({
    required this.id,
    required this.amount,
    required this.isJackpot,
    required this.timestamp,
  });
}

class SpinGameStateNotifier extends StateNotifier<SpinGameState> {
  final SpinGameService _spinGameService = SpinGameService();

  SpinGameStateNotifier()
      : super(SpinGameState(
          isSpinning: false,
          history: [],
          isLoading: false,
        ));

  Future<void> loadSpinHistory(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final history = await _spinGameService.getSpinHistory(userId);
      state = state.copyWith(
        history: history
            .map((data) => SpinHistoryItem(
                  id: data['id'] as String,
                  amount: data['amount'] as int,
                  isJackpot: data['isJackpot'] as bool,
                  timestamp: (data['timestamp'] as Timestamp).toDate(),
                ))
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<SpinResult> spin(String userId) async {
    state = state.copyWith(isSpinning: true);

    try {
      final result = _spinGameService.calculateSpinResult();
      await _spinGameService.recordSpinResult(
        userId,
        result.amount,
        result.isJackpot,
      );

      state = state.copyWith(
        isSpinning: false,
        lastSpinAmount: result.amount,
        lastSpinWasJackpot: result.isJackpot,
      );

      await loadSpinHistory(userId);
      return result;
    } catch (e) {
      state = state.copyWith(isSpinning: false);
      rethrow;
    }
  }
}
