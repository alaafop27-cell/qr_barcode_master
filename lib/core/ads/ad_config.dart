/// ---------------------------------------------------------------------------
/// AdMob configuration  (the ONLY file you need to touch to enable ads)
/// ---------------------------------------------------------------------------
///
/// Ads are DISABLED while these values are empty: no SDK initialisation, no
/// requests, no test ads, and nothing is shown in the UI.
///
/// Two ways to plug in your real IDs after you create your AdMob account:
///
///  A) Without editing code (recommended for the GitHub build):
///     In your GitHub repo go to  Settings > Secrets and variables > Actions >
///     Variables  and create:
///         ADMOB_APP_ID           e.g. ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
///         ADMOB_BANNER_ID        e.g. ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
///         ADMOB_INTERSTITIAL_ID  e.g. ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW
///     The workflow passes them to the app and to AndroidManifest.xml.
///
///  B) Hard-code them: paste the values into the `defaultValue:` strings below
///     AND put the App ID in android/app/src/main/AndroidManifest.xml as
///     <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" .../>
///     (the CI patch script does that for you when ADMOB_APP_ID is set).
class AdConfig {
  AdConfig._();

  /// AdMob *application* ID (contains a "~"). Must match the manifest value.
  static const String appId =
      String.fromEnvironment('ADMOB_APP_ID', defaultValue: '');

  /// Banner ad unit ID (contains a "/").
  static const String bannerUnitId =
      String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: '');

  /// Interstitial ad unit ID (contains a "/").
  static const String interstitialUnitId =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: '');

  /// Show an interstitial after every N completed "actions"
  /// (a scan result viewed, or a QR code generated).
  static const int interstitialEveryNActions = 4;

  static bool get bannerEnabled => appId.isNotEmpty && bannerUnitId.isNotEmpty;

  static bool get interstitialEnabled =>
      appId.isNotEmpty && interstitialUnitId.isNotEmpty;

  static bool get anyEnabled => bannerEnabled || interstitialEnabled;
}
