import 'package:flutter/services.dart';

/// Sound + vibration feedback on a successful scan.
/// Uses the platform's built-in click sound / haptics, so no audio assets
/// or extra packages are needed.
class FeedbackService {
  FeedbackService._();

  static Future<void> scanFeedback({
    required bool sound,
    required bool vibrate,
  }) async {
    if (vibrate) await HapticFeedback.vibrate();
    if (sound) await SystemSound.play(SystemSoundType.click);
  }
}
