import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_service.dart';
import '../../core/services/transaction_service.dart';
import '../../core/models/transaction_model.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  final List<int> dailyRewards = [50, 75, 100, 150, 175, 200, 250];
  int currentDay = 1;
  bool canClaim = true;

  @override
  void initState() {
    super.initState();
    _loadDailyBonusData();
  }

  Future<void> _loadDailyBonusData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastClaimDate = data['lastDailyBonusDate']?.toDate();
        final streakDay = data['dailyBonusStreak'] ?? 0;

        if (lastClaimDate != null) {
          final now = DateTime.now();
          final difference = now.difference(lastClaimDate).inDays;

          setState(() {
            if (difference > 1) {
              // Streak broken
              currentDay = 1;
              canClaim = true;
            } else if (difference == 1) {
              // Next day, can claim
              currentDay = (streakDay % 7) + 1;
              canClaim = true;
            } else if (difference == 0) {
              // Same day, cannot claim
              currentDay = streakDay;
              canClaim = false;
            }
          });
        }
      }
    }
  }

  Future<void> _claimBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reward = dailyRewards[currentDay - 1];
    final transactionService = TransactionService();

    try {
      // Update user data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'coins': FieldValue.increment(reward),
        'lastDailyBonusDate': FieldValue.serverTimestamp(),
        'dailyBonusStreak': currentDay,
      });

      // Record transaction
      await transactionService.recordTransaction(
        userId: user.uid,
        amount: reward,
        type: TransactionType.earned,
        source: 'Daily Bonus',
        description: 'Day $currentDay Bonus: $reward coins',
      );

      setState(() {
        canClaim = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claimed $reward coins!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming bonus: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.15, // 15% from the top
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Bonus',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Day $currentDay',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isActive = day == currentDay;
                    final isPast = day < currentDay;

                    return Container(
                      width: 45,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.blue
                            : isPast
                                ? Colors.grey.shade800
                                : Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Day ${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dailyRewards[index]}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canClaim ? _claimBonus : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.card_giftcard),
                    label: Text(
                      canClaim
                          ? 'Claim ${dailyRewards[currentDay - 1]} Coins'
                          : 'Come back tomorrow!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
