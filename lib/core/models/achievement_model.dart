import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class AchievementModel {
  final String id;
  final String name;
  final String description;
  final int requiredValue;
  final String type;
  final int rewardCoins;
  final DateTime? unlockedAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredValue,
    required this.type,
    required this.rewardCoins,
    this.unlockedAt,
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AchievementModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      requiredValue: data['requiredValue'] ?? 0,
      type: data['type'] ?? '',
      rewardCoins: data['rewardCoins'] ?? 0,
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'requiredValue': requiredValue,
      'type': type,
      'rewardCoins': rewardCoins,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }

  bool isUnlocked(UserModel user) {
    switch (type) {
      case 'games_played':
        return user.gamesPlayed >= requiredValue;
      case 'high_score':
        return user.highScore >= requiredValue;
      case 'total_coins':
        return user.totalEarned >= requiredValue;
      case 'login_streak':
        return user.loginStreak >= requiredValue;
      default:
        return false;
    }
  }
}
