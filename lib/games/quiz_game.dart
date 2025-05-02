import 'package:flutter/material.dart';
import 'dart:math';

class QuizGame extends StatefulWidget {
  const QuizGame({Key? key}) : super(key: key);

  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResult = false;
  List<bool?> _answers = [];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the capital of France?',
      'options': ['London', 'Berlin', 'Paris', 'Madrid'],
      'correctAnswer': 2,
    },
    {
      'question': 'Which planet is known as the Red Planet?',
      'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      'correctAnswer': 1,
    },
    {
      'question': 'What is the largest mammal in the world?',
      'options': ['African Elephant', 'Blue Whale', 'Giraffe', 'Hippopotamus'],
      'correctAnswer': 1,
    },
    {
      'question': 'Who painted the Mona Lisa?',
      'options': ['Van Gogh', 'Da Vinci', 'Picasso', 'Rembrandt'],
      'correctAnswer': 1,
    },
    {
      'question': 'What is the chemical symbol for gold?',
      'options': ['Ag', 'Fe', 'Au', 'Cu'],
      'correctAnswer': 2,
    },
    {
      'question': 'Which country is home to the kangaroo?',
      'options': ['New Zealand', 'South Africa', 'Australia', 'Brazil'],
      'correctAnswer': 2,
    },
    {
      'question': 'What is the largest organ in the human body?',
      'options': ['Brain', 'Heart', 'Liver', 'Skin'],
      'correctAnswer': 3,
    },
    {
      'question': 'Who wrote "Romeo and Juliet"?',
      'options': [
        'Charles Dickens',
        'William Shakespeare',
        'Jane Austen',
        'Mark Twain'
      ],
      'correctAnswer': 1,
    },
    {
      'question': 'What is the hardest natural substance on Earth?',
      'options': ['Gold', 'Iron', 'Diamond', 'Platinum'],
      'correctAnswer': 2,
    },
    {
      'question': 'Which element is most abundant in Earth\'s atmosphere?',
      'options': ['Oxygen', 'Carbon', 'Nitrogen', 'Hydrogen'],
      'correctAnswer': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _answers = List.filled(_questions.length, null);
    _questions.shuffle(Random());
  }

  void _checkAnswer(int selectedOption) {
    if (_answers[_currentQuestionIndex] != null) return;

    setState(() {
      _answers[_currentQuestionIndex] =
          selectedOption == _questions[_currentQuestionIndex]['correctAnswer'];

      if (_answers[_currentQuestionIndex]!) {
        _score += 100;
      }

      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            _showResult = true;
          }
        });
      });
    });
  }

  void _restartGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _showResult = false;
      _answers = List.filled(_questions.length, null);
      _questions.shuffle(Random());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Quiz Game'),
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
      body: _showResult ? _buildResultScreen() : _buildQuestionScreen(),
    );
  }

  Widget _buildQuestionScreen() {
    final question = _questions[_currentQuestionIndex];
    final options = question['options'] as List<String>;
    final currentAnswer = _answers[_currentQuestionIndex];

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Question ${_currentQuestionIndex + 1}/${_questions.length}',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            question['question'],
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final isSelected = currentAnswer != null &&
                    index == question['correctAnswer'] - 1;
                final isWrongSelected = currentAnswer != null &&
                    currentAnswer == false &&
                    index == question['correctAnswer'] - 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ElevatedButton(
                    onPressed: currentAnswer == null
                        ? () => _checkAnswer(index + 1)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.green
                          : isWrongSelected
                              ? Colors.red
                              : Colors.purple,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      options[index],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final correctAnswers = _answers.where((answer) => answer == true).length;
    final percentage = (correctAnswers / _questions.length * 100).round();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Quiz Complete!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Score: $_score',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Correct Answers: $correctAnswers/${_questions.length}',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Percentage: $percentage%',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _restartGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: const Text(
              'Play Again',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
