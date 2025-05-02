import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class RapidFireGame extends StatefulWidget {
  const RapidFireGame({Key? key}) : super(key: key);

  @override
  State<RapidFireGame> createState() => _RapidFireGameState();
}

class _RapidFireGameState extends State<RapidFireGame> {
  int _score = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  Timer? _gameTimer;
  Timer? _targetTimer;
  List<Offset> _targets = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _targets = [];
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _endGame();
        }
      });
    });

    _targetTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_isPlaying) {
        setState(() {
          _targets.add(Offset(
            _random.nextDouble() * 0.8 + 0.1,
            _random.nextDouble() * 0.6 + 0.2,
          ));
        });
      }
    });
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _gameTimer?.cancel();
      _targetTimer?.cancel();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _onTargetTap(Offset target) {
    if (!_isPlaying) return;

    setState(() {
      _score += 10;
      _targets.remove(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Rapid Fire'),
        backgroundColor: Colors.black87,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Timer display
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_timeLeft',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Targets
          ..._targets.map((target) => Positioned(
                left: target.dx * MediaQuery.of(context).size.width,
                top: target.dy * MediaQuery.of(context).size.height,
                child: GestureDetector(
                  onTap: () => _onTargetTap(target),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.amber,
                      size: 30,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
