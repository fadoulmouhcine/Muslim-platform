import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';

class WidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.example.muslim/widget');

  /// Saves the prayer times to shared cache for the native home/lock widgets
  /// and triggers a background native widget reload.
  static Future<void> updateWidgetData({
    required PrayerTimes prayerTimes,
    required String city,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Formulate lightweight JSON for widgets
      final Map<String, String> widgetData = {
        'city': city,
        'fajr': prayerTimes.fajr.toIso8601String(),
        'sunrise': prayerTimes.sunrise.toIso8601String(),
        'dhuhr': prayerTimes.dhuhr.toIso8601String(),
        'asr': prayerTimes.asr.toIso8601String(),
        'maghrib': prayerTimes.maghrib.toIso8601String(),
        'isha': prayerTimes.isha.toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Write to SharedPreferences
      await prefs.setString('widget_prayer_data', jsonEncode(widgetData));

      // Invoke MethodChannel to trigger native widget update
      await _channel.invokeMethod('reloadWidget');
    } catch (e) {
      // Fail silently to prevent app crashes, ensuring light background operations
      debugPrint('Widget update failed: $e');
    }
  }
}
