import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_service.dart';
import 'method_channel_constants.dart'; // ✅ Task 3.5: Centralized channel names
import '../constants/app_strings.dart';


class SilentModeService {
  static const MethodChannel _channel =
      MethodChannel(MethodChannelNames.silentMode);

  static Future<bool> hasDndPermission() async {
    try {
      final bool hasPerm = await _channel.invokeMethod('hasDndPermission');
      return hasPerm;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openDndSettings() async {
    try {
      await _channel.invokeMethod('openDndSettings');
    } catch (e) {
      debugPrint("❌ Error opening DND settings: $e");
    }
  }

  static Future<bool> enableSilentMode() async {
    try {
      final bool success = await _channel.invokeMethod('enableSilentMode');
      return success;
    } catch (e) {
      debugPrint("❌ Error enabling silent mode: $e");
      return false;
    }
  }

  static Future<bool> restoreNormalMode(
      {bool triggerCatchUpNotification = true}) async {
    try {
      final bool success = await _channel.invokeMethod('restoreNormalMode');
      if (success && triggerCatchUpNotification) {
        await _showCatchUpNotification();
      }
      return success;
    } catch (e) {
      debugPrint("❌ Error restoring normal mode: $e");
      return false;
    }
  }

  static Future<bool> isSilentOrDnd() async {
    try {
      final bool result = await _channel.invokeMethod('isSilentOrDnd');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// 🌿 Post-Prayer Catch-Up Notification
  static Future<void> _showCatchUpNotification() async {
    try {
      await NotificationService.showCatchUpNotification(
        title: "🌿 تقبل الله طاعتكم وصالح أعمالكم",
        body:
            "تم إعادة تفعيل الصوت والأنماط الصوتية تلقائياً. يمكنك الآن متابعة تنبيهاتك ورسائلك في كنف الله.",
      );
    } catch (e) {
      debugPrint("❌ Catch-up notification error: $e");
    }
  }

  /// 🌿 DND Permission Rationale Dialog
  static Future<void> showDndPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.do_not_disturb_on_rounded,
                color: Color(0xFFC5A059), size: 24),
            const SizedBox(width: 10),
            Text(
              "إذن الوضع الصامت (DND)",
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "لتفعيل كتم الصوت التلقائي أثناء إقامة الصلاة واستعادته فور انقضائها، يتطلب التطبيق الوصول لإعدادات \"عدم الإزعاج\".",
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(AppStrings.cancel, style: GoogleFonts.cairo(color: Colors.white54)),

          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx, rootNavigator: true).pop();
              await openDndSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A059),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "الانتقال للإعدادات",
              style: GoogleFonts.cairo(
                  color: const Color(0xFF101712), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
