import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final List<Map<String, dynamic>> initialAchievements = [
  {
    'name': 'First Steps',
    'description': 'Play your first game',
    'requiredValue': 1,
    'type': 'games_played',
    'rewardCoins': 50,
  },
  {
    'name': 'Dedicated Player',
    'description': 'Play 10 games',
    'requiredValue': 10,
    'type': 'games_played',
    'rewardCoins': 100,
  },
  {
    'name': 'Gaming Veteran',
    'description': 'Play 50 games',
    'requiredValue': 50,
    'type': 'games_played',
    'rewardCoins': 500,
  },
  {
    'name': 'Score Rookie',
    'description': 'Reach a high score of 100',
    'requiredValue': 100,
    'type': 'high_score',
    'rewardCoins': 100,
  },
  {
    'name': 'Score Master',
    'description': 'Reach a high score of 500',
    'requiredValue': 500,
    'type': 'high_score',
    'rewardCoins': 500,
  },
  {
    'name': 'Score Legend',
    'description': 'Reach a high score of 1000',
    'requiredValue': 1000,
    'type': 'high_score',
    'rewardCoins': 1000,
  },
  {
    'name': 'Coin Collector',
    'description': 'Earn your first 100 coins',
    'requiredValue': 100,
    'type': 'total_coins',
    'rewardCoins': 50,
  },
  {
    'name': 'Treasure Hunter',
    'description': 'Earn 1000 coins in total',
    'requiredValue': 1000,
    'type': 'total_coins',
    'rewardCoins': 200,
  },
  {
    'name': 'Regular Player',
    'description': 'Achieve a 3-day login streak',
    'requiredValue': 3,
    'type': 'login_streak',
    'rewardCoins': 100,
  },
  {
    'name': 'Dedicated Player',
    'description': 'Achieve a 7-day login streak',
    'requiredValue': 7,
    'type': 'login_streak',
    'rewardCoins': 300,
  },
];

Future<void> setupInitialAchievements() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  // Get existing achievements
  final existingAchievements = await firestore.collection('achievements').get();

  if (existingAchievements.docs.isEmpty) {
    for (final achievement in initialAchievements) {
      final docRef = firestore.collection('achievements').doc();
      batch.set(docRef, achievement);
    }

    await batch.commit();
    debugPrint('Initial achievements created successfully');
  } else {
    debugPrint('Achievements already exist, skipping initialization');
  }
}
