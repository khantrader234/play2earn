import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_controller.dart';

class Obstacle extends PositionComponent with HasGameRef<GameController> {
  final double gameSpeed;

  Obstacle({
    required Vector2 position,
    required this.gameSpeed,
  }) : super(position: position, size: Vector2.all(50));

  @override
  void render(Canvas canvas) {
    // Draw a simple red rectangle for the obstacle
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= gameSpeed * dt;

    if (position.x < -width) {
      removeFromParent();
    }
  }
}
