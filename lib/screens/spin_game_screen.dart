import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/spin_game_service.dart';
import '../services/ad_service.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpinGameScreen extends ConsumerStatefulWidget {
  const SpinGameScreen({super.key});

  @override
  ConsumerState<SpinGameScreen> createState() => _SpinGameScreenState();
}

class _SpinGameScreenState extends ConsumerState<SpinGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _remainingFreeSpins = 3;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _loadRemainingSpins();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRemainingSpins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _firebaseService.getUserStats(user.uid);
    final data = userDoc.data() as Map<String, dynamic>;
    final lastSpinDate = data['lastSpinDate'] as Timestamp?;
    final remainingSpins = data['remainingSpins'] as int? ?? 3;

    if (lastSpinDate != null) {
      final now = DateTime.now();
      final lastDate = lastSpinDate.toDate();
      if (now.day != lastDate.day) {
        await _firebaseService.updateUserData(user.uid, {
          'remainingSpins': 3,
          'lastSpinDate': FieldValue.serverTimestamp(),
        });
        setState(() => _remainingFreeSpins = 3);
      } else {
        setState(() => _remainingFreeSpins = remainingSpins);
      }
    } else {
      setState(() => _remainingFreeSpins = 3);
    }
  }

  Future<void> _spinWheel() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_remainingFreeSpins > 0) {
        await _firebaseService.updateUserData(user.uid, {
          'remainingSpins': FieldValue.increment(-1),
          'lastSpinDate': FieldValue.serverTimestamp(),
        });
        setState(() => _remainingFreeSpins--);
      } else {
        final reward = await _adService.showRewardedAd();
        if (!reward) {
          setState(() => _isLoading = false);
          return;
        }
      }

      _controller.reset();
      _controller.forward();

      await Future.delayed(const Duration(seconds: 3));
      final result =
          await ref.read(spinGameStateProvider.notifier).spin(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.isJackpot ? Icons.celebration : Icons.currency_bitcoin,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  result.isJackpot
                      ? '🎉 Jackpot! You won ${result.amount} coins!'
                      : 'You won ${result.amount} coins!',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            backgroundColor: result.isJackpot ? Colors.green : null,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to spin. Please try again.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spinState = ref.watch(spinGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wheel of Fortune'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildHistorySheet(spinState.history),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wheel of Fortune
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value * 10 * 3.14159,
                        child: SvgPicture.asset(
                          'assets/images/wheel.svg',
                          width: 300,
                          height: 300,
                        ),
                      );
                    },
                  ),
                  if (_isLoading)
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              // Remaining spins
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.casino, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Free Spins: $_remainingFreeSpins',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 24),
              // Spin button
              ElevatedButton(
                onPressed: _isLoading ? null : _spinWheel,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  backgroundColor: _remainingFreeSpins > 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.amber,
                  foregroundColor:
                      _remainingFreeSpins > 0 ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  _remainingFreeSpins > 0
                      ? 'SPIN NOW (FREE)'
                      : 'WATCH AD TO SPIN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySheet(List<SpinHistoryItem> history) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spin History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.isJackpot
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isJackpot
                            ? Icons.celebration
                            : Icons.currency_bitcoin,
                        color: item.isJackpot ? Colors.amber : Colors.green,
                      ),
                    ),
                    title: Text(
                      '${item.amount} coins',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
                    ),
                    trailing: item.isJackpot
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🎉 JACKPOT',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
