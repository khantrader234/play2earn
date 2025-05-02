import 'package:flutter/material.dart';
import 'game_manager.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool Function(GameManager) isUnlocked;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.points,
  });
}

class SpecialEvent {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool Function(GameManager) shouldTrigger;
  final void Function(GameManager) onTrigger;

  SpecialEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.shouldTrigger,
    required this.onTrigger,
  });
}

class AchievementManager extends ChangeNotifier {
  final List<Achievement> _achievements = [
    Achievement(
      id: 'first_tear',
      title: 'First Tear',
      description: 'Drop your first tear',
      icon: 'assets/icons/tear.png',
      isUnlocked: (game) => game.tearsDropped >= 1,
      points: 10,
    ),
    Achievement(
      id: 'meeting_master',
      title: 'Meeting Master',
      description: 'Attend 5 meetings',
      icon: 'assets/icons/meeting.png',
      isUnlocked: (game) => game.meetingsAttended >= 5,
      points: 20,
    ),
    Achievement(
      id: 'therapy_regular',
      title: 'Therapy Regular',
      description: 'Complete 3 therapy sessions',
      icon: 'assets/icons/therapy.png',
      isUnlocked: (game) => game.therapySessions >= 3,
      points: 30,
    ),
    Achievement(
      id: 'dlc_addict',
      title: 'DLC Addict',
      description: 'Purchase 5 microtransactions',
      icon: 'assets/icons/dlc.png',
      isUnlocked: (game) => game.microtransactionsPurchased >= 5,
      points: 40,
    ),
    Achievement(
      id: 'mental_breakdown',
      title: 'Mental Breakdown',
      description: 'Reach maximum existential dread',
      icon: 'assets/icons/breakdown.png',
      isUnlocked: (game) => game.existentialDread >= 0.9,
      points: 50,
    ),
    Achievement(
      id: 'workaholic',
      title: 'Workaholic',
      description: 'Maintain high productivity for 10 minutes',
      icon: 'assets/icons/work.png',
      isUnlocked: (game) => game.productivity >= 0.9,
      points: 25,
    ),
  ];

  final List<SpecialEvent> _specialEvents = [
    SpecialEvent(
      id: 'corporate_meeting',
      title: 'Emergency Meeting',
      description: 'The CEO wants to discuss your productivity',
      icon: 'assets/icons/emergency_meeting.png',
      shouldTrigger: (game) => game.productivity < 0.5 && !game.isInMeeting,
      onTrigger: (game) {
        game.startMeeting();
        game.updateMentalState(-0.3, 0.2);
      },
    ),
    SpecialEvent(
      id: 'therapy_offer',
      title: 'Therapy Session Available',
      description: 'A therapist is available for a session',
      icon: 'assets/icons/therapy_offer.png',
      shouldTrigger: (game) => game.mentalStability < 0.4 && !game.isInTherapy,
      onTrigger: (game) {
        game.startTherapy();
      },
    ),
    SpecialEvent(
      id: 'dlc_sale',
      title: 'DLC Sale!',
      description: 'Limited time offer on therapy DLC',
      icon: 'assets/icons/sale.png',
      shouldTrigger: (game) => game.microtransactionPressure < 0.5,
      onTrigger: (game) {
        game.purchaseMicrotransaction();
      },
    ),
    SpecialEvent(
      id: 'system_update',
      title: 'System Update',
      description: 'Your system needs an update',
      icon: 'assets/icons/update.png',
      shouldTrigger: (game) => game.isGlitching,
      onTrigger: (game) {
        game.updateMentalState(-0.2, 0.3);
      },
    ),
  ];

  final Map<String, bool> _unlockedAchievements = {};
  int _totalPoints = 0;
  SpecialEvent? _currentEvent;

  int get totalPoints => _totalPoints;
  List<Achievement> get achievements => _achievements;
  Map<String, bool> get unlockedAchievements => _unlockedAchievements;
  SpecialEvent? get currentEvent => _currentEvent;

  void checkAchievements(GameManager game) {
    bool hasNewAchievement = false;

    for (var achievement in _achievements) {
      if (_unlockedAchievements[achievement.id] == false) {
        if (achievement.isUnlocked(game)) {
          _unlockedAchievements[achievement.id] = true;
          _totalPoints += achievement.points;
          hasNewAchievement = true;
        }
      }
    }

    if (hasNewAchievement) {
      notifyListeners();
    }
  }

  void checkSpecialEvents(GameManager game) {
    for (var event in _specialEvents) {
      if (event.shouldTrigger(game)) {
        _currentEvent = event;
        event.onTrigger(game);
        notifyListeners();
        break;
      }
    }
  }

  void clearCurrentEvent() {
    _currentEvent = null;
    notifyListeners();
  }

  bool isUnlocked(String achievementId) {
    return _unlockedAchievements[achievementId] ?? false;
  }

  void reset() {
    _unlockedAchievements.clear();
    _totalPoints = 0;
    _currentEvent = null;
    notifyListeners();
  }
}
