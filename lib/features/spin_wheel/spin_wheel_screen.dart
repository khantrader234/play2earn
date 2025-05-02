import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/user_service.dart';
import '../../core/services/transaction_service.dart';
import '../../core/models/transaction_model.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with TickerProviderStateMixin {
  bool isSpinning = false;
  final List<int> rewards = [10, 20, 30, 50, 100];
  DateTime? lastSpinTime;
  DateTime? lastDayReset;
  int spinsRemaining = 3;
  int adSpinsUsed = 0;
  static const maxDailyAdSpins = 10;
  static const maxFreeSpins = 3;
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _iconController;
  late Animation<double> _iconRotationAnimation;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Request test ads on devices you're using to debug your app.
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
          testDeviceIds: ['PR5HWSM7S8KJLNGY']), // Your actual device ID
    );
    _loadSpinData();
    _loadRewardedAd();

    // Button press animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Icon rotation animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _loadRewardedAd() {
    if (!mounted) return;
    setState(() {
      _isAdLoaded = false;
    });

    RewardedAd.load(
      adUnitId: 'ca-app-pub-7518687507556599/6624231013',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded successfully');
          if (!mounted) return;
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });

          // Set full screen callback
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Ad showed fullscreen content.');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed fullscreen content.');
              ad.dispose();
              if (mounted) _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Ad failed to show fullscreen content: $error');
              ad.dispose();
              if (mounted) _loadRewardedAd();
            },
            onAdImpression: (ad) {
              debugPrint('Ad impression recorded.');
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Ad failed to load: ${error.message}');
          debugPrint('Error code: ${error.code}');
          debugPrint('Error domain: ${error.domain}');
          if (!mounted) return;
          setState(() {
            _isAdLoaded = false;
          });
          // Retry loading after a delay
          Future.delayed(const Duration(minutes: 1), () {
            if (mounted) _loadRewardedAd();
          });
        },
      ),
    );
  }

  Future<void> _loadSpinData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await Provider.of<UserService>(context, listen: false)
          .getUserStream(user.uid)
          .first;
      if (userData != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          lastSpinTime = userData.lastSpinTime;
          lastDayReset = userData.lastDayReset;

          // Reset spins if it's a new day
          if (lastDayReset == null ||
              DateTime(lastDayReset!.year, lastDayReset!.month,
                      lastDayReset!.day) !=
                  today) {
            spinsRemaining = maxFreeSpins;
            adSpinsUsed = 0;
          } else {
            spinsRemaining = userData.spinsRemaining;
            adSpinsUsed = userData.adSpinsUsed;
          }
        });
      }
    }
  }

  Future<bool> _canSpin() async {
    if (spinsRemaining <= 0 && adSpinsUsed >= maxDailyAdSpins) {
      return false;
    }
    if (lastSpinTime != null) {
      final timeSinceLastSpin = DateTime.now().difference(lastSpinTime!);
      if (timeSinceLastSpin.inSeconds < 5) {
        // Prevent rapid spinning
        return false;
      }
    }
    return true;
  }

  Future<void> _watchAdForSpin() async {
    if (adSpinsUsed >= maxDailyAdSpins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You\'ve reached the maximum extra spins for today')),
      );
      return;
    }

    if (!_isAdLoaded || _rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad is not ready yet. Please try again.')),
      );
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to show ad. Please try again.')),
        );
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        setState(() {
          spinsRemaining++;
          adSpinsUsed++;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'adSpinsUsed': adSpinsUsed,
            'spinsRemaining': spinsRemaining,
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You earned an extra spin!')),
        );
      },
    );
  }

  Future<void> _onSpinComplete(int reward) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userService = Provider.of<UserService>(context, listen: false);
    final transactionService = TransactionService();

    // Record the transaction
    await transactionService.recordTransaction(
      userId: user.uid,
      amount: reward,
      type: TransactionType.earned,
      source: 'Spin Wheel',
      description: 'Won $reward coins from Spin Wheel!',
    );

    // Update user's coins and spin data
    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'coins': FieldValue.increment(reward),
      'lastSpinTime': now,
      'spinsRemaining': spinsRemaining - 1,
      'lastDayReset': now,
      'adSpinsUsed': adSpinsUsed,
    });

    // Show reward dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations! 🎉'),
        content: Text('You won $reward coins!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    setState(() {
      isSpinning = false;
      lastSpinTime = now;
      spinsRemaining--;
    });
  }

  String _getSpinStatus() {
    if (spinsRemaining > 0) {
      return '$spinsRemaining free spins remaining';
    }
    if (adSpinsUsed < maxDailyAdSpins) {
      return 'Watch an ad to earn more spins! (${maxDailyAdSpins - adSpinsUsed} remaining)';
    }
    return 'Come back tomorrow for more spins!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin & Win'),
        backgroundColor: Colors.black87,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                _getSpinStatus(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: FortuneWheel(
                        selected: Stream.value(0),
                        animateFirst: false,
                        physics: CircularPanPhysics(
                          duration: const Duration(seconds: 1),
                          curve: Curves.decelerate,
                        ),
                        onFling: () {
                          // Disable direct fling
                          return;
                        },
                        items: rewards.map((reward) {
                          return FortuneItem(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                '$reward\nCoins',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: reward == 100
                                  ? Colors.amber
                                  : reward >= 50
                                      ? Colors.orange
                                      : Colors.purple,
                              borderColor: Colors.white,
                              borderWidth: 3,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    AnimatedBuilder(
                      animation: _buttonScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.amber.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (isSpinning) return;

                                // Start button press animation
                                await _buttonController.forward();
                                await _buttonController.reverse();

                                final canSpin = await _canSpin();
                                if (!canSpin) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(spinsRemaining <= 0
                                          ? 'No spins remaining. Watch an ad for more spins!'
                                          : 'Please wait a moment before spinning again.'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isSpinning = true);

                                // Start icon rotation animation
                                _iconController.repeat();

                                final selected =
                                    Random().nextInt(rewards.length);
                                await Future.delayed(
                                    const Duration(seconds: 3));

                                // Stop icon rotation animation
                                _iconController.stop();

                                await _onSpinComplete(rewards[selected]);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 20),
                                textStyle: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _iconRotationAnimation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _iconRotationAnimation.value,
                                        child:
                                            const Icon(Icons.casino, size: 28),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('SPIN NOW'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (spinsRemaining <= 0 && adSpinsUsed < maxDailyAdSpins)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: ElevatedButton.icon(
                    onPressed: _watchAdForSpin,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Ad for Extra Spin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Daily Limits:\n'
                  '• ${maxFreeSpins} free spins\n'
                  '• Up to ${maxDailyAdSpins} extra spins from ads\n'
                  '• Resets daily at midnight',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
