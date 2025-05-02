import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/achievement_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<UserModel?>(
              stream: userService.getUserStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProfileHeader(user, userData),
                    const SizedBox(height: 24),
                    _buildStats(userData),
                    const SizedBox(height: 24),
                    _buildAchievements(userData),
                    const SizedBox(height: 24),
                    _buildMissions(userData),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(User user, UserModel userData) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.photoURL ?? ''),
              backgroundColor: Colors.grey[300],
              child: user.photoURL == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              userData.displayName ?? 'Player',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (userData.email != null)
              Text(
                userData.email!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Member since: ${userData.createdAt.toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (userData.referralCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Referral Code: ${userData.referralCode}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats(UserModel userData) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Games',
              userData.gamesPlayed.toString(),
              Icons.games,
            ),
            const Divider(),
            _buildStatRow(
              'High Score',
              userData.highScore.toString(),
              Icons.emoji_events,
            ),
            const Divider(),
            _buildStatRow(
              'Total Coins',
              userData.coins.toString(),
              Icons.monetization_on,
            ),
            const Divider(),
            _buildStatRow(
              'Login Streak',
              '${userData.loginStreak} days',
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(UserModel userData) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('achievements')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final achievements = snapshot.data!.docs
                    .map((doc) => AchievementModel.fromFirestore(doc))
                    .toList();

                if (achievements.isEmpty) {
                  return const Center(
                    child: Text(
                      'No achievements available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final isUnlocked =
                        userData.achievements[achievement.id] == true;

                    return ListTile(
                      leading: Icon(
                        isUnlocked ? Icons.star : Icons.star_border,
                        color: isUnlocked ? Colors.amber : Colors.grey,
                      ),
                      title: Text(
                        achievement.name,
                        style: TextStyle(
                          fontWeight:
                              isUnlocked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(achievement.description),
                          Text(
                            'Reward: ${achievement.rewardCoins} coins',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: isUnlocked
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissions(UserModel userData) {
    final missions = userData.missions;
    final today = DateTime.now();
    final lastReset = missions['lastReset'] ?? '';
    final isResetNeeded = lastReset != today.toString().split(' ')[0];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Missions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isResetNeeded && missions['claimed'] == true)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMissionItem(
              'Play Games',
              missions['play_games'] ?? 0,
              3,
              Icons.games,
            ),
            const Divider(),
            _buildMissionItem(
              'Collect Coins',
              missions['collect_coins'] ?? 0,
              50,
              Icons.monetization_on,
            ),
            const Divider(),
            _buildMissionItem(
              'Watch Ads',
              missions['spin_wheel'] ?? 0,
              1,
              Icons.ondemand_video,
            ),
            const SizedBox(height: 16),
            if (!isResetNeeded &&
                missions['play_games'] >= 3 &&
                missions['collect_coins'] >= 50 &&
                missions['spin_wheel'] >= 1 &&
                missions['claimed'] != true)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final userService =
                        Provider.of<UserService>(context, listen: false);
                    userService.updateMissionProgress(
                        userData.uid, 'claimed', 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Claim Rewards',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionItem(
      String label, int current, int required, IconData icon) {
    final progress = current / required;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.amber),
          title: Text(label),
          subtitle: Text('$current/$required'),
          trailing: Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: progress >= 1 ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1 ? Colors.green : Colors.amber,
          ),
        ),
      ],
    );
  }
}
