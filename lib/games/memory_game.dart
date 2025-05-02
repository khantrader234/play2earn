import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class MemoryGame extends StatefulWidget {
  const MemoryGame({Key? key}) : super(key: key);

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final int _numPairs = 8;
  late List<String> _items;
  late List<bool> _flipped;
  late List<bool> _matched;
  late bool _isProcessing;
  int _score = 0;
  int _moves = 0;
  Timer? _timer;
  int _secondsElapsed = 0;
  int? _firstFlippedIndex;

  final List<String> _emojis = [
    '🎮',
    '🎲',
    '🎯',
    '🎪',
    '🎨',
    '🎭',
    '🎪',
    '🎢',
    '🎡',
    '🎠',
    '🎪',
    '🎭',
    '🎨',
    '🎯',
    '🎲',
    '🎮',
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Create pairs of items
    _items = [];
    List<String> availableEmojis = List.from(_emojis);
    for (int i = 0; i < _numPairs; i++) {
      int randomIndex = Random().nextInt(availableEmojis.length);
      String selectedEmoji = availableEmojis[randomIndex];
      _items.add(selectedEmoji);
      _items.add(selectedEmoji);
      availableEmojis.removeAt(randomIndex);
    }

    // Shuffle the items
    _items.shuffle();

    // Initialize game state
    _flipped = List.filled(_numPairs * 2, false);
    _matched = List.filled(_numPairs * 2, false);
    _isProcessing = false;
    _score = 0;
    _moves = 0;
    _secondsElapsed = 0;
    _firstFlippedIndex = null;

    // Start the timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing || _flipped[index] || _matched[index]) return;

    setState(() {
      _flipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _moves++;
      if (_items[_firstFlippedIndex!] == _items[index]) {
        // Match found
        _matched[_firstFlippedIndex!] = true;
        _matched[index] = true;
        _score += 100;
        _firstFlippedIndex = null;

        // Check if game is complete
        if (_matched.every((m) => m)) {
          _timer?.cancel();
          _showGameOverDialog();
        }
      } else {
        // No match
        _isProcessing = true;
        Timer(const Duration(milliseconds: 1000), () {
          setState(() {
            _flipped[_firstFlippedIndex!] = false;
            _flipped[index] = false;
            _firstFlippedIndex = null;
            _isProcessing = false;
          });
        });
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $_score'),
            Text('Moves: $_moves'),
            Text('Time: $_secondsElapsed seconds'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _initializeGame();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Memory Game'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Moves: $_moves',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  'Time: ${_secondsElapsed}s',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _numPairs * 2,
                itemBuilder: (context, index) {
                  return _buildCard(index);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializeGame();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Restart Game',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: _matched[index]
              ? Colors.green.withOpacity(0.5)
              : _flipped[index]
                  ? Colors.purple
                  : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _flipped[index] || _matched[index]
              ? Text(
                  _items[index],
                  style: const TextStyle(fontSize: 32),
                )
              : const Icon(
                  Icons.question_mark,
                  color: Colors.white54,
                  size: 32,
                ),
        ),
      ),
    );
  }
}
