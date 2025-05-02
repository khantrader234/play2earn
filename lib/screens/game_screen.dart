import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/sound_manager.dart';
import '../services/achievement_manager.dart';
import '../animations/normie_animation_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SoundManager _soundManager = SoundManager();
  final AchievementManager _achievementManager = AchievementManager();

  @override
  void initState() {
    super.initState();
    _soundManager.playBackgroundMusic();
  }

  @override
  void dispose() {
    _soundManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameManager()),
        ChangeNotifierProvider(create: (_) => _achievementManager),
      ],
      child: Consumer2<GameManager, AchievementManager>(
        builder: (context, gameManager, achievementManager, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Rapid Fire: Normie\'s Mental Breakdown'),
              actions: [
                IconButton(
                  icon: Icon(_soundManager.isMuted
                      ? Icons.volume_off
                      : Icons.volume_up),
                  onPressed: () {
                    _soundManager.toggleMute();
                    setState(() {});
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildStats(gameManager),
                Expanded(
                  child: Center(
                    child: NormieAnimationController(
                      mentalStability: gameManager.mentalStability,
                      existentialDread: gameManager.existentialDread,
                      isInMeeting: gameManager.isInMeeting,
                      isGlitching: gameManager.isGlitching,
                      soundManager: _soundManager,
                    ),
                  ),
                ),
                _buildActionButtons(gameManager, achievementManager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats(GameManager gameManager) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatBar(
            'Mental Stability',
            gameManager.mentalStability,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildStatBar(
            'Existential Dread',
            gameManager.existentialDread,
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildStatBar(
            'Productivity',
            gameManager.productivity,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildStatBar(
            'Microtransaction Pressure',
            gameManager.microtransactionPressure,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      GameManager gameManager, AchievementManager achievementManager) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
            onPressed: () {
              gameManager.startMeeting();
              _soundManager.playMeetingAmbience();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('Start Meeting'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.endMeeting();
              _soundManager.stopBackgroundMusic();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('End Meeting'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.startTherapy();
              _soundManager.playTherapySession();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('Start Therapy'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.endTherapy();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('End Therapy'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.purchaseMicrotransaction();
              _soundManager.playMicrotransaction();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('Buy DLC'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.work();
              _soundManager.playWorkComplete();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('Work'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.takeBreak();
              achievementManager.checkAchievements(gameManager);
            },
            child: const Text('Take Break'),
          ),
          ElevatedButton(
            onPressed: () {
              gameManager.reset();
              achievementManager.reset();
              _soundManager.playBackgroundMusic();
            },
            child: const Text('Reset Game'),
          ),
        ],
      ),
    );
  }
}
