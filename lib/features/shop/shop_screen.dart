import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/user_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final coins = userData?['coins'] ?? 0;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      coins.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final coins = userData?['coins'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPowerUpCard(
                context,
                'Double Points',
                'Double your points for 1 game',
                Icons.star,
                Colors.amber,
                100,
                coins,
                () => _purchasePowerUp(context, 'doublePoints', 100),
              ),
              const SizedBox(height: 16),
              _buildPowerUpCard(
                context,
                'Extra Life',
                'Get an extra life in the game',
                Icons.favorite,
                Colors.red,
                50,
                coins,
                () => _purchasePowerUp(context, 'extraLife', 50),
              ),
              const SizedBox(height: 16),
              _buildPowerUpCard(
                context,
                'Shield',
                'Protect yourself from one obstacle',
                Icons.shield,
                Colors.blue,
                75,
                coins,
                () => _purchasePowerUp(context, 'shield', 75),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPowerUpCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    int cost,
    int userCoins,
    VoidCallback onPurchase,
  ) {
    final canAfford = userCoins >= cost;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      cost.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: canAfford ? onPurchase : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(canAfford ? 'Purchase' : 'Not enough coins'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchasePowerUp(
    BuildContext context,
    String powerUpType,
    int cost,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.purchasePowerUp(currentUser.uid, powerUpType, cost);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Power-up purchased successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
