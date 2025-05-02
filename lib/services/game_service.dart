import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_service.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Game configuration
  static const int baseCoinReward = 10;
  static const int scoreMultiplier = 2;
  static const int maxBonusMultiplier = 5;
  static const int streakBonus = 5;

  // Calculate coins earned based on score and streak
  int calculateCoinsEarned(int score, int streak) {
    final baseCoins = score ~/ scoreMultiplier;
    final bonusMultiplier = streak > 0 ? (streak ~/ streakBonus) + 1 : 1;
    final finalMultiplier = bonusMultiplier > maxBonusMultiplier
        ? maxBonusMultiplier
        : bonusMultiplier;

    return (baseCoins * finalMultiplier) + baseCoinReward;
  }

  // Record game completion
  Future<void> recordGameCompletion(
    String userId,
    int score,
    int coinsEarned,
    String gameType,
  ) async {
    await _firebaseService.recordGamePlay(userId, score, coinsEarned);
    await _analytics.logEvent(
      name: 'game_completed',
      parameters: {
        'game_type': gameType,
        'score': score,
        'coins_earned': coinsEarned,
      },
    );
  }

  // Get high scores
  Future<List<Map<String, dynamic>>> getHighScores(String gameType) async {
    final snapshot = await _firebaseService.getHighScores(gameType);
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final snapshot = await _firebaseService.getUserStats(userId);
    return snapshot.data() ?? {};
  }
}

// Game state provider
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

class GameState {
  final bool isPlaying;
  final int currentScore;
  final int highScore;
  final int coinsEarned;
  final int streak;
  final String? currentGameType;

  GameState({
    required this.isPlaying,
    required this.currentScore,
    required this.highScore,
    required this.coinsEarned,
    required this.streak,
    this.currentGameType,
  });

  GameState copyWith({
    bool? isPlaying,
    int? currentScore,
    int? highScore,
    int? coinsEarned,
    int? streak,
    String? currentGameType,
  }) {
    return GameState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentScore: currentScore ?? this.currentScore,
      highScore: highScore ?? this.highScore,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      streak: streak ?? this.streak,
      currentGameType: currentGameType ?? this.currentGameType,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  final GameService _gameService = GameService();

  GameStateNotifier()
      : super(GameState(
          isPlaying: false,
          currentScore: 0,
          highScore: 0,
          coinsEarned: 0,
          streak: 0,
        ));

  void startGame(String gameType) {
    state = state.copyWith(
      isPlaying: true,
      currentScore: 0,
      currentGameType: gameType,
    );
  }

  void updateScore(int newScore) {
    state = state.copyWith(
      currentScore: newScore,
      highScore: newScore > state.highScore ? newScore : state.highScore,
    );
  }

  Future<void> endGame(String userId) async {
    if (!state.isPlaying) return;

    final coinsEarned = _gameService.calculateCoinsEarned(
      state.currentScore,
      state.streak,
    );

    await _gameService.recordGameCompletion(
      userId,
      state.currentScore,
      coinsEarned,
      state.currentGameType ?? 'unknown',
    );

    state = state.copyWith(
      isPlaying: false,
      coinsEarned: state.coinsEarned + coinsEarned,
    );
  }

  void incrementStreak() {
    state = state.copyWith(streak: state.streak + 1);
  }

  void resetStreak() {
    state = state.copyWith(streak: 0);
  }
}
