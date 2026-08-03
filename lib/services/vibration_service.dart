import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'settings_provider.dart';

enum HapticType { light, medium, heavy, selection }

class VibrationService {
  /// Triggers instant hardware tactile vibration when global haptic setting is enabled.
  /// Uses [HapticFeedback.vibrate] for reliable hardware motor activation that works
  /// independently of media audio volume.
  static void triggerHaptic(SettingsProvider settings,
      {HapticType type = HapticType.light}) {
    if (!settings.isHapticEnabled) return;
    try {
      switch (type) {
        case HapticType.light:
          HapticFeedback.vibrate();
          break;
        case HapticType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      debugPrint("VibrationService error: $e");
    }
  }

  /// Direct trigger without settings provider check (used when provider is passed or in raw callbacks)
  static void forceVibrate() {
    try {
      HapticFeedback.vibrate();
    } catch (e) {
      debugPrint("VibrationService forceVibrate error: $e");
    }
  }
}
