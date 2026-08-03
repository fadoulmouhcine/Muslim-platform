import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';

class MethodConfig {
  final int aladhanId;
  final String? tune;
  final String? methodSettings;
  final bool isVerified;
  final String notes;

  const MethodConfig(
    this.aladhanId, {
    this.tune,
    this.methodSettings,
    this.isVerified = true,
    required this.notes,
  });
}

class OfficialPrayerTimesService {
  static const String _baseUrl = "https://api.aladhan.com/v1/calendar";

  static const Map<String, MethodConfig> _methods = {
    'morocco': MethodConfig(21,
        tune: "0,0,0,5,0,3,0,0,0",
        notes: "Morocco Ministry of Habous & Islamic Affairs - Aladhan ID 21"),
    'karachi': MethodConfig(1,
        notes: "University of Islamic Sciences, Karachi - Aladhan ID 1"),
    'isna': MethodConfig(2,
        notes: "Islamic Society of North America (ISNA) - Aladhan ID 2"),
    'mwl': MethodConfig(3, notes: "Muslim World League (MWL) - Aladhan ID 3"),
    'egypt': MethodConfig(5,
        notes: "Egyptian General Authority of Survey - Aladhan ID 5"),
    'umm_al_qura':
        MethodConfig(4, notes: "Umm Al-Qura University, Makkah - Aladhan ID 4"),
    'france': MethodConfig(12,
        notes: "Union Organization Islamic de France (UOIF) - Aladhan ID 12"),
    'algeria': MethodConfig(19,
        notes: "Algeria Ministry of Religious Affairs - Aladhan ID 19"),
    'tunisia': MethodConfig(18,
        notes: "Tunisia Ministry of Religious Affairs - Aladhan ID 18"),
    'kuwait': MethodConfig(9, notes: "Kuwait Ministry of Awqaf - Aladhan ID 9"),
    'paris_mosque': MethodConfig(12,
        isVerified: true,
        notes:
            "Grand Mosque of Paris - Aligned with France UOIF 12° / Aladhan ID 12"),
    'uae': MethodConfig(16,
        isVerified: true, notes: "UAE GAIAE / Dubai Awqaf - Aladhan ID 16"),
    'palestine': MethodConfig(23,
        isVerified: true,
        notes:
            "Palestine Ministry of Awqaf - Aligned with Jerusalem / Jordan Aladhan ID 23"),
    'turkey': MethodConfig(13,
        notes: "Turkey Diyanet İşleri Başkanlığı - Aladhan ID 13"),
    'belgium': MethodConfig(99,
        methodSettings: "18,null,18",
        isVerified: false,
        notes: "Executive of Muslims of Belgium - Custom 18°/18° Method 99"),
    'igmg_germany': MethodConfig(99,
        methodSettings: "18,null,18",
        isVerified: false,
        notes: "Germany Milli Görüş (IGMG) - Custom 18°/18° Method 99"),
  };

  static MethodConfig getMethodConfig(String methodKey) {
    return _methods[methodKey] ?? _methods['morocco']!;
  }

  /// Clear cached prayer times
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith("official_prayers_")) {
          await prefs.remove(k);
        }
      }
      debugPrint("🧹 Cleared all official_prayers_ cached entries.");
    } catch (e) {
      debugPrint("Error clearing prayer cache: $e");
    }
  }

  /// Get cache key for a specific month and location
  static String _getCacheKey(
      int year, int month, double lat, double lng, String methodKey) {
    final latGrid = (lat * 10000).round() / 10000;
    final lngGrid = (lng * 10000).round() / 10000;
    return "official_prayers_${year}_${month}_${latGrid}_${lngGrid}_$methodKey";
  }

  /// Fetch monthly calendar from Aladhan API and save to SharedPreferences
  static Future<bool> fetchAndCacheMonth({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    required String methodKey,
  }) async {
    final config = getMethodConfig(methodKey);
    String urlStr =
        "$_baseUrl/$year/$month?latitude=$latitude&longitude=$longitude&method=${config.aladhanId}";
    if (config.tune != null) {
      urlStr += "&tune=${config.tune}";
    }
    if (config.methodSettings != null) {
      urlStr += "&methodSettings=${config.methodSettings}";
    }
    final url = Uri.parse(urlStr);

    try {
      debugPrint("📡 Fetching official prayer times from API: $url");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final cacheKey =
              _getCacheKey(year, month, latitude, longitude, methodKey);
          await prefs.setString(cacheKey, response.body);
          debugPrint(
              "✅ Cached official prayer times for $year-$month under key: $cacheKey");
          return true;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch prayer times from API: $e");
    }
    return false;
  }

  /// Retrieve prayer times for a specific day from local cache or API
  static Future<PrayerTimes?> getOfficialPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String methodKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        _getCacheKey(date.year, date.month, latitude, longitude, methodKey);

    String? cachedJson = prefs.getString(cacheKey);

    // 1. If not in cache, try fetching online
    if (cachedJson == null) {
      bool success = await fetchAndCacheMonth(
        year: date.year,
        month: date.month,
        latitude: latitude,
        longitude: longitude,
        methodKey: methodKey,
      );
      if (success) {
        cachedJson = prefs.getString(cacheKey);
      }
    }

    // 2. If we have cached JSON data, parse today's times
    if (cachedJson != null) {
      try {
        final data = json.decode(cachedJson);
        final List<dynamic> daysList = data['data'] ?? [];

        for (final dayData in daysList) {
          final dateInfo = dayData['date'];
          final gregorian = dateInfo['gregorian'];
          int d = int.parse(gregorian['day'].toString());

          if (d == date.day) {
            final timings = dayData['timings'];
            return _parseTimingsToPrayerTimes(
                date, latitude, longitude, timings);
          }
        }
      } catch (e) {
        debugPrint("❌ Error parsing cached official prayer times: $e");
      }
    }

    // Return null to trigger mathematical fallback
    return null;
  }

  /// Helper to convert API timing strings ("05:12 (WEST)") to `PrayerTimes` object
  static PrayerTimes? _parseTimingsToPrayerTimes(
    DateTime date,
    double latitude,
    double longitude,
    Map<String, dynamic> timings,
  ) {
    DateTime? parseTime(String timeStr) {
      try {
        final clean = timeStr.split(" ").first.trim();
        final parts = clean.split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      } catch (e) {
        return null;
      }
    }

    final fajr = parseTime(timings['Fajr'] ?? "");
    final sunrise = parseTime(timings['Sunrise'] ?? "");
    final dhuhr = parseTime(timings['Dhuhr'] ?? "");
    final asr = parseTime(timings['Asr'] ?? "");
    final maghrib = parseTime(timings['Maghrib'] ?? "");
    final isha = parseTime(timings['Isha'] ?? "");

    if (fajr == null ||
        dhuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }

    final coords = Coordinates(latitude, longitude);
    final dateComp = DateComponents(date.year, date.month, date.day);
    final params = CalculationMethod.other.getParameters();

    return _CustomPrayerTimes(
      coords: coords,
      dateComp: dateComp,
      params: params,
      fajrTime: fajr,
      sunriseTime: sunrise ?? fajr.add(const Duration(hours: 1, minutes: 20)),
      dhuhrTime: dhuhr,
      asrTime: asr,
      maghribTime: maghrib,
      ishaTime: isha,
    );
  }
}

/// Custom extension of `PrayerTimes` overriding time getters with API values
class _CustomPrayerTimes implements PrayerTimes {
  final PrayerTimes _base;
  final DateTime _fajr;
  final DateTime _sunrise;
  final DateTime _dhuhr;
  final DateTime _asr;
  final DateTime _maghrib;
  final DateTime _isha;

  _CustomPrayerTimes({
    required Coordinates coords,
    required DateComponents dateComp,
    required CalculationParameters params,
    required DateTime fajrTime,
    required DateTime sunriseTime,
    required DateTime dhuhrTime,
    required DateTime asrTime,
    required DateTime maghribTime,
    required DateTime ishaTime,
  })  : _fajr = fajrTime,
        _sunrise = sunriseTime,
        _dhuhr = dhuhrTime,
        _asr = asrTime,
        _maghrib = maghribTime,
        _isha = ishaTime,
        _base = PrayerTimes(coords, dateComp, params);

  @override
  Coordinates get coordinates => _base.coordinates;

  @override
  DateComponents get dateComponents => _base.dateComponents;

  @override
  CalculationParameters get calculationParameters =>
      _base.calculationParameters;

  @override
  DateTime get fajr => _fajr;

  @override
  DateTime get sunrise => _sunrise;

  @override
  DateTime get dhuhr => _dhuhr;

  @override
  DateTime get asr => _asr;

  @override
  DateTime get maghrib => _maghrib;

  @override
  DateTime get isha => _isha;

  @override
  DateTime? timeForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _fajr;
      case Prayer.sunrise:
        return _sunrise;
      case Prayer.dhuhr:
        return _dhuhr;
      case Prayer.asr:
        return _asr;
      case Prayer.maghrib:
        return _maghrib;
      case Prayer.isha:
        return _isha;
      default:
        return null;
    }
  }

  @override
  Duration? get utcOffset => _base.utcOffset;

  @override
  Prayer currentPrayerByDateTime(DateTime date) => currentPrayer(date);

  @override
  Prayer nextPrayerByDateTime(DateTime date) => nextPrayer(date);

  @override
  Prayer currentPrayer([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (now.isAfter(_isha)) return Prayer.isha;
    if (now.isAfter(_maghrib)) return Prayer.maghrib;
    if (now.isAfter(_asr)) return Prayer.asr;
    if (now.isAfter(_dhuhr)) return Prayer.dhuhr;
    if (now.isAfter(_sunrise)) return Prayer.sunrise;
    if (now.isAfter(_fajr)) return Prayer.fajr;
    return Prayer.none;
  }

  @override
  Prayer nextPrayer([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (now.isBefore(_fajr)) return Prayer.fajr;
    if (now.isBefore(_sunrise)) return Prayer.sunrise;
    if (now.isBefore(_dhuhr)) return Prayer.dhuhr;
    if (now.isBefore(_asr)) return Prayer.asr;
    if (now.isBefore(_maghrib)) return Prayer.maghrib;
    if (now.isBefore(_isha)) return Prayer.isha;
    return Prayer.none;
  }
}
