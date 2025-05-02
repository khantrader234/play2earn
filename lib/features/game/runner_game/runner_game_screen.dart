import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flame/parallax.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/particles.dart';
import 'package:flame/effects.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/models/transaction_model.dart';

class RunnerGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Player player;
  late double gravity = 1000;
  late double groundY;
  late TextComponent scoreText;
  late TextComponent highScoreText;
  late TextComponent multiplierText;
  int score = 0;
  int highScore = 0;
  int scoreMultiplier = 1;
  double obstacleSpawnTimer = 0;
  double powerUpSpawnTimer = 0;
  final double obstacleSpawnInterval = 1.5;
  final double powerUpSpawnInterval = 10.0;
  final Random random = Random();
  final TransactionService _transactionService = TransactionService();
  bool hasClaimedReward = false;
  bool isInvincible = false;
  double invincibilityTimer = 0;
  final double invincibilityDuration = 5.0;
  double multiplierTimer = 0;
  final double multiplierDuration = 10.0;
  AudioPool? jumpSound;
  AudioPool? powerUpSound;
  AudioPool? gameOverSound;

  @override
  Future<void> onLoad() async {
    // Load sounds
    try {
      jumpSound = await FlameAudio.createPool(
        'sounds/jump.mp3',
        maxPlayers: 3,
      );
      powerUpSound = await FlameAudio.createPool(
        'sounds/powerup.mp3',
        maxPlayers: 2,
      );
      gameOverSound = await FlameAudio.createPool(
        'sounds/game_over.mp3',
        maxPlayers: 1,
      );
    } catch (e) {
      print('Warning: Sound files not found. Game will run without sound.');
    }

    // Load background
    final parallax = await loadParallaxComponent(
      [
        ParallaxImageData('backgrounds/sky.png'),
        ParallaxImageData('backgrounds/clouds.png'),
        ParallaxImageData('backgrounds/mountains.png'),
        ParallaxImageData('backgrounds/ground.png'),
      ],
      baseVelocity: Vector2(50, 0),
      velocityMultiplierDelta: Vector2(1.0, 0),
      repeat: ImageRepeat.repeatX,
      priority: -1,
      alignment: Alignment.bottomLeft,
    );

    // Adjust layer velocities
    parallax.parallax?.layers[0].velocityMultiplier =
        Vector2(0.0, 0); // Sky (static)
    parallax.parallax?.layers[1].velocityMultiplier =
        Vector2(0.5, 0); // Clouds (slow)
    parallax.parallax?.layers[2].velocityMultiplier =
        Vector2(0.75, 0); // Mountains (medium)
    parallax.parallax?.layers[3].velocityMultiplier =
        Vector2(1.0, 0); // Ground (fast)

    add(parallax);

    // Set ground position
    groundY = size.y - 100;

    // Add player
    player = Player(game: this);
    player.position = Vector2(50, groundY);
    add(player);

    // Add score text
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Add high score text
    highScoreText = TextComponent(
      text: 'High Score: 0',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(highScoreText);

    // Add multiplier text
    multiplierText = TextComponent(
      text: 'x1',
      position: Vector2(20, 80),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.green,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(multiplierText);

    // Load high score
    await _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        highScore = data['runnerHighScore'] ?? 0;
        highScoreText.text = 'High Score: $highScore';
      }
    }
  }

  Future<void> _updateHighScore() async {
    if (score > highScore) {
      highScore = score;
      highScoreText.text = 'High Score: $highScore';

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'runnerHighScore': highScore,
        });
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update score with multiplier
    score += (60 * dt * scoreMultiplier).toInt();
    scoreText.text = 'Score: $score';

    // Spawn obstacles
    obstacleSpawnTimer += dt;
    if (obstacleSpawnTimer >= obstacleSpawnInterval) {
      _spawnObstacle();
      obstacleSpawnTimer = 0;
    }

    // Spawn power-ups
    powerUpSpawnTimer += dt;
    if (powerUpSpawnTimer >= powerUpSpawnInterval) {
      _spawnPowerUp();
      powerUpSpawnTimer = 0;
    }

    // Update invincibility
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0;
      }
    }

    // Update score multiplier
    if (scoreMultiplier > 1) {
      multiplierTimer += dt;
      if (multiplierTimer >= multiplierDuration) {
        scoreMultiplier = 1;
        multiplierTimer = 0;
        multiplierText.text = 'x1';
      }
    }
  }

  void _spawnObstacle() {
    final obstacleType = random.nextInt(3);
    Obstacle obstacle;

    switch (obstacleType) {
      case 0:
        obstacle = GroundObstacle();
        break;
      case 1:
        obstacle = FlyingObstacle();
        break;
      case 2:
        obstacle = JumpingObstacle();
        break;
      default:
        obstacle = GroundObstacle();
    }

    obstacle.position = Vector2(size.x + 50, groundY);
    add(obstacle);
  }

  void _spawnPowerUp() {
    final powerUpType = random.nextInt(2);
    PowerUp powerUp;

    switch (powerUpType) {
      case 0:
        powerUp = InvincibilityPowerUp();
        break;
      case 1:
        powerUp = MultiplierPowerUp();
        break;
      default:
        powerUp = InvincibilityPowerUp();
    }

    powerUp.position = Vector2(
      size.x + 50,
      groundY - random.nextDouble() * 200,
    );
    add(powerUp);
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.jump();
  }

  void gameOver() {
    if (!isInvincible) {
      _updateHighScore();
      gameOverSound?.start();
      pauseEngine();
      overlays.add('gameOver');
    }
  }

  void activatePowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.invincibility:
        isInvincible = true;
        invincibilityTimer = 0;
        _createParticleEffect(
          position: player.position,
          color: Colors.blue,
        );
        break;
      case PowerUpType.multiplier:
        scoreMultiplier = 2;
        multiplierTimer = 0;
        multiplierText.text = 'x2';
        _createParticleEffect(
          position: player.position,
          color: Colors.green,
        );
        break;
    }
    powerUpSound?.start();
  }

  void _createParticleEffect({
    required Vector2 position,
    required Color color,
  }) {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      final particle = CircleComponent(
        position: position,
        radius: 5,
        paint: Paint()..color = color,
      );

      add(particle);

      // Add a simple move behavior
      particle.add(
        MoveEffect.by(
          Vector2(
            (random.nextDouble() - 0.5) * 200,
            (random.nextDouble() - 0.5) * 200,
          ),
          EffectController(
            duration: 1,
            curve: Curves.easeOut,
          ),
          onComplete: () => particle.removeFromParent(),
        ),
      );

      // Add a fade out effect
      particle.add(
        OpacityEffect.fadeOut(
          EffectController(
            duration: 1,
            curve: Curves.easeOut,
          ),
        ),
      );
    }
  }

  Future<void> _claimReward() async {
    if (hasClaimedReward) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Calculate reward based on score (1 coin per 100 points)
    final reward = (score / 100).floor();

    try {
      // Update user's coins
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'coins': FieldValue.increment(reward),
      });

      // Record transaction
      await _transactionService.recordTransaction(
        userId: user.uid,
        amount: reward,
        type: TransactionType.earned,
        source: 'Runner Game',
        description: 'Game Score: $score, Reward: $reward coins',
      );

      hasClaimedReward = true;
    } catch (e) {
      print('Error claiming reward: $e');
    }
  }
}

enum PowerUpType {
  invincibility,
  multiplier,
}

abstract class Obstacle extends SpriteComponent with CollisionCallbacks {
  static const double speed = 300;

  Obstacle() : super(size: Vector2(30, 50));

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    if (position.x < -50) {
      removeFromParent();
    }
  }
}

class GroundObstacle extends Obstacle {
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('sprites/obstacle_ground.png');
    add(RectangleHitbox());
  }
}

class FlyingObstacle extends Obstacle {
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('sprites/obstacle_flying.png');
    add(RectangleHitbox());
  }
}

class JumpingObstacle extends Obstacle {
  double velocityY = 0;
  bool isJumping = false;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('sprites/obstacle_jumping.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    final game = parent as RunnerGame;

    // Apply gravity
    velocityY += game.gravity * dt;
    position.y += velocityY * dt;

    // Ground collision
    if (position.y >= game.groundY) {
      position.y = game.groundY;
      velocityY = 0;
      isJumping = false;
    }

    // Random jumping
    if (!isJumping && Random().nextDouble() < 0.01) {
      velocityY = -300;
      isJumping = true;
    }
  }
}

abstract class PowerUp extends SpriteComponent with CollisionCallbacks {
  static const double speed = 200;
  final PowerUpType type;

  PowerUp({required this.type}) : super(size: Vector2(30, 30));

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    if (position.x < -50) {
      removeFromParent();
    }
  }
}

class InvincibilityPowerUp extends PowerUp {
  InvincibilityPowerUp() : super(type: PowerUpType.invincibility);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('sprites/powerup_invincible.png');
    add(RectangleHitbox());
  }
}

class MultiplierPowerUp extends PowerUp {
  MultiplierPowerUp() : super(type: PowerUpType.multiplier);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('sprites/powerup_multiplier.png');
    add(RectangleHitbox());
  }
}

class Player extends SpriteComponent with CollisionCallbacks {
  double velocityY = 0;
  bool isJumping = false;
  bool canDoubleJump = false;
  final RunnerGame game;

  Player({required this.game}) : super(size: Vector2(50, 50));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('sprites/player.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    velocityY += game.gravity * dt;
    position.y += velocityY * dt;

    // Ground collision
    if (position.y >= game.groundY) {
      position.y = game.groundY;
      velocityY = 0;
      isJumping = false;
      canDoubleJump = true;
    }
  }

  void jump() {
    if (!isJumping) {
      velocityY = -500;
      isJumping = true;
      game.jumpSound?.start();
    } else if (canDoubleJump) {
      velocityY = -400;
      canDoubleJump = false;
      game.jumpSound?.start();
    }
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Obstacle) {
      game.gameOver();
    } else if (other is PowerUp) {
      game.activatePowerUp(other.type);
      other.removeFromParent();
    }
  }
}

class RunnerGameScreen extends StatelessWidget {
  const RunnerGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<RunnerGame>(
        game: RunnerGame(),
        overlayBuilderMap: {
          'gameOver': (context, game) => Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Game Over',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score: ${game.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'High Score: ${game.highScore}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reward: ${(game.score / 100).floor()} coins',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: game.hasClaimedReward
                            ? null
                            : () async {
                                await game._claimReward();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Claimed ${(game.score / 100).floor()} coins!',
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: game.hasClaimedReward
                              ? Colors.grey
                              : Colors.green,
                        ),
                        child: Text(
                          game.hasClaimedReward
                              ? 'Reward Claimed'
                              : 'Claim Reward',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('gameOver');
                          game.resumeEngine();
                          game.score = 0;
                          game.player.position.y = game.groundY;
                          game.player.velocityY = 0;
                          game.hasClaimedReward = false;
                        },
                        child: const Text('Play Again'),
                      ),
                    ],
                  ),
                ),
              ),
        },
      ),
    );
  }
}
