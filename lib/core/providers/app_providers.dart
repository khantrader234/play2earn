import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// User State Provider
final userProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Wallet Balance Provider
final walletBalanceProvider = StateProvider<double>((ref) => 0.0);

// Daily Bonus State Provider
final dailyBonusProvider =
    StateNotifierProvider<DailyBonusNotifier, DailyBonusState>((ref) {
  return DailyBonusNotifier();
});

class DailyBonusState {
  final bool hasClaimedToday;
  final int streakCount;
  final DateTime lastClaimDate;

  DailyBonusState({
    required this.hasClaimedToday,
    required this.streakCount,
    required this.lastClaimDate,
  });

  DailyBonusState copyWith({
    bool? hasClaimedToday,
    int? streakCount,
    DateTime? lastClaimDate,
  }) {
    return DailyBonusState(
      hasClaimedToday: hasClaimedToday ?? this.hasClaimedToday,
      streakCount: streakCount ?? this.streakCount,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
    );
  }
}

class DailyBonusNotifier extends StateNotifier<DailyBonusState> {
  DailyBonusNotifier()
      : super(DailyBonusState(
          hasClaimedToday: false,
          streakCount: 0,
          lastClaimDate: DateTime.now().subtract(const Duration(days: 1)),
        ));

  void claimBonus() {
    final now = DateTime.now();
    final lastClaim = state.lastClaimDate;
    final isNextDay = now.difference(lastClaim).inDays >= 1;

    if (isNextDay) {
      final newStreak =
          now.difference(lastClaim).inDays == 1 ? state.streakCount + 1 : 1;

      state = state.copyWith(
        hasClaimedToday: true,
        streakCount: newStreak,
        lastClaimDate: now,
      );
    }
  }
}

// Ad Watch History Provider
final adHistoryProvider =
    StateNotifierProvider<AdHistoryNotifier, List<AdHistoryItem>>((ref) {
  return AdHistoryNotifier();
});

class AdHistoryItem {
  final String id;
  final DateTime timestamp;
  final int coinsEarned;
  final String adType;

  AdHistoryItem({
    required this.id,
    required this.timestamp,
    required this.coinsEarned,
    required this.adType,
  });
}

class AdHistoryNotifier extends StateNotifier<List<AdHistoryItem>> {
  AdHistoryNotifier() : super([]);

  void addAdWatch(String adType, int coinsEarned) {
    state = [
      AdHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        coinsEarned: coinsEarned,
        adType: adType,
      ),
      ...state,
    ];
  }
}

// Game State Provider
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

class GameState {
  final bool isPlaying;
  final int currentScore;
  final int highScore;
  final int coinsEarned;

  GameState({
    required this.isPlaying,
    required this.currentScore,
    required this.highScore,
    required this.coinsEarned,
  });

  GameState copyWith({
    bool? isPlaying,
    int? currentScore,
    int? highScore,
    int? coinsEarned,
  }) {
    return GameState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentScore: currentScore ?? this.currentScore,
      highScore: highScore ?? this.highScore,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier()
      : super(GameState(
          isPlaying: false,
          currentScore: 0,
          highScore: 0,
          coinsEarned: 0,
        ));

  void startGame() {
    state = state.copyWith(
      isPlaying: true,
      currentScore: 0,
    );
  }

  void updateScore(int newScore) {
    state = state.copyWith(
      currentScore: newScore,
      highScore: newScore > state.highScore ? newScore : state.highScore,
    );
  }

  void endGame(int coinsEarned) {
    state = state.copyWith(
      isPlaying: false,
      coinsEarned: state.coinsEarned + coinsEarned,
    );
  }
}
