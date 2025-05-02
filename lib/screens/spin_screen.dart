import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:math' as math;

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> with TickerProviderStateMixin {
  late final StreamController<int> selected;
  bool isSpinning = false;
  int? currentValue;
  int remainingFreeSpins = 3;
  int adSpinsUsed = 0;
  DateTime? lastSpinTime;
  bool isAdLoaded = false;
  RewardedAd? rewardedAd;
  static const maxDailyAdSpins = 10;
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Animation controllers
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;
  late AnimationController _wheelShineController;
  late Animation<double> _wheelShineAnimation;
  late AnimationController _spinCountController;
  late Animation<double> _spinCountAnimation;

  final List<FortuneItem> items = [
    const FortuneItem(
      child: Text(
        '50\nCoins',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      style: FortuneItemStyle(
        color: Colors.blue,
        borderColor: Colors.white,
        borderWidth: 3,
      ),
    ),
    const FortuneItem(
      child: Text(
        '100\nCoins',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      style: FortuneItemStyle(
        color: Colors.green,
        borderColor: Colors.white,
        borderWidth: 3,
      ),
    ),
    const FortuneItem(
      child: Text(
        '150\nCoins',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      style: FortuneItemStyle(
        color: Colors.orange,
        borderColor: Colors.white,
        borderWidth: 3,
      ),
    ),
    const FortuneItem(
      child: Text(
        '200\nCoins',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      style: FortuneItemStyle(
        color: Colors.purple,
        borderColor: Colors.white,
        borderWidth: 3,
      ),
    ),
    const FortuneItem(
      child: Text(
        '300\nCoins',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      style: FortuneItemStyle(
        color: Colors.red,
        borderColor: Colors.white,
        borderWidth: 3,
      ),
    ),
  ];

  final List<int> rewards = [50, 100, 150, 200, 300];

  @override
  void initState() {
    super.initState();
    selected = StreamController<int>.broadcast();

    // Initialize Mobile Ads SDK
    MobileAds.instance.initialize().then((_) {
      _loadRewardedAd();
    });

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    // Wheel shine animation
    _wheelShineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _wheelShineAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _wheelShineController,
      curve: Curves.linear,
    ));
    _wheelShineController.repeat();

    // Spin count animation
    _spinCountController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _spinCountAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _spinCountController,
      curve: Curves.easeInOut,
    ));

    _loadSpinData();
  }

  void _loadRewardedAd() {
    if (_retryCount >= maxRetries) {
      debugPrint('Max retry attempts reached for ad loading');
      _retryCount = 0;
      return;
    }

    setState(() {
      isAdLoaded = false;
    });

    RewardedAd.load(
      adUnitId:
          'ca-app-pub-7518687507556599/6624231013', // Production ad unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded successfully');
          setState(() {
            rewardedAd = ad;
            isAdLoaded = true;
            _retryCount = 0;
          });

          // Set full screen callback
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Ad showed fullscreen content.');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed fullscreen content.');
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Ad failed to show fullscreen content: $error');
              ad.dispose();
              _loadRewardedAd();
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
          setState(() {
            isAdLoaded = false;
            _retryCount++;
          });
          // Retry loading after a delay
          Future.delayed(retryDelay, _loadRewardedAd);
        },
      ),
    );
  }

  Future<void> _loadSpinData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final lastSpinDate = data['lastSpinDate'] as Timestamp?;
    final spinsLeft = data['remainingFreeSpins'] as int? ?? 3;
    final adsWatched = data['adSpinsUsed'] as int? ?? 0;

    if (lastSpinDate != null) {
      final now = DateTime.now();
      final lastDate = lastSpinDate.toDate();
      if (now.day != lastDate.day ||
          now.month != lastDate.month ||
          now.year != lastDate.year) {
        // Reset for new day
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'remainingFreeSpins': 3,
          'adSpinsUsed': 0,
          'lastSpinDate': FieldValue.serverTimestamp(),
        });
        setState(() {
          remainingFreeSpins = 3;
          adSpinsUsed = 0;
        });
      } else {
        setState(() {
          remainingFreeSpins = spinsLeft;
          adSpinsUsed = adsWatched;
        });
      }
    }
  }

  Future<void> _watchAdForSpin() async {
    if (!isAdLoaded || rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Ad not ready. Please try again.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadRewardedAd();
      return;
    }

    if (adSpinsUsed >= maxDailyAdSpins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Maximum extra spins reached for today!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    rewardedAd!.show(
      onUserEarnedReward: (_, reward) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        setState(() {
          remainingFreeSpins++;
          adSpinsUsed++;
        });

        // Animate spin count
        _spinCountController
            .forward()
            .then((_) => _spinCountController.reverse());

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'remainingFreeSpins': remainingFreeSpins,
          'adSpinsUsed': adSpinsUsed,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.stars, color: Color(0xFFFFD700)),
                SizedBox(width: 8),
                Text('You earned an extra spin!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        _loadRewardedAd();
      },
    );

    rewardedAd = null;
    setState(() {
      isAdLoaded = false;
    });
  }

  Future<void> _spinWheel() async {
    if (isSpinning || remainingFreeSpins <= 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Animate button press
    await _buttonController.forward();
    await _buttonController.reverse();

    setState(() {
      isSpinning = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    final selectedValue = Fortune.randomInt(0, items.length);
    currentValue = selectedValue;
    selected.add(selectedValue);

    // Record spin and update remaining spins
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'remainingFreeSpins': remainingFreeSpins - 1,
      'lastSpinDate': FieldValue.serverTimestamp(),
    });

    setState(() {
      remainingFreeSpins--;
    });

    // Wait for wheel animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Update wallet with reward
    await _updateWallet(rewards[selectedValue]);

    setState(() {
      isSpinning = false;
    });

    // Show reward dialog with confetti animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildRewardDialog(selectedValue),
    );
  }

  Widget _buildRewardDialog(int selectedValue) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242B3D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        '🎉 Congratulations!',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${rewards[selectedValue]}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 2,
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'COINS WON',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            remainingFreeSpins > 0
                ? '$remainingFreeSpins free spins remaining'
                : 'Watch an ad to get more spins!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            HapticFeedback.lightImpact();
          },
          child: const Text(
            'CLAIM',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateWallet(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'balance': FieldValue.increment(amount),
        'totalEarned': FieldValue.increment(amount),
      });

      // Record transaction
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'amount': amount,
        'type': 'spin_reward',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating wallet: $e');
    }
  }

  @override
  void dispose() {
    selected.close();
    _buttonController.dispose();
    _wheelShineController.dispose();
    _spinCountController.dispose();
    rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F2C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Spins remaining indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF242B3D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _spinCountAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _spinCountAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFFFFD700),
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FREE SPINS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '$remainingFreeSpins',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'AD SPINS LEFT',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${maxDailyAdSpins - adSpinsUsed}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Fortune wheel
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shine effect
                  AnimatedBuilder(
                    animation: _wheelShineAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _wheelShineAnimation.value,
                        child: Container(
                          width: 340,
                          height: 340,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFFFD700).withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Wheel
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: FortuneWheel(
                      selected: selected.stream,
                      items: items,
                      animateFirst: false,
                      onAnimationEnd: () {
                        HapticFeedback.heavyImpact();
                      },
                      physics: CircularPanPhysics(
                        duration: const Duration(seconds: 3),
                        curve: Curves.decelerate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Spin buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Free spin button
                  AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _buttonAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: remainingFreeSpins > 0 && !isSpinning
                              ? _spinWheel
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSpinning)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                ),
                              if (isSpinning) const SizedBox(width: 12),
                              Text(
                                isSpinning
                                    ? 'Spinning...'
                                    : remainingFreeSpins > 0
                                        ? 'SPIN NOW'
                                        : 'NO FREE SPINS LEFT',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Watch ad button
                  if (remainingFreeSpins <= 0 && adSpinsUsed < maxDailyAdSpins)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed:
                            isAdLoaded && !isSpinning ? _watchAdForSpin : null,
                        icon: isAdLoaded
                            ? const Icon(Icons.play_circle_outline)
                            : const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFFD700)),
                                ),
                              ),
                        label: Text(
                          isAdLoaded ? 'WATCH AD FOR SPIN' : 'LOADING AD...',
                          style: const TextStyle(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF242B3D),
                          foregroundColor: const Color(0xFFFFD700),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
