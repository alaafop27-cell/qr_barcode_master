import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Central place for everything ad related. The rest of the app only calls:
///   - AdService.instance.initialize()                  (once, in main)
///   - AdService.instance.registerActionAndMaybeShow()  (after user actions)
///   - BannerAdWidget                                   (see banner_ad_widget.dart)
///
/// If [AdConfig] has no IDs, every method here is a harmless no-op.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  int _actionCount = 0;

  bool get bannerEnabled => _initialized && AdConfig.bannerEnabled;
  bool get interstitialEnabled => _initialized && AdConfig.interstitialEnabled;

  Future<void> initialize() async {
    if (!AdConfig.anyEnabled) return; // nothing configured yet -> ads off
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (AdConfig.interstitialEnabled) _loadInterstitial();
    } catch (e) {
      debugPrint('AdService: initialisation failed: $e');
    }
  }

  void _loadInterstitial() {
    if (!interstitialEnabled) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('AdService: interstitial failed: ${error.message}');
          _interstitial = null;
        },
      ),
    );
  }

  /// Call after a natural pause in the flow (e.g. user came back from a result
  /// screen). Shows an interstitial every [AdConfig.interstitialEveryNActions].
  void registerActionAndMaybeShow() {
    if (!interstitialEnabled) return;
    _actionCount++;
    if (_actionCount % AdConfig.interstitialEveryNActions != 0) return;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedForFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}
