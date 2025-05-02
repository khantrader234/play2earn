import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/user_service.dart';
import '../../core/services/transaction_service.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/user_model.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  bool _isLoading = false;
  final TransactionService _transactionService = TransactionService();
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
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    setState(() {
      _isAdLoaded = false;
    });

    RewardedAd.load(
      adUnitId: 'ca-app-pub-7518687507556599/6624231013',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded successfully');
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
            _isAdLoaded = false;
          });
          // Retry loading after a delay
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Ads'),
        backgroundColor: Colors.black87,
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

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.ondemand_video,
                        size: 80,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Watch ads to earn coins!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Earn 10 coins per ad watched',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      if (userData.lastWatchTime != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Last watched: ${userData.lastWatchTime!.toString()}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _watchAd(context, userData),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.amber,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.play_circle_filled),
                        label: Text(
                          _isLoading ? 'Loading...' : 'Watch Ad',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _watchAd(BuildContext context, UserModel userData) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check cooldown
      if (userData.lastWatchTime != null) {
        final difference = DateTime.now().difference(userData.lastWatchTime!);
        if (difference.inHours < 1) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait ${60 - difference.inMinutes} minutes before watching another ad',
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      if (!_isAdLoaded || _rewardedAd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ad is not ready yet. Please try again.')),
        );
        _loadRewardedAd();
        setState(() => _isLoading = false);
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
            const SnackBar(
                content: Text('Failed to show ad. Please try again.')),
          );
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (_ad, _reward) async {
          // Update user data
          final userDoc =
              FirebaseFirestore.instance.collection('users').doc(user.uid);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(userDoc);
            final currentUser = UserModel.fromFirestore(snapshot);

            transaction.update(userDoc, {
              'coins': currentUser.coins + 10,
              'totalEarned': currentUser.totalEarned + 10,
              'lastWatchTime': FieldValue.serverTimestamp(),
            });
          });

          // Record transaction
          await _transactionService.recordTransaction(
            userId: user.uid,
            amount: 10,
            type: TransactionType.earned,
            source: 'Watch Ad',
            description: 'Reward for watching an advertisement',
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You earned 10 coins!')),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
}
