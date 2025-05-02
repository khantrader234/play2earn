import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('Failed to initialize Mobile Ads SDK: $e');
      // Retry initialization after delay
      Future.delayed(retryDelay, initialize);
    }
  }

  // Load a new rewarded ad
  Future<void> _loadRewardedAd() async {
    if (_retryCount >= maxRetries) {
      debugPrint('Max retry attempts reached for ad loading');
      _retryCount = 0;
      return;
    }

    try {
      await RewardedAd.load(
        adUnitId:
            'ca-app-pub-7518687507556599/6624231013', // Production ad unit ID
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isAdLoaded = true;
            _retryCount = 0;
            _setupAdListeners(ad);
            debugPrint('Ad loaded successfully');
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isAdLoaded = false;
            _retryCount++;
            debugPrint('Ad failed to load: ${error.message}');
            debugPrint('Retry count: $_retryCount');
            // Retry loading after delay
            Future.delayed(retryDelay, _loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading ad: $e');
      _retryCount++;
      Future.delayed(retryDelay, _loadRewardedAd);
    }
  }

  void _setupAdListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        _analytics.logEvent(
          name: 'ad_shown',
          parameters: {'ad_type': 'rewarded'},
        );
        debugPrint('Ad showed fullscreen content');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _loadRewardedAd(); // Load the next ad
        debugPrint('Ad dismissed fullscreen content');
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _loadRewardedAd(); // Load the next ad
        debugPrint('Ad failed to show: ${error.message}');
      },
      onAdImpression: (RewardedAd ad) {
        debugPrint('Ad impression recorded');
      },
    );
  }

  // Show a rewarded ad
  Future<bool> showRewardedAd() async {
    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint('Ad not loaded, attempting to load');
      await _loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();

    try {
      _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          _analytics.logEvent(
            name: 'ad_reward_earned',
            parameters: {
              'ad_type': 'rewarded',
              'reward_amount': reward.amount,
              'reward_type': reward.type,
            },
          );
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          completer.complete(true);
        },
      );
    } catch (e) {
      debugPrint('Error showing ad: $e');
      completer.complete(false);
    }

    return completer.future;
  }

  // Get ad status
  bool get isAdLoaded => _isAdLoaded;

  // Dispose of the current ad
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}
