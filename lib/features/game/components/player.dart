import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_controller.dart';

class Player extends PositionComponent with HasGameRef<GameController> {
  // Physics properties
  static const double gravity = 800.0;
  static const double jumpForce = -400.0;
  bool isJumping = false;
  double verticalVelocity = 0;

  Player({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    // Draw a simple blue rectangle for the player
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    verticalVelocity += gravity * dt;
    position.y += verticalVelocity * dt;

    // Ground collision
    if (position.y > game.size.y - 90) {
      position.y = game.size.y - 90;
      verticalVelocity = 0;
      isJumping = false;
    }
  }

  void jump() {
    if (!isJumping) {
      verticalVelocity = jumpForce;
      isJumping = true;
    }
  }

  bool collidesWith(PositionComponent other) {
    return toRect().overlaps(other.toRect());
  }

  void reset() {
    position = Vector2(100, game.size.y - 100);
    verticalVelocity = 0;
    isJumping = false;
  }
}
