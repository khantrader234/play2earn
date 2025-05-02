import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController gameController;
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> coins = ValueNotifier<int>(0);
  final ValueNotifier<bool> isGameOver = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    gameController = GameController(
      onScoreChanged: (newScore) => score.value = newScore,
      onCoinsCollected: (newCoins) => coins.value = newCoins,
      onGameOver: () => isGameOver.value = true,
    );
  }

  @override
  void dispose() {
    score.dispose();
    coins.dispose();
    isGameOver.dispose();
    gameController.onRemove();
    super.dispose();
  }

  void restartGame() {
    score.value = 0;
    coins.value = 0;
    isGameOver.value = false;
    gameController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: gameController,
            overlayBuilderMap: {
              'score': (_, __) => ValueListenableBuilder<int>(
                    valueListenable: score,
                    builder: (context, value, _) => Positioned(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 20,
                      child: Text(
                        'Score: $value',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2.0, 2.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              'coins': (_, __) => ValueListenableBuilder<int>(
                    valueListenable: coins,
                    builder: (context, value, _) => Positioned(
                      top: MediaQuery.of(context).padding.top + 20,
                      right: 20,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(2.0, 2.0),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              'gameOver': (_, __) => ValueListenableBuilder<bool>(
                    valueListenable: isGameOver,
                    builder: (context, value, _) => value
                        ? Center(
                            child: SingleChildScrollView(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Game Over!',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(2.0, 2.0),
                                            blurRadius: 3.0,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Score: ${score.value}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: restartGame,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                      ),
                                      child: const Text(
                                        'Play Again',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
            },
            initialActiveOverlays: const ['score', 'coins'],
          ),
        ],
      ),
    );
  }
}
