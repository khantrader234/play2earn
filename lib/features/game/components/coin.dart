import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_controller.dart';

class Coin extends PositionComponent with HasGameReference<GameController> {
  final double gameSpeed;

  Coin({required Vector2 position, required this.gameSpeed})
      : super(position: position, size: Vector2(30, 30));

  @override
  void render(Canvas canvas) {
    // Draw a simple gold circle for the coin
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = Colors.amber
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
