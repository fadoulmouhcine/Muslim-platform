import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'quran_service.dart';

class SettingsProvider with ChangeNotifier {
  // --- إعدادات المصحف ---
  double _fontSize = 24.0;
  bool _isMushafMode = true;
  String _quranType = 'hafs';
  String _numberType = 'arabic'; // 'arabic' (١٢٣) or 'latin' (123)
  bool _isTajweedMode = false;

  // --- إعدادات الأذان ---
  String _adhanSound = 'adhan_hamza';
  double _adhanVolume = 0.8;
  int _notificationOffset = 0;
  String _calculationMethod = 'mwl';
  int? _preFajrAlarmMinutes;
  Map<String, bool> _prayerMuteStatus = {
    'fajr': false,
    'dhuhr': false,
    'asr': false,
    'maghrib': false,
    'isha': false,
  };
  Map<String, int> _prayerOffsets = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  // --- إعدادات الـ Setup والأهداف ---
  bool _isFirstTime = true;
  String _userName = "مسلم"; // ✅ Default fallback name
  // ✅ Arabic-only app: locale is fixed and no longer user-configurable.
  static const Locale _appLocale = Locale('ar');
  int _dailyHizbGoal = 1;

  int _dailyTasbihGoal = 100;
  bool _remindAdhkarSabah = true;
  bool _remindAdhkarMasaa = true;
  bool _autoSilentEnabled = false;
  bool _respectSilentMode = false;
  bool _isHapticEnabled = true; // ✅ Global haptic setting

  // --- إعدادات التذكيرات الذكية (Step 3) ---
  bool _isMulkReminderEnabled = true;
  bool _isFastingReminderEnabled = true;
  bool _isFridaySalawatReminderEnabled = true;

  // --- إعدادات المظهر ---
  ThemeMode _themeMode = ThemeMode.system;

  // --- إعدادات التقويم الهجري والميلادي ---
  String _gregorianMonthNaming =
      'standard'; // 'standard', 'maghrebi', 'levantine'
      
  // --- Location Data ---
  double? _latitude;
  double? _longitude;
  String? _city;
  
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get city => _city;
  
  Future<void> setLocation(double lat, double lng, String? cityName) async {
    _latitude = lat;
    _longitude = lng;
    if (cityName != null && cityName.trim().isNotEmpty) {
      _city = cityName.trim();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', lat);
    await prefs.setDouble('longitude', lng);
    if (_city != null) {
      await prefs.setString('city', _city!);
    }
    notifyListeners();
  }

  // --- Getters ---
  String get userName => _userName;
  double get fontSize => _fontSize;
  bool get isMushafMode => _isMushafMode;
  String get quranType => _quranType;
  String get numberType => _numberType;
  bool get isTajweedMode => _isTajweedMode;
  bool get isWarsh => _quranType == 'warsh';
  String get gregorianMonthNaming => _gregorianMonthNaming;
  bool get autoSilentEnabled => _autoSilentEnabled;
  bool get respectSilentMode => _respectSilentMode;
  bool get isHapticEnabled => _isHapticEnabled;
  bool get isMulkReminderEnabled => _isMulkReminderEnabled;
  bool get isFastingReminderEnabled => _isFastingReminderEnabled;
  bool get isFridaySalawatReminderEnabled => _isFridaySalawatReminderEnabled;
  // --- إعدادات نظام عرض الوقت ---
  String _timeFormatMode = 'system'; // 'system', 'h12', 'h24'
  String get timeFormatMode => _timeFormatMode;
  bool get is24HourFormat => _timeFormatMode == 'h24';

  Future<void> setTimeFormatMode(String mode) async {
    if (_timeFormatMode != mode) {
      _timeFormatMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('time_format_mode', mode);
      notifyListeners();
    }
  }

  Future<void> toggleTimeFormat(bool value) async {
    await setTimeFormatMode(value ? 'h24' : 'h12');
  }

  String formatPrayerTime(DateTime time,
      {BuildContext? context, bool? alwaysUse24HourFormat}) {
    bool use24 = false;
    if (_timeFormatMode == 'h24') {
      use24 = true;
    } else if (_timeFormatMode == 'h12') {
      use24 = false;
    } else {
      if (alwaysUse24HourFormat != null) {
        use24 = alwaysUse24HourFormat;
      } else if (context != null) {
        try {
          use24 = MediaQuery.of(context).alwaysUse24HourFormat;
        } catch (_) {
          use24 = false;
        }
      } else {
        use24 = false;
      }
    }

    if (use24) {
      String formatted = DateFormat('HH:mm').format(time);
      return replaceDigits(formatted);
    } else {
      String formatted = DateFormat.jm(currentLanguage).format(time);
      return replaceDigits(formatted);
    }
  }

  Future<void> setMulkReminderEnabled(bool enabled) async {
    if (_isMulkReminderEnabled != enabled) {
      _isMulkReminderEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMulkReminderEnabled', enabled);
      notifyListeners();
    }
  }

  Future<void> setFastingReminderEnabled(bool enabled) async {
    if (_isFastingReminderEnabled != enabled) {
      _isFastingReminderEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFastingReminderEnabled', enabled);
      notifyListeners();
    }
  }

  Future<void> setFridaySalawatReminderEnabled(bool enabled) async {
    if (_isFridaySalawatReminderEnabled != enabled) {
      _isFridaySalawatReminderEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFridaySalawatReminderEnabled', enabled);
      notifyListeners();
    }
  }

  Future<void> setAutoSilentEnabled(bool enabled) async {
    _autoSilentEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSilentEnabled', enabled);
    notifyListeners();
  }

  Future<void> setRespectSilentMode(bool enabled) async {
    _respectSilentMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('respect_silent_mode', enabled);
    notifyListeners();
  }

  Future<void> setHapticEnabled(bool enabled) async {
    if (_isHapticEnabled != enabled) {
      _isHapticEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isHapticEnabled', enabled);
      notifyListeners();
    }
  }

  static const Map<String, List<String>> _gregorianMonthNames = {
    'standard': [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ],
    'maghrebi': [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'ماي',
      'يونيو',
      'يوليوز',
      'غشت',
      'شتنبر',
      'أكتوبر',
      'نونبر',
      'دجنبر'
    ],
    'levantine': [
      'كانون الثاني',
      'شباط',
      'آذار',
      'نيسان',
      'أيار',
      'حزيران',
      'تموز',
      'آب',
      'أيلول',
      'تشرين الأول',
      'تشرين الثاني',
      'كانون الأول'
    ],
  };

  String getGregorianMonthName(int month) {
    if (month < 1 || month > 12) return '';
    final list = _gregorianMonthNames[_gregorianMonthNaming] ??
        _gregorianMonthNames['standard']!;
    return list[month - 1];
  }

  Future<void> setGregorianMonthNaming(String mode) async {
    if (_gregorianMonthNaming != mode) {
      _gregorianMonthNaming = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gregorian_month_naming', mode);
      notifyListeners();
    }
  }

  String get adhanSound => _adhanSound;
  double get adhanVolume => _adhanVolume;
  int get notificationOffset => _notificationOffset;
  String get calculationMethod => _calculationMethod;
  int? get preFajrAlarmMinutes => _preFajrAlarmMinutes;
  int get preFajrMinutes => _preFajrAlarmMinutes ?? 0;

  bool get isFirstTime => _isFirstTime;
  // ✅ Arabic-only app: always returns the fixed Arabic locale.
  Locale get appLocale => _appLocale;
  String get currentLanguage => _appLocale.languageCode;

  int get dailyHizbGoal => _dailyHizbGoal;
  int get dailyTasbihGoal => _dailyTasbihGoal;
  bool get remindAdhkarSabah => _remindAdhkarSabah;
  bool get remindAdhkarMasaa => _remindAdhkarMasaa;

  ThemeMode get themeMode => _themeMode;

  bool isPrayerMuted(String prayerName) {
    return _prayerMuteStatus[prayerName] ?? false;
  }

  bool isPrayerEnabled(String prayerName) {
    return !isPrayerMuted(prayerName);
  }

  Future<void> setPrayerNotification(String prayerName, bool enabled) async {
    if (isPrayerEnabled(prayerName) != enabled) {
      await togglePrayerMute(prayerName);
    }
  }

  Future<void> setPreFajrMinutes(int minutes) async {
    await setPreFajrAlarmMinutes(minutes == 0 ? null : minutes);
  }

  int getPrayerOffset(String prayerKey) {
    return _prayerOffsets[prayerKey] ?? 0;
  }

  int _quranFontStyleIndex = 0;
  int get quranFontStyleIndex => _quranFontStyleIndex;

  Future<void> setQuranFontStyleIndex(int index) async {
    _quranFontStyleIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quranFontStyleIndex', index);
    notifyListeners();
  }

  // --- إعدادات خط "القرآن البسيط" ---
  // ✅ Font family picker for "القرآن البسيط" (Simple Quran mode). All
  // options are clean, fully-Arabic-script-capable, bundled fonts (no
  // network fetching — see `GoogleFonts.config.allowRuntimeFetching` in
  // main.dart). Amiri remains the default (traditional Naskh, ideal for
  // stacked harakāt), while Cairo and Aref Ruqaa offer alternative modern/
  // calligraphic clean reading styles.
  String _simpleFontFamily = 'Amiri';
  String get simpleFontFamily => _simpleFontFamily;

  static const Map<String, String> simpleFontOptions = {
    'Amiri': 'أميري',
    'Cairo': 'القاهرة',
    'ArefRuqaa': 'عارف رقعة',
  };

  Future<void> setSimpleFontFamily(String family) async {
    if (!simpleFontOptions.containsKey(family)) return;
    if (_simpleFontFamily != family) {
      _simpleFontFamily = family;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('simpleFontFamily', family);
      notifyListeners();
    }
  }

  // --- Font & Path Helpers ---
  String get currentFontFamily {
    // index 1 = "القرآن البسيط" (Simple): the user-selected clean typeface
    // (see `simpleFontFamily`/`setSimpleFontFamily`) is used — it handles
    // stacked harakāt without metric collisions. The reading screen further
    // strips complex Tajweed/stop-sign annotation marks for this mode via
    // `TajweedService.simplifyForPlainMode()`, while keeping the standard
    // essential diacritics (fatha/damma/kasra/sukun/shadda) intact.
    if (_quranFontStyleIndex == 1) {
      switch (_simpleFontFamily) {
        case 'Cairo':
          return GoogleFonts.cairo().fontFamily ?? 'Cairo';
        case 'ArefRuqaa':
          return GoogleFonts.arefRuqaa().fontFamily ?? 'Aref Ruqaa';
        default:
          return GoogleFonts.amiri().fontFamily ?? 'Amiri';
      }
    }
    if (_quranType == 'warsh') return 'Warsh';

    if (_quranType == 'qaloun') return 'Qaloun';
    if (_quranType == 'sousi') return 'Sousi';
    if (_quranType == 'douri') return 'Douri';
    if (_quranType == 'shuba') return 'Shuba';
    return 'Hafs';
  }

  String get currentJsonPath {
    if (_quranType == 'warsh') return 'assets/json/quran/warsh.json';
    if (_quranType == 'qaloun') return 'assets/json/quran/qaloun.json';
    if (_quranType == 'sousi') return 'assets/json/quran/sousi.json';
    if (_quranType == 'douri') return 'assets/json/quran/douri.json';
    if (_quranType == 'shuba') return 'assets/json/quran/shuba.json';
    return 'assets/json/quran/hafs.json';
  }

  String get qiraaName {
    if (_quranType == 'warsh') return 'رواية ورش عن نافع';
    if (_quranType == 'qaloun') return 'رواية قالون عن نافع';
    if (_quranType == 'sousi') return 'رواية السوسي عن أبي عمرو';
    if (_quranType == 'douri') return 'رواية الدوري عن أبي عمرو';
    if (_quranType == 'shuba') return 'رواية شعبة عن عاصم';
    return 'رواية حفص عن عاصم';
  }

  CalculationParameters getCalculationParameters() {
    CalculationParameters params;
    switch (_calculationMethod) {
      case 'morocco':
        params = CalculationParameters(
          fajrAngle: 19.0,
          ishaAngle: 17.0,
          method: CalculationMethod.other,
        );
        params.adjustments.dhuhr = 5;
        params.adjustments.maghrib = 3;
        break;
      case 'karachi':
        params = CalculationMethod.karachi.getParameters();
        break;
      case 'isna':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'mwl':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'egypt':
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 'umm_al_qura':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'france':
      case 'paris_mosque':
        params = CalculationParameters(
          fajrAngle: 12.0,
          ishaAngle: 12.0,
          method: CalculationMethod.other,
        );
        break;
      case 'algeria':
        params = CalculationParameters(
          fajrAngle: 18.0,
          ishaAngle: 17.0,
          method: CalculationMethod.other,
        );
        break;
      case 'tunisia':
        params = CalculationParameters(
          fajrAngle: 18.0,
          ishaAngle: 18.0,
          method: CalculationMethod.other,
        );
        break;
      case 'kuwait':
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 'uae':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'palestine':
        params = CalculationParameters(
          fajrAngle: 18.0,
          ishaAngle: 17.0,
          method: CalculationMethod.other,
        );
        break;
      case 'turkey':
        params = CalculationMethod.qatar.getParameters();
        break;
      case 'belgium':
      case 'igmg_germany':
        params = CalculationParameters(
          fajrAngle: 18.0,
          ishaAngle: 18.0,
          method: CalculationMethod.other,
        );
        break;
      default:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
    }
    params.madhab = _madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return params;
  }


  // --- Load Settings ---
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Location
    _latitude = prefs.getDouble('latitude');
    _longitude = prefs.getDouble('longitude');
    _city = prefs.getString('city');


    // Quran
    _fontSize = prefs.getDouble('fontSize') ?? 24.0;
    _isMushafMode = prefs.getBool('isMushafMode') ?? true;
    _quranType = prefs.getString('quranType') ?? 'hafs';
    _numberType = prefs.getString('numberType') ?? 'arabic';
    _isTajweedMode = prefs.getBool('isTajweedMode') ?? false;
    // ✅ Migration: "القرآن النسخ" (old index 1) was removed, leaving only
    // two options — "القرآن العثماني" (0) and "القرآن البسيط" (was index 2,
    // now index 1). Remap any previously-saved value so existing users don't
    // land on a now-nonexistent option.
    final savedFontStyleIndex = prefs.getInt('quranFontStyleIndex') ?? 0;
    if (savedFontStyleIndex == 2) {
      _quranFontStyleIndex = 1; // Old "Simple" -> new "Simple" slot.
    } else if (savedFontStyleIndex == 1) {
      _quranFontStyleIndex = 0; // Old "Naskh" (removed) -> fallback Uthmanic.
    } else {
      _quranFontStyleIndex = 0;
    }

    // ✅ "القرآن البسيط" font family picker: default to 'Amiri' if unset or
    // if a previously-saved value is no longer a valid/known option.
    final savedSimpleFontFamily = prefs.getString('simpleFontFamily');
    _simpleFontFamily = (savedSimpleFontFamily != null &&
            simpleFontOptions.containsKey(savedSimpleFontFamily))
        ? savedSimpleFontFamily
        : 'Amiri';


    // Adhan
    _adhanSound = prefs.getString('adhanSound') ?? 'adhan_hamza';
    _adhanVolume = prefs.getDouble('adhanVolume') ?? 0.8;
    _notificationOffset = prefs.getInt('notificationOffset') ?? 0;
    _calculationMethod = prefs.getString('calculationMethod') ?? 'mwl';
    _preFajrAlarmMinutes = prefs.getInt('preFajrAlarmMinutes');
    _isAutoMethod = prefs.getBool('isAutoMethod') ?? true;
    _lastCountryCode = prefs.getString('lastCountryCode');
    _lastResolutionSource = prefs.getString('lastResolutionSource');
    _pendingCountryCode = prefs.getString('pendingCountryCode');
    _previousMethodBeforeAutoSwitch =
        prefs.getString('previousMethodBeforeAutoSwitch');
    _madhab = prefs.getString('prayerMadhab') ?? 'shafi';


    String? muteJson = prefs.getString('prayerMuteStatus');
    if (muteJson != null) {
      Map<String, dynamic> decoded = json.decode(muteJson);
      _prayerMuteStatus =
          decoded.map((key, value) => MapEntry(key, value as bool));
    }

    String? offsetsJson = prefs.getString('prayerOffsets');
    if (offsetsJson != null) {
      Map<String, dynamic> decoded = json.decode(offsetsJson);
      _prayerOffsets = decoded.map((key, value) => MapEntry(key, value as int));
    }

    // Setup & Goals
    _isFirstTime = prefs.getBool('isFirstTime') ?? true;
    _userName = prefs.getString('userName') ?? "مسلم";

    _dailyHizbGoal = prefs.getInt('dailyHizbGoal') ?? 1;
    _respectSilentMode = prefs.getBool('respect_silent_mode') ?? false;

    _dailyTasbihGoal = prefs.getInt('dailyTasbihGoal') ?? 100;
    _remindAdhkarSabah = prefs.getBool('remindAdhkarSabah') ?? true;
    _remindAdhkarMasaa = prefs.getBool('remindAdhkarMasaa') ?? true;

    _gregorianMonthNaming =
        prefs.getString('gregorian_month_naming') ?? 'standard';
    _autoSilentEnabled = prefs.getBool('autoSilentEnabled') ?? false;
    _isHapticEnabled = prefs.getBool('isHapticEnabled') ?? true;
    _isMulkReminderEnabled = prefs.getBool('isMulkReminderEnabled') ?? true;
    _isFastingReminderEnabled =
        prefs.getBool('isFastingReminderEnabled') ?? true;
    _isFridaySalawatReminderEnabled =
        prefs.getBool('isFridaySalawatReminderEnabled') ?? true;
    _timeFormatMode = prefs.getString('time_format_mode') ??
        (prefs.getBool('is_24_hour_format') == true ? 'h24' : 'system');

    int themeIndex =
        prefs.getInt('themeMode') ?? 0; // 0: System, 1: Light, 2: Dark
    _themeMode = ThemeMode.values[themeIndex];

    notifyListeners();
  }

  // --- Setters ---

  Future<void> setUserName(String name) async {
    final cleanName = name.trim();
    _userName = cleanName.isEmpty ? "مسلم" : cleanName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> toggleViewMode(bool isMushaf) async {
    _isMushafMode = isMushaf;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMushafMode', isMushaf);
    notifyListeners();
  }

  Future<void> setQuranType(String type) async {
    if (type != 'hafs' &&
        type != 'warsh' &&
        type != 'qaloun' &&
        type != 'sousi' &&
        type != 'douri' &&
        type != 'shuba') {
      return;
    }
    _quranType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quranType', type);
    try {
      await QuranService.loadQuran(currentJsonPath, forceReload: true);
    } catch (e) {
      debugPrint("⚠️ Failed to load Quran data for $type: $e");
    }
    notifyListeners();
  }

  Future<void> setNumberType(String type) async {
    if (type != 'arabic' && type != 'latin') {
      return;
    }
    _numberType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numberType', type);
    notifyListeners();
  }

  Future<void> toggleTajweedMode(bool value) async {
    _isTajweedMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTajweedMode', value);
    notifyListeners();
  }

  Future<void> setAdhanSound(String sound) async {
    _adhanSound = sound;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhanSound', sound);
    notifyListeners();
  }

  Future<void> setAdhanVolume(double volume) async {
    _adhanVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('adhanVolume', volume);
    notifyListeners();
  }

  /// ✅ Lightweight local-only setter for real-time slider dragging.
  /// Updates the in-memory value and triggers a UI rebuild WITHOUT
  /// touching SharedPreferences — eliminating async I/O on every drag frame.
  /// Call [setAdhanVolume] in onChangeEnd to actually persist the final value.
  void setAdhanVolumeLocally(double volume) {
    _adhanVolume = volume;
    notifyListeners();
  }

  Future<void> setNotificationOffset(int minutes) async {
    _notificationOffset = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationOffset', minutes);
    notifyListeners();
  }

  bool _isAutoMethod = true;
  String? _lastCountryCode;
  String? _lastResolutionSource; // 'gps' or 'locale'
  String? _pendingCountryCode;
  String? _autoSwitchNoticeMessage;
  String? _previousMethodBeforeAutoSwitch;

  bool get isAutoMethod => _isAutoMethod;
  String? get lastCountryCode => _lastCountryCode;
  String? get lastResolutionSource => _lastResolutionSource;
  String? get autoSwitchNoticeMessage => _autoSwitchNoticeMessage;
  String? get previousMethodBeforeAutoSwitch => _previousMethodBeforeAutoSwitch;

  static const Map<String, String> countryToMethodMap = {
    'MA': 'morocco',
    'MAR': 'morocco',
    'SA': 'umm_al_qura',
    'EG': 'egypt',
    'DZ': 'algeria',
    'TN': 'tunisia',
    'KW': 'kuwait',
    'TR': 'turkey',
    'PK': 'karachi',
    'US': 'isna',
    'CA': 'isna',
    'FR': 'france',
    'AE': 'uae',
    'PS': 'palestine',
    'BE': 'belgium',
    'DE': 'igmg_germany',
  };

  static String resolveMethodForCountry(String? countryCode,
      {double? lat, double? lng}) {
    // 1. Lat/Lng Bounding Box override (authoritative for Morocco coordinates)
    if (lat != null && lng != null) {
      if (lat >= 20.0 && lat <= 36.0 && lng >= -17.0 && lng <= -1.0) {
        return 'morocco';
      }
      if (lat >= 16.0 && lat <= 32.0 && lng >= 34.0 && lng <= 56.0) {
        return 'umm_al_qura';
      }
      if (lat >= 22.0 && lat <= 32.0 && lng >= 25.0 && lng <= 36.0) {
        return 'egypt';
      }
    }

    // 2. ISO Country Code mapping
    if (countryCode == null) return 'mwl';
    final code = countryCode.toUpperCase().trim();
    return countryToMethodMap[code] ?? 'mwl';
  }

  Future<bool> resolveLocationMethod({
    required String countryCode,
    bool isGpsSource = true,
    double? lat,
    double? lng,
  }) async {
    String code = countryCode.toUpperCase().trim();
    if (lat != null && lng != null) {
      if (lat >= 20.0 && lat <= 36.0 && lng >= -17.0 && lng <= -1.0) {
        code = 'MA';
      }
    }

    final prefs = await SharedPreferences.getInstance();

    final sourceStr = isGpsSource ? 'gps' : 'locale';
    final previousCountry = _lastCountryCode;
    final previousSource = _lastResolutionSource;

    debugPrint(
        "[AUTO-METHOD] resolveLocationMethod: code=$code, gps=$isGpsSource (prev=$previousCountry/$previousSource)");

    // Save current resolution source and country
    _lastResolutionSource = sourceStr;
    await prefs.setString('lastResolutionSource', sourceStr);

    _lastCountryCode = code;
    await prefs.setString('lastCountryCode', code);

    if (!_isAutoMethod) {
      debugPrint("[AUTO-METHOD] Auto-method is locked. Skipping resolution.");
      return false;
    }

    final targetMethod = resolveMethodForCountry(code, lat: lat, lng: lng);

    // EAGER UPGRADE RULE:
    // If upgrading from a low-confidence 'locale' guess to a real 'gps' resolution,
    // BYPASS the 2-step travel debounce and switch immediately!
    final isEagerGpsUpgrade = (previousSource == 'locale' && isGpsSource);

    if (isEagerGpsUpgrade) {
      debugPrint(
          "[AUTO-METHOD] GPS upgrade from locale ($previousCountry) -> GPS ($code). Bypassing debounce.");
      _pendingCountryCode = null;
      await prefs.remove('pendingCountryCode');
    } else {
      // Normal 2-step debounce for confirmed GPS-to-GPS travel (or locale-to-locale updates)
      if (previousCountry != null && previousCountry != code) {
        if (_pendingCountryCode != code) {
          _pendingCountryCode = code;
          await prefs.setString('pendingCountryCode', code);
          debugPrint(
              "[AUTO-METHOD] Debounce: 1st check for $code via $sourceStr. Waiting for 2nd.");
          return false;
        }
      } else if (_pendingCountryCode != null && _pendingCountryCode != code) {
        _pendingCountryCode = code;
        await prefs.setString('pendingCountryCode', code);
        return false;
      }
    }

    _pendingCountryCode = null;
    await prefs.remove('pendingCountryCode');

    if (_calculationMethod != targetMethod) {
      _previousMethodBeforeAutoSwitch = _calculationMethod;
      _calculationMethod = targetMethod;

      await prefs.setString('calculationMethod', targetMethod);
      if (_previousMethodBeforeAutoSwitch != null) {
        await prefs.setString(
            'previousMethodBeforeAutoSwitch', _previousMethodBeforeAutoSwitch!);
      }

      final countryName = _getCountryNameInArabic(code);
      final methodName = _getMethodNameInArabic(targetMethod);
      _autoSwitchNoticeMessage =
          "تم تحديث طريقة الحساب تلقائياً إلى $methodName ($countryName)";

      debugPrint(
          "[AUTO-METHOD] Switched to $targetMethod for country $code via $sourceStr.");

      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> setAutoMethodEnabled(bool enabled,
      {String? currentCountryCode, double? lat, double? lng}) async {
    if (enabled) {
      final incomingCode = currentCountryCode ?? _lastCountryCode;
      final targetMethod =
          resolveMethodForCountry(incomingCode, lat: lat, lng: lng);

      // Short-circuit: if auto-method is already on, the country hasn't changed,
      // and the resolved target already matches the current method — nothing to do.
      // Avoids a redundant setCalculationMethod + notifyListeners cascade that
      // would re-fire the settings-fingerprint listener in main_screen and trigger
      // a background GPS sync for zero benefit.
      if (_isAutoMethod &&
          incomingCode == _lastCountryCode &&
          _calculationMethod == targetMethod) {
        debugPrint(
            "[AUTO-METHOD] No-op: already enabled, same country ($incomingCode), same method ($targetMethod).");
        return;
      }

      _isAutoMethod = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAutoMethod', true);
      await setCalculationMethod(targetMethod, isUserAction: false);
    } else {
      _isAutoMethod = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAutoMethod', false);
    }
    notifyListeners();
  }

  Future<void> revertAutoSwitch() async {
    if (_previousMethodBeforeAutoSwitch != null) {
      final prev = _previousMethodBeforeAutoSwitch!;
      _previousMethodBeforeAutoSwitch = null;
      _autoSwitchNoticeMessage = null;
      _isAutoMethod = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAutoMethod', false);
      await prefs.remove('previousMethodBeforeAutoSwitch');

      await setCalculationMethod(prev, isUserAction: true);
    }
  }

  void clearAutoSwitchNotice() {
    _autoSwitchNoticeMessage = null;
    notifyListeners();
  }

  static String _getCountryNameInArabic(String code) {
    switch (code) {
      case 'MA':
        return 'المغرب';
      case 'SA':
        return 'السعودية';
      case 'EG':
        return 'مصر';
      case 'DZ':
        return 'الجزائر';
      case 'TN':
        return 'تونس';
      case 'KW':
        return 'الكويت';
      case 'TR':
        return 'تركيا';
      case 'PK':
        return 'باكستان';
      case 'US':
        return 'أمريكا';
      case 'CA':
        return 'كندا';
      case 'FR':
        return 'فرنسا';
      case 'AE':
        return 'الإمارات';
      case 'PS':
        return 'فلسطين';
      case 'BE':
        return 'بلجيكا';
      case 'DE':
        return 'ألمانيا';
      default:
        return code;
    }
  }

  static String _getMethodNameInArabic(String key) {
    switch (key) {
      case 'morocco':
        return 'وزارة الأوقاف المغربية';
      case 'karachi':
        return 'جامعة العلوم الإسلامية بكراتشي';
      case 'isna':
        return 'الاتحاد الإسلامي بأمريكا الشمالية';
      case 'mwl':
        return 'رابطة العالم الإسلامي';
      case 'egypt':
        return 'الهيئة العامة المصرية للمساحة';
      case 'umm_al_qura':
        return 'تقويم أم القرى';
      case 'france':
        return 'اتحاد المنظمات الإسلامية في فرنسا';
      case 'algeria':
        return 'وزارة الشؤون الدينية والأوقاف الجزائرية';
      case 'tunisia':
        return 'وزارة الشؤون الدينية التونسية';
      case 'kuwait':
        return 'وزارة الأوقاف والشئون الإسلامية الكويتية';
      case 'paris_mosque':
        return 'مسجد باريس الكبير';
      case 'uae':
        return 'الهيئة العامة للشؤون الإسلامية والأوقاف - الإمارات';
      case 'palestine':
        return 'وزارة الأوقاف والشؤون الدينية الفلسطينية';
      case 'turkey':
        return 'رئاسة الشؤون الدينية التركية (ديانت)';
      case 'belgium':
        return 'المجلس التنفيذي الإسلامي ببلجيكا';
      case 'igmg_germany':
        return 'منظمة ملي جوروش بألمانيا (IGMG)';
      default:
        return key;
    }
  }

  Future<void> setCalculationMethod(String method,
      {bool isUserAction = true}) async {
    if (isUserAction) {
      _isAutoMethod = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAutoMethod', false);
    }

    if (_calculationMethod != method) {
      _calculationMethod = method;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('calculationMethod', method);
      notifyListeners();
    }
  }

  // --- إعدادات المذهب الفقهي (Shafi'i / Hanafi) ---
  // Affects the Asr prayer time calculation (shadow-length factor).
  String _madhab = 'shafi'; // 'shafi' or 'hanafi'
  String get madhab => _madhab;

  Future<void> setMadhab(String value) async {
    if (value != 'shafi' && value != 'hanafi') return;
    if (_madhab != value) {
      _madhab = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayerMadhab', value);
      notifyListeners();
    }
  }


  Future<void> setPreFajrAlarmMinutes(int? minutes) async {
    _preFajrAlarmMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    if (minutes != null) {
      await prefs.setInt('preFajrAlarmMinutes', minutes);
    } else {
      await prefs.remove('preFajrAlarmMinutes');
    }
    notifyListeners();
  }

  Future<void> togglePrayerMute(String prayerName) async {
    if (_prayerMuteStatus.containsKey(prayerName)) {
      _prayerMuteStatus[prayerName] = !(_prayerMuteStatus[prayerName] ?? false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayerMuteStatus', json.encode(_prayerMuteStatus));
      notifyListeners();
    }
  }

  Future<void> setPrayerOffset(String prayerKey, int minutes) async {
    _prayerOffsets[prayerKey] = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayerOffsets', json.encode(_prayerOffsets));
    notifyListeners();
  }

  Future<void> completeSetup() async {
    _isFirstTime = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    notifyListeners();
  }


  Future<void> updateGoals(
      {int? hizb, int? tasbih, bool? sabah, bool? masaa}) async {
    if (hizb != null) _dailyHizbGoal = hizb;
    if (tasbih != null) _dailyTasbihGoal = tasbih;
    if (sabah != null) _remindAdhkarSabah = sabah;
    if (masaa != null) _remindAdhkarMasaa = masaa;

    final prefs = await SharedPreferences.getInstance();
    if (hizb != null) prefs.setInt('dailyHizbGoal', hizb);
    if (tasbih != null) prefs.setInt('dailyTasbihGoal', tasbih);
    if (sabah != null) prefs.setBool('remindAdhkarSabah', sabah);
    if (masaa != null) prefs.setBool('remindAdhkarMasaa', masaa);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  // 🔥🔥🔥 دوال توحيد الأرقام (CORE LOGIC) 🔥🔥🔥

  // تستعمل لتحويل رقم الآية
  String getVerseNumber(int number) {
    return replaceDigits(number.toString());
  }

  // تستعمل لتحويل أي نص يحتوي على أرقام
  String replaceDigits(String input) {
    if (input.isEmpty) {
      return input;
    }

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    if (_numberType == 'latin') {
      // تحويل إلى 123 (Latin)
      for (int i = 0; i < arabic.length; i++) {
        input = input.replaceAll(arabic[i], english[i]);
      }
    } else {
      // تحويل إلى ١٢٣ (Arabic)
      for (int i = 0; i < english.length; i++) {
        input = input.replaceAll(english[i], arabic[i]);
      }
    }
    return input;
  }
}
