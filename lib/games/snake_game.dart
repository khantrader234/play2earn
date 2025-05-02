import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({Key? key}) : super(key: key);

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static List<Color> colors = [
    Colors.purple.shade900,
    Colors.purple.shade800,
    Colors.purple.shade700,
  ];

  final int rows = 20;
  final int cols = 20;
  final randomGen = Random();

  var snake = [
    [0, 0],
  ];
  var food = [0, 0];
  var direction = 'right';
  var isPlaying = false;
  var score = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    generateFood();
  }

  void generateFood() {
    food = [
      randomGen.nextInt(rows),
      randomGen.nextInt(cols),
    ];
  }

  void startGame() {
    const duration = Duration(milliseconds: 200);
    snake = [
      [(rows / 2).floor(), (cols / 2).floor()]
    ];
    score = 0;
    direction = 'right';
    isPlaying = true;
    timer?.cancel();
    timer = Timer.periodic(duration, (Timer timer) {
      moveSnake();
      if (checkGameOver()) {
        timer.cancel();
        endGame();
      }
    });
  }

  void moveSnake() {
    setState(() {
      switch (direction) {
        case 'up':
          snake.insert(0, [snake.first[0] - 1, snake.first[1]]);
          break;
        case 'down':
          snake.insert(0, [snake.first[0] + 1, snake.first[1]]);
          break;
        case 'left':
          snake.insert(0, [snake.first[0], snake.first[1] - 1]);
          break;
        case 'right':
          snake.insert(0, [snake.first[0], snake.first[1] + 1]);
          break;
      }

      if (snake.first[0] == food[0] && snake.first[1] == food[1]) {
        generateFood();
        score += 10;
      } else {
        snake.removeLast();
      }
    });
  }

  bool checkGameOver() {
    if (!isPlaying) return false;

    if (snake.first[0] < 0 ||
        snake.first[0] >= rows ||
        snake.first[1] < 0 ||
        snake.first[1] >= cols) {
      return true;
    }

    for (var i = 1; i < snake.length; i++) {
      if (snake[i][0] == snake.first[0] && snake[i][1] == snake.first[1]) {
        return true;
      }
    }

    return false;
  }

  void endGame() {
    isPlaying = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.purple.shade900,
          title: const Text(
            'Game Over',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Score: $score',
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Play Again',
                style: TextStyle(color: Colors.yellow),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
            )
          ],
        );
      },
    );
  }

  Widget buildGameControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade900,
          ),
          onPressed: !isPlaying ? startGame : null,
          child: Text(
            !isPlaying ? 'Start' : 'Playing...',
            style: const TextStyle(color: Colors.yellow),
          ),
        ),
        Text(
          'Score: $score',
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (direction != 'up' && details.delta.dy > 0) {
                  direction = 'down';
                } else if (direction != 'down' && details.delta.dy < 0) {
                  direction = 'up';
                }
              },
              onHorizontalDragUpdate: (details) {
                if (direction != 'left' && details.delta.dx > 0) {
                  direction = 'right';
                } else if (direction != 'right' && details.delta.dx < 0) {
                  direction = 'left';
                }
              },
              child: AspectRatio(
                aspectRatio: rows / cols,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                  ),
                  itemCount: rows * cols,
                  itemBuilder: (BuildContext context, int index) {
                    var color = Colors.purple.shade900;
                    var x = (index / cols).floor();
                    var y = index % cols;

                    if (snake.any((pos) => pos[0] == x && pos[1] == y)) {
                      var snakeIndex =
                          snake.indexWhere((pos) => pos[0] == x && pos[1] == y);
                      color = colors[snakeIndex % colors.length];
                    } else if (food[0] == x && food[1] == y) {
                      color = Colors.yellow;
                    }

                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: buildGameControls(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
