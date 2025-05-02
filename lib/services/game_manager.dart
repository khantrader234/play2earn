import 'dart:math';
import 'package:flutter/material.dart';

class GameManager extends ChangeNotifier {
  double _mentalStability = 1.0;
  double _existentialDread = 0.0;
  double _productivity = 1.0;
  double _microtransactionPressure = 0.0;
  bool _isInMeeting = false;
  bool _isInTherapy = false;
  bool _isGlitching = false;
  int _tearsDropped = 0;
  int _meetingsAttended = 0;
  int _therapySessions = 0;
  int _microtransactionsPurchased = 0;
  int _minutesWorked = 0;
  final Random _random = Random();

  // Getters
  double get mentalStability => _mentalStability;
  double get existentialDread => _existentialDread;
  double get productivity => _productivity;
  double get microtransactionPressure => _microtransactionPressure;
  bool get isInMeeting => _isInMeeting;
  bool get isInTherapy => _isInTherapy;
  bool get isGlitching => _isGlitching;
  int get tearsDropped => _tearsDropped;
  int get meetingsAttended => _meetingsAttended;
  int get therapySessions => _therapySessions;
  int get microtransactionsPurchased => _microtransactionsPurchased;
  int get minutesWorked => _minutesWorked;

  // Game events
  void startMeeting() {
    _isInMeeting = true;
    _meetingsAttended++;
    updateMentalState(-0.2, 0.1);
    notifyListeners();
  }

  void endMeeting() {
    _isInMeeting = false;
    notifyListeners();
  }

  void startTherapy() {
    _isInTherapy = true;
    _therapySessions++;
    updateMentalState(0.3, -0.2);
    notifyListeners();
  }

  void endTherapy() {
    _isInTherapy = false;
    notifyListeners();
  }

  void purchaseMicrotransaction() {
    _microtransactionsPurchased++;
    _microtransactionPressure += 0.1;
    updateMentalState(-0.1, 0.15);
    notifyListeners();
  }

  void dropTear() {
    _tearsDropped++;
    updateMentalState(-0.05, 0.05);
    notifyListeners();
  }

  void work() {
    _productivity = (_productivity + 0.1).clamp(0.0, 1.0);
    _minutesWorked++;
    updateMentalState(-0.1, 0.1);
    notifyListeners();
  }

  void takeBreak() {
    _productivity = (_productivity - 0.1).clamp(0.0, 1.0);
    updateMentalState(0.2, -0.1);
    notifyListeners();
  }

  void updateMentalState(double stabilityChange, double dreadChange) {
    _mentalStability = (_mentalStability + stabilityChange).clamp(0.0, 1.0);
    _existentialDread = (_existentialDread + dreadChange).clamp(0.0, 1.0);

    // Random chance to trigger glitch effect
    if (_mentalStability < 0.5 && !_isGlitching) {
      _isGlitching = true;
      Future.delayed(const Duration(seconds: 2), () {
        _isGlitching = false;
        notifyListeners();
      });
    }

    // Random chance to drop a tear
    if (_mentalStability < 0.7 && _random.nextDouble() < 0.3) {
      dropTear();
    }
  }

  void reset() {
    _mentalStability = 1.0;
    _existentialDread = 0.0;
    _productivity = 1.0;
    _microtransactionPressure = 0.0;
    _isInMeeting = false;
    _isInTherapy = false;
    _isGlitching = false;
    _tearsDropped = 0;
    _meetingsAttended = 0;
    _therapySessions = 0;
    _microtransactionsPurchased = 0;
    _minutesWorked = 0;
    notifyListeners();
  }
}
