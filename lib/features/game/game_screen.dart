import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import '../../core/services/user_service.dart';
import '../../core/theme/app_theme.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            color: AppTheme.accentColor,
            onPressed: () {
              // Navigate to wallet screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Rewards',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<UserService>(
                      builder: (context, userService, child) {
                        return Text(
                          '${userService.currentUser?.coins ?? 0} coins',
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Claim daily reward
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Claim'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio:
                    0.85, // Adjust this value to control card height
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final games = [
                  ('Snake Game', 'Classic snake game', Icons.games),
                  ('Memory Game', 'Test your memory', Icons.memory),
                  ('Quiz Game', 'Answer and earn', Icons.quiz),
                  (
                    'Coming Soon',
                    'More games coming soon',
                    Icons.hourglass_empty
                  ),
                ];
                final (title, description, icon) = games[index];
                return _buildGameCard(
                  context,
                  title,
                  description,
                  icon,
                  index < 3 ? () {} : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.surfaceColor,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RunnerGame extends FlameGame with TapDetector {
  late Player player;
  late TextComponent scoreText;
  late TextComponent powerUpText;
  int score = 0;
  bool isGameOver = false;
  List<String> activePowerUps = [];
  double gameSpeed = 300.0;
  final Random _random = Random();
  List<Obstacle> obstacles = [];
  List<Coin> coins = [];
  double obstacleSpawnTimer = 0;
  double coinSpawnTimer = 0;
  late UserService _userService;

  RunnerGame(UserService userService) {
    _userService = userService;
  }

  @override
  Future<void> onLoad() async {
    // Load player sprite
    final playerSprite = await loadSprite('player.png');
    player = Player(
      position: Vector2(100, size.y - 100),
      size: Vector2(50, 50),
    );
    add(player);

    // Add score text
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
    add(scoreText);

    // Add power-up text
    powerUpText = TextComponent(
      text: 'Power-ups: None',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
    add(powerUpText);

    // Load power-ups from Firestore
    await _loadPowerUps();
  }

  Future<void> _loadPowerUps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final powerUps = List<String>.from(userData?['powerUps'] ?? []);

    if (powerUps.isNotEmpty) {
      activePowerUps = powerUps;
      powerUpText.text = 'Power-ups: ${powerUps.join(", ")}';
      overlays.add('powerUps');
    }
  }

  void _spawnObstacle() {
    final obstacle = Obstacle(
      position: Vector2(size.x + 50, size.y - 50),
      size: Vector2(30, 30),
    );
    obstacles.add(obstacle);
    add(obstacle);
  }

  void _spawnCoin() {
    final coin = Coin(
      position: Vector2(size.x + 50, size.y - 100),
      size: Vector2(20, 20),
    );
    coins.add(coin);
    add(coin);
  }

  Future<void> _updateCoins(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _userService.addCoins(amount);
  }

  void _gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    pauseEngine();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userService.updateHighScore(user.uid, score);
      _userService.incrementGamesPlayed();
    }

    overlays.add('gameOver');
  }

  void _usePowerUp(String powerUpType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _userService.usePowerUp(powerUpType);
    activePowerUps.remove(powerUpType);
    powerUpText.text = 'Power-ups: ${activePowerUps.join(", ")}';
    if (activePowerUps.isEmpty) {
      overlays.remove('powerUps');
    }
  }

  void _checkCollisions() {
    for (final obstacle in obstacles) {
      if (player.toRect().overlaps(obstacle.toRect())) {
        if (activePowerUps.contains('shield')) {
          _usePowerUp('shield');
          obstacle.removeFromParent();
          obstacles.remove(obstacle);
        } else if (activePowerUps.contains('extraLife')) {
          _usePowerUp('extraLife');
          obstacle.removeFromParent();
          obstacles.remove(obstacle);
        } else {
          _gameOver();
        }
      }
    }

    for (final coin in coins) {
      if (player.toRect().overlaps(coin.toRect())) {
        score += activePowerUps.contains('doublePoints') ? 2 : 1;
        scoreText.text = 'Score: $score';
        coin.removeFromParent();
        coins.remove(coin);
        _updateCoins(1);
      }
    }
  }

  void resetGame() {
    isGameOver = false;
    score = 0;
    scoreText.text = 'Score: 0';
    gameSpeed = 300.0;

    // Remove all obstacles and coins
    for (final obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();

    for (final coin in coins) {
      coin.removeFromParent();
    }
    coins.clear();

    // Reset player position
    player.position = Vector2(100, size.y - 100);
    player.speedY = 0;

    resumeEngine();
    overlays.remove('gameOver');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // Increase game speed over time
    gameSpeed += dt * 10;
    if (gameSpeed > 600) gameSpeed = 600;

    // Spawn obstacles
    obstacleSpawnTimer += dt;
    if (obstacleSpawnTimer >= 2) {
      obstacleSpawnTimer = 0;
      _spawnObstacle();
    }

    // Spawn coins
    coinSpawnTimer += dt;
    if (coinSpawnTimer >= 1) {
      coinSpawnTimer = 0;
      _spawnCoin();
    }

    // Move obstacles and coins
    for (final obstacle in obstacles) {
      obstacle.position.x -= gameSpeed * dt;
      if (obstacle.position.x < -obstacle.size.x) {
        obstacle.removeFromParent();
        obstacles.remove(obstacle);
      }
    }

    for (final coin in coins) {
      coin.position.x -= gameSpeed * dt;
      if (coin.position.x < -coin.size.x) {
        coin.removeFromParent();
        coins.remove(coin);
      }
    }

    _checkCollisions();
  }

  @override
  void onTap() {
    if (!isGameOver) {
      player.jump();
    }
  }
}

class Player extends PositionComponent with HasGameRef<RunnerGame> {
  double speedY = 0;
  final double gravity = 800;
  final double jumpSpeed = -400;

  Player({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = Colors.blue);
  }

  void jump() {
    if (position.y >= gameRef.size.y - 100) {
      speedY = jumpSpeed;
    }
  }

  @override
  void update(double dt) {
    speedY += gravity * dt;
    position.y += speedY * dt;

    if (position.y > gameRef.size.y - 100) {
      position.y = gameRef.size.y - 100;
      speedY = 0;
    }

    super.update(dt);
  }
}

class Obstacle extends PositionComponent with HasGameRef<RunnerGame> {
  Obstacle({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = Colors.red);
  }
}

class Coin extends PositionComponent with HasGameRef<RunnerGame> {
  Coin({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.amber,
    );
  }
}

class PowerUpOverlay extends StatelessWidget {
  final RunnerGame game;

  const PowerUpOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(
            alpha: 0.5 * 255,
            red: 0,
            green: 0,
            blue: 0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: game.activePowerUps.map((powerUp) {
            IconData icon;
            Color color;
            switch (powerUp) {
              case 'doublePoints':
                icon = Icons.star;
                color = Colors.amber;
                break;
              case 'extraLife':
                icon = Icons.favorite;
                color = Colors.red;
                break;
              case 'shield':
                icon = Icons.shield;
                color = Colors.blue;
                break;
              default:
                icon = Icons.help;
                color = Colors.grey;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    powerUp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final RunnerGame game;

  const GameOverOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.8 * 255,
            red: 255,
            green: 255,
            blue: 255,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${game.score}',
              style: const TextStyle(fontSize: 24, color: Colors.black),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                game.resetGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
