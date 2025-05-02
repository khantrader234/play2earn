import 'package:flutter/material.dart';

class Obstacle extends StatelessWidget {
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;

  const Obstacle({
    Key? key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.color = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
