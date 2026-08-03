import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri/hijri_calendar.dart';

class SyncService {
  static Future<bool> syncHijriDate() async {
    try {
      final now = DateTime.now();
      final String dateStr = "${now.day}-${now.month}-${now.year}";

      final url = Uri.parse("https://api.aladhan.com/v1/gToH/$dateStr");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        HijriCalendar.setLocal('ar');
        final localHijri = HijriCalendar.fromDate(now);

        final String? dayStr = data['data']?['hijri']?['day']?.toString();
        final int apiDay =
            (dayStr != null ? int.tryParse(dayStr) : null) ?? localHijri.hDay;

        int offset = 0;
        if (apiDay != localHijri.hDay) {
          offset = apiDay - localHijri.hDay;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('hijri_offset', offset);

        debugPrint("Hijri sync complete: offset=$offset");
        return true;
      }
    } catch (e) {
      debugPrint("Hijri sync failed: $e");
    }
    return false;
  }
}
