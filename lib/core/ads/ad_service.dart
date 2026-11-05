/// Ads are temporarily disabled (placeholder).
/// The rest of the app already calls these methods, so when AdMob is added
/// later this file is simply replaced by the real implementation.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool get bannerEnabled => false;
  bool get interstitialEnabled => false;

  Future<void> initialize() async {}

  void registerActionAndMaybeShow() {}
}
