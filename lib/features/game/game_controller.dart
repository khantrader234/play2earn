import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'components/player.dart';
import 'components/coin.dart';
import 'components/obstacle.dart';

class GameController extends FlameGame with TapDetector, KeyboardHandler {
  // Game components
  late Player player;
  final List<Coin> coins = [];
  final List<Obstacle> obstacles = [];
  late ParticleSystemComponent particleSystem;

  // Game state
  bool isGameOver = false;
  int score = 0;
  int collectedCoins = 0;
  double gameSpeed = 300.0;
  final double maxGameSpeed = 600.0;
  final double speedIncrease = 10.0;

  // Physics constants
  static const double gravity = 800.0;
  static const double jumpForce = -400.0;

  // Spawn timers
  double obstacleSpawnTimer = 0;
  double coinSpawnTimer = 0;

  // Callbacks
  final Function(int) onScoreChanged;
  final Function(int) onCoinsCollected;
  final VoidCallback onGameOver;

  // Power-ups
  List<String> activePowerUps = [];

  GameController({
    required this.onScoreChanged,
    required this.onCoinsCollected,
    required this.onGameOver,
  });

  @override
  Future<void> onLoad() async {
    print('GameController: onLoad called');
    // Add background
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(size.x, size.y),
        paint: Paint()..color = const Color(0xFF1A237E),
      ),
    );

    // Add stars (decorative background elements)
    final random = Random();
    for (int i = 0; i < 50; i++) {
      final starPosition = Vector2(
        random.nextDouble() * size.x,
        random.nextDouble() * size.y,
      );
      add(
        CircleComponent(
          position: starPosition,
          radius: random.nextDouble() * 2 + 1,
          paint: Paint()
            ..color = Colors.white.withValues(
              alpha: 0.8 * 255,
              red: 255,
              green: 255,
              blue: 255,
            ),
        ),
      );
    }

    // Initialize player
    player = Player(
      position: Vector2(100, size.y - 100),
      size: Vector2(50, 50),
    );
    await add(player);
    print('GameController: Player added');

    // Initialize particle system
    particleSystem = ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 0.5,
        generator: (i) => CircleParticle(
          paint: Paint()..color = Colors.amber,
          radius: 5,
        ),
      ),
    );
    await add(particleSystem);

    // Add ground
    add(
      RectangleComponent(
        position: Vector2(0, size.y - 40),
        size: Vector2(size.x, 40),
        paint: Paint()..color = const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) return;

    // Update score
    score += (dt * 10).toInt();
    onScoreChanged(score);

    // Update game speed
    gameSpeed = min(gameSpeed + speedIncrease * dt, maxGameSpeed);

    // Spawn obstacles
    obstacleSpawnTimer += dt;
    if (obstacleSpawnTimer >= 2.0) {
      obstacleSpawnTimer = 0;
      _spawnObstacle();
    }

    // Spawn coins
    coinSpawnTimer += dt;
    if (coinSpawnTimer >= 1.0) {
      coinSpawnTimer = 0;
      _spawnCoin();
    }

    // Check collisions
    _checkCollisions();
  }

  void _spawnObstacle() {
    final random = Random();
    final obstacleType = random.nextInt(3);
    final obstacle = Obstacle(
      position: Vector2(size.x + 50, size.y - 100),
      gameSpeed: gameSpeed,
    );
    add(obstacle);
    obstacles.add(obstacle);
  }

  void _spawnCoin() {
    final random = Random();
    final coin = Coin(
      position: Vector2(
        size.x + 50,
        size.y - 150 - random.nextDouble() * 100,
      ),
      gameSpeed: gameSpeed,
    );
    add(coin);
    coins.add(coin);
  }

  void _checkCollisions() {
    // Check player-obstacle collisions
    for (final obstacle in obstacles) {
      if (player.collidesWith(obstacle)) {
        _handleGameOver();
        return;
      }
    }

    // Check player-coin collisions
    for (final coin in coins) {
      if (player.collidesWith(coin)) {
        coin.removeFromParent();
        coins.remove(coin);
        collectedCoins++;
        onCoinsCollected(collectedCoins);
        break;
      }
    }
  }

  void _handleGameOver() {
    print('GameController: Game Over');
    isGameOver = true;
    onGameOver();
    updateFirestore();
  }

  Future<void> updateFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        final currentHighScore = snapshot.data()?['highScore'] ?? 0;
        final currentCoins = snapshot.data()?['coins'] ?? 0;

        if (score > currentHighScore) {
          transaction.update(userDoc, {'highScore': score});
        }

        transaction.update(userDoc, {
          'coins': currentCoins + collectedCoins,
          'gamesPlayed': FieldValue.increment(1),
        });
      });
    }
  }

  @override
  void onTap() {
    if (!isGameOver) {
      player.jump();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && !isGameOver) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        player.jump();
      }
    }
    return true;
  }

  void reset() {
    print('GameController: Reset called');
    isGameOver = false;
    score = 0;
    collectedCoins = 0;
    gameSpeed = 300.0;
    player.reset();

    // Remove all obstacles and coins
    for (final obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();

    for (final coin in coins) {
      coin.removeFromParent();
    }
    coins.clear();
  }

  @override
  void onRemove() {
    super.onRemove();
    for (final component in [...children]) {
      component.removeFromParent();
    }
  }
}
