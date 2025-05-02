import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isMuted = false;

  // Sound effects
  static const String _breathingNormal = 'assets/sounds/breathing_normal.mp3';
  static const String _breathingStressed =
      'assets/sounds/breathing_stressed.mp3';
  static const String _breathingBreakdown =
      'assets/sounds/breathing_breakdown.mp3';
  static const String _meetingAmbience = 'assets/sounds/meeting_ambience.mp3';
  static const String _tearDrop = 'assets/sounds/tear_drop.mp3';
  static const String _glitchEffect = 'assets/sounds/glitch_effect.mp3';
  static const String _achievementUnlocked =
      'assets/sounds/achievement_unlocked.mp3';
  static const String _specialEvent = 'assets/sounds/special_event.mp3';
  static const String _workComplete = 'assets/sounds/work_complete.mp3';
  static const String _therapySession = 'assets/sounds/therapy_session.mp3';
  static const String _microtransaction = 'assets/sounds/microtransaction.mp3';
  static const String _backgroundMusic = 'assets/sounds/background_music.mp3';

  // Play sound effects
  Future<void> playBreathingNormal() async {
    if (!_isMuted) await _player.play(AssetSource(_breathingNormal));
  }

  Future<void> playBreathingStressed() async {
    if (!_isMuted) await _player.play(AssetSource(_breathingStressed));
  }

  Future<void> playBreathingBreakdown() async {
    if (!_isMuted) await _player.play(AssetSource(_breathingBreakdown));
  }

  Future<void> playMeetingAmbience() async {
    if (!_isMuted) await _player.play(AssetSource(_meetingAmbience));
  }

  Future<void> playTearDrop() async {
    if (!_isMuted) await _player.play(AssetSource(_tearDrop));
  }

  Future<void> playGlitchEffect() async {
    if (!_isMuted) await _player.play(AssetSource(_glitchEffect));
  }

  Future<void> playAchievementUnlocked() async {
    if (!_isMuted) await _player.play(AssetSource(_achievementUnlocked));
  }

  Future<void> playSpecialEvent() async {
    if (!_isMuted) await _player.play(AssetSource(_specialEvent));
  }

  Future<void> playWorkComplete() async {
    if (!_isMuted) await _player.play(AssetSource(_workComplete));
  }

  Future<void> playTherapySession() async {
    if (!_isMuted) await _player.play(AssetSource(_therapySession));
  }

  Future<void> playMicrotransaction() async {
    if (!_isMuted) await _player.play(AssetSource(_microtransaction));
  }

  // Background music
  Future<void> playBackgroundMusic() async {
    if (!_isMuted) {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource(_backgroundMusic));
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
  }

  // Mute control
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _player.stop();
      _bgmPlayer.stop();
    } else {
      playBackgroundMusic();
    }
  }

  bool get isMuted => _isMuted;

  // Cleanup
  void dispose() {
    _player.dispose();
    _bgmPlayer.dispose();
  }
}
