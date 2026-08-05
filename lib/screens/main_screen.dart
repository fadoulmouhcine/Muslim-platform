import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/vibration_service.dart';
import '../main.dart'; // ✅ Import Global Key
import 'dashboard_screen.dart';
import '../services/widget_service.dart';
import 'daily_harvest_screen.dart';
import 'quran_screen.dart';
import 'sunnah_screen.dart';
import 'settings_screen.dart';
import '../services/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

// 🔥 1. زدنا "with WidgetsBindingObserver" باش نراقبو حالة التطبيق
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  PrayerTimes? _prayerTimes;
  Coordinates? _myCoordinates;
  CalculationParameters? _params;
  String _city = "جاري تحديد الموقع...";
  bool _isLoading = true;
  StreamSubscription<String>? _adhanSubscription;

  String _lastCalculationMethod = '';

  @override
  void initState() {
    super.initState();
    // 🔥 2. كنفعل المراقب فاش كتحل الصفحة
    WidgetsBinding.instance.addObserver(this);

    // ✅ Check for Initial Payload (Cold Start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPayload();
      _listenToSettingsChanges();
    });

    _initAdhanTriggerListener();
    _initLocationAndPrayers();
  }

  void _initAdhanTriggerListener() {
    _adhanSubscription =
        NotificationService.onAdhanTriggered.listen((prayerName) {
      if (!mounted) return;
      debugPrint(
          "🕌 MainScreen received AdhanTriggered for $prayerName -> Reactively rebuilding UI banner!");
      if (_myCoordinates != null && _params != null) {
        final times = PrayerTimes.today(_myCoordinates!, _params!);
        setState(() {
          _prayerTimes = times;
        });
      } else {
        setState(() {});
      }
    });
  }

  // ✅ 100% OFFLINE: Prayer times are now always computed instantly and
  // deterministically via the `adhan` astronomical calculation engine —
  // no network round-trip, no cache invalidation, no "no internet" state.
  void _listenToSettingsChanges() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _lastCalculationMethod = settings.calculationMethod;
    settings.addListener(() {
      if (!mounted) return;
      if (settings.calculationMethod != _lastCalculationMethod ||
          settings.madhab !=
              (_params?.madhab == Madhab.hanafi ? 'hanafi' : 'shafi')) {
        _lastCalculationMethod = settings.calculationMethod;
        debugPrint(
            "⚡ Calculation settings changed -> Reactively recomputing offline prayer times...");
        final coords = _myCoordinates ?? Coordinates(21.4225, 39.8262);
        final params = settings.getCalculationParameters();
        final times = PrayerTimes.today(coords, params);
        setState(() {
          _params = params;
          _prayerTimes = times;
        });
        WidgetService.updateWidgetData(prayerTimes: times, city: _city);
      }
    });
  }

  // 🔥 Helper: Check for pending notification payload
  Future<void> _checkPayload() async {
    String? payload = await NotificationService.consumePendingPayload();

    // Clean up payload
    payload = payload?.trim();

    if (payload != null && mounted) {
      // Long delay (1s) to ensuring everything is settled
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      if (payload == 'daily_harvest') {
        try {
          if (navigatorKey.currentState != null) {
            // Short UX Feedback
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("جاري الانتقال إلى حصاد اليوم 🌿",
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFC5A059),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ));

            // Navigate via Global Key
            navigatorKey.currentState!.push(
              MaterialPageRoute(builder: (_) => const DailyHarvestScreen()),
            );
          }
        } catch (e) {
          debugPrint("❌ Navigation Error: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    _adhanSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔥 4. هاد الدالة هي "العقل المدبر": كتعيق بيك فاش كترجع للتطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 User returned -> Re-syncing notifications...");

      // ✅ Check for Payload (Background/Warm Start)
      _checkPayload();

      // إلا كان عندنا الموقع والبارامترات، كنعاودو نحسبو الوقت دابا
      final coords = _myCoordinates;
      final params = _params;
      if (coords != null && params != null && mounted) {
        final times = PrayerTimes.today(coords, params);
        setState(() {
          _prayerTimes = times;
        });

        NotificationService.schedulePrayerNotifications(times, context);
        WidgetService.updateWidgetData(prayerTimes: times, city: _city);
      }
    }
  }

  /// ✅ 100% OFFLINE PRAYER-TIME RESOLUTION FLOW
  /// Prayer times are always computed locally via the `adhan` astronomical
  /// engine the instant we have GPS coordinates (or a cached fallback) —
  /// no network dependency whatsoever. The only thing that can legitimately
  /// block this flow is the *location* subsystem itself (GPS service off,
  /// or permission denied), never connectivity.
  Future<void> _initLocationAndPrayers({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        if (_prayerTimes == null) _isLoading = true;
      });
    } else {
      setState(() {
        _city = "جاري تحديد الموقع...";
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      double? cachedLat = prefs.getDouble('latitude');
      double? cachedLng = prefs.getDouble('longitude');
      String? cachedCity = prefs.getString('city');

      bool hasCache =
          cachedLat != null && cachedLng != null && cachedCity != null;

      // 1. INSTANT OFFLINE CALCULATION FROM CACHED COORDINATES
      // (Shown immediately on every launch — zero network, zero delay.)
      if (hasCache) {
        debugPrint("📦 Fast Cache Hit! Computing offline prayer times instantly.");
        _myCoordinates = Coordinates(cachedLat, cachedLng);
        _city = cachedCity;
        if (!mounted) return;
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        _params = settings.getCalculationParameters();
        final times = PrayerTimes.today(_myCoordinates!, _params!);
        if (mounted) {
          setState(() {
            _prayerTimes = times;
            _isLoading = false;
          });
          WidgetService.updateWidgetData(prayerTimes: times, city: _city);
        }
      }

      // 2. LOCATION SERVICE / PERMISSION CHECKS
      // (No connectivity check needed — the calculation engine is offline.)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!hasCache && mounted) {
          await _showEnableLocationDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!hasCache && mounted) {
            setState(() {
              _city = "الإذن مرفوض";
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!hasCache && mounted) {
          setState(() {
            _city = "الإذن مرفوض نهائياً";
            _isLoading = false;
          });
        }
        return;
      }

      // 3. Fetch a fresh GPS fix in the background (low accuracy for speed)
      // to refine location/city — prayer times are recomputed offline
      // the instant we have coordinates, regardless of network state.
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );

        // Save & Reschedule
        await _updateLocationData(position, isBackgroundUpdate: hasCache);
      } catch (e) {
        debugPrint("⚠️ Silent GPS Sync Failed: $e");
        if (!hasCache && mounted) {
          setState(() {
            _city = "تعذر تحديد الموقع";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateLocationData(Position position,
      {required bool isBackgroundUpdate}) async {
    final prefs = await SharedPreferences.getInstance();

    // Skip recalculation if haven't moved significantly
    if (isBackgroundUpdate) {
      double? cachedLat = prefs.getDouble('latitude');
      double? cachedLng = prefs.getDouble('longitude');
      if (cachedLat != null && cachedLng != null) {
        double distanceInMeters = Geolocator.distanceBetween(
            cachedLat, cachedLng, position.latitude, position.longitude);
        if (distanceInMeters < 5000) {
          debugPrint(
              "✅ User is in same area (Diff: ${distanceInMeters.toInt()}m). Sync complete.");
          return; // Do nothing
        }
      }
    }

    _myCoordinates = Coordinates(position.latitude, position.longitude);

    const String lang = 'ar';
    const String fallbackCity = "موقعي";

    String newCity = fallbackCity;
    String? countryCode;

    bool isGpsSource = false;

    try {
      await setLocaleIdentifier(lang);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude)
              .timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        newCity = placemarks.first.locality ??
            placemarks.first.country ??
            fallbackCity;
        if (newCity.isEmpty) newCity = fallbackCity;
        countryCode = placemarks.first.isoCountryCode;
        if (countryCode != null && countryCode.isNotEmpty) {
          isGpsSource = true;
        }
      }
    } catch (e) {
      // ✅ Reverse-geocoding (city name) requires network, but the prayer
      // time calculation itself does NOT — so a failure here only affects
      // the displayed city label, never the accuracy of the prayer times.
      debugPrint("⚠️ Error getting city/country via geocoding (network?): $e");
    }

    if (countryCode == null || countryCode.isEmpty) {
      try {
        final locale = Platform.localeName;
        if (locale.contains('_')) {
          countryCode = locale.split('_').last;
        } else if (locale.contains('-')) {
          countryCode = locale.split('-').last;
        }
        isGpsSource = false;
        debugPrint(
            "⚠️ Geocoding failed/empty. Falling back to device locale region: $countryCode (locale: $locale)");
      } catch (e) {
        debugPrint("Error reading locale fallback: $e");
      }
    }

    if (countryCode != null && countryCode.isNotEmpty && mounted) {
      debugPrint(
          "🌍 [LOCATION-RESOLVE] Source: ${isGpsSource ? 'GPS' : 'LOCALE'} | CountryCode: $countryCode | Lat/Lng: (${position.latitude}, ${position.longitude})");
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await settings.resolveLocationMethod(
        countryCode: countryCode,
        isGpsSource: isGpsSource,
        lat: position.latitude,
        lng: position.longitude,
      );
    }

    // Save for Fast Cache
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);
    await prefs.setString('city', newCity);

    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _params = settings.getCalculationParameters();
    // ✅ Fully offline astronomical calculation — instant, deterministic,
    // no network round-trip required.
    final PrayerTimes computedTimes =
        PrayerTimes.today(_myCoordinates!, _params!);

    if (mounted) {
      setState(() {
        _city = newCity;
        _prayerTimes = computedTimes;
        _isLoading = false;
      });

      NotificationService.schedulePrayerNotifications(computedTimes, context);
      WidgetService.updateWidgetData(prayerTimes: computedTimes, city: _city);
    }
  }

  Future<void> _showEnableLocationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تفعيل الموقع"),
          content: const Text("المرجو تفعيل GPS."),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isLoading = false);
                },
                child: const Text("إلغاء")),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                  _initLocationAndPrayers();
                },
                child: const Text("تفعيل")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2D5A3F))) // Updated loading color
          : DashboardScreen(
              onTabChange: (index) => setState(() => _selectedIndex = index),
              prayerTimes: _prayerTimes,
              city: _city,
              coordinates: _myCoordinates,
              params: _params,
              onRetryLocation: () {
                _initLocationAndPrayers(showLoader: false);
              },
            ),
      const SunnahScreen(),
      const QuranScreen(),
      const SettingsScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors.of(context);

    final systemAreaBg = isDark ? Colors.black : c.scaffoldBg;
    final barBg = isDark ? const Color(0xFF0A2E23) : Colors.white;
    final topBorderColor = isDark
        ? const Color(0xFFC5A059)
        : const Color(0xFF003527).withValues(alpha: 0.15);
    final activeColor =
        isDark ? const Color(0xFFC5A059) : const Color(0xFF003527);
    final inactiveColor = isDark ? Colors.white60 : Colors.grey[600]!;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: systemAreaBg,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: c.scaffoldBg,
          extendBody: false,
          body: pages[_selectedIndex],
          bottomNavigationBar: Container(
            color: systemAreaBg,
            child: SafeArea(
              bottom: true,
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20.0)),
                  border: Border(
                    top: BorderSide(
                      color: topBorderColor,
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20.0)),
                  child: SizedBox(
                    height: 60,
                    child: BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: (idx) {
                        final settings = Provider.of<SettingsProvider>(context,
                            listen: false);
                        VibrationService.triggerHaptic(settings);
                        setState(() => _selectedIndex = idx);
                      },
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: activeColor,
                      unselectedItemColor: inactiveColor,
                      selectedLabelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 11),
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined, size: 22),
                          activeIcon: Icon(Icons.home_rounded, size: 22),
                          label: 'الرئيسية',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.mosque_outlined, size: 22),
                          activeIcon: Icon(Icons.mosque_rounded, size: 22),
                          label: 'السنة',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book_outlined, size: 22),
                          activeIcon: Icon(Icons.menu_book_rounded, size: 22),
                          label: 'القرآن',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline_rounded, size: 22),
                          activeIcon: Icon(Icons.person_rounded, size: 22),
                          label: 'حسابي',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
