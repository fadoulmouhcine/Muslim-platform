import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅
import '../services/settings_provider.dart'; // ✅
import '../constants/app_strings.dart';


/// Represents the different states of location resolution used to drive
/// the Qibla screen's error/retry UI (Task 3.3).
enum _LocationStatus {
  loading,
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class QiblaScreen extends StatefulWidget {
  final VoidCallback? backToHome;

  const QiblaScreen({super.key, this.backToHome});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _hasSensor = false;
  double? _qiblaDirection;
  Timer? _timer;
  StreamSubscription? _compassSub;
  bool _isDialogShown = false;

  _LocationStatus _locationStatus = _LocationStatus.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSystemCheck();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  // ✅ Task 3.3 FIX: `heading == 0` is a mathematically VALID compass
  // reading (true/magnetic North). The previous logic incorrectly treated
  // `heading == 0` as "no sensor data yet" and kept waiting, which meant a
  // device that happened to be pointing exactly North on the first compass
  // event would get stuck forever waiting for a "non-zero" heading that
  // might never come again. We now only check for `null`, since a null
  // heading is the only value that legitimately means "sensor unavailable /
  // no reading yet" per the flutter_compass API contract.
  void _startSystemCheck() {
    if (FlutterCompass.events == null) {
      _showErrorAndExit();
      return;
    }

    _compassSub = FlutterCompass.events!.listen((event) {
      double? heading = event.heading;
      if (heading != null) {
        _compassSub?.cancel();
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _hasSensor = true;
          });
          _getQiblaLocation();
        }
      }
    });

    _timer = Timer(const Duration(seconds: 3), () {
      _compassSub?.cancel();
      if (!_hasSensor && mounted) {
        _showErrorAndExit();
      }
    });
  }

  void _showErrorAndExit() {
    if (_isDialogShown) return;
    setState(() => _isDialogShown = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("تنبيه"),
          ],
        ),
        content: const Text(
          "هاتفك لا يحتوي على مستشعر البوصلة.\nسيتم إعادتك للصفحة الرئيسية.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.backToHome != null) {
                widget.backToHome!();
              }
            },
            child: const Text(
              "حسناً (OK)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Task 3.3: Location resolution now tracks an explicit `_LocationStatus`
  // so the UI can render a clean retry/error state instead of silently
  // leaving `_qiblaDirection` null forever (which just showed "تحديد
  // الموقع..." indefinitely with no way to recover without leaving the screen).
  Future<void> _getQiblaLocation() async {
    if (mounted) {
      setState(() => _locationStatus = _LocationStatus.loading);
    }

    try {
      // 1. Ensure the location service itself is enabled on the device.
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationStatus = _LocationStatus.serviceDisabled);
        }
        return;
      }

      // 2. Check / request permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _locationStatus = _LocationStatus.permissionDenied);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
              () => _locationStatus = _LocationStatus.permissionDeniedForever);
        }
        return;
      }

      // 3. Fetch position & compute Qibla direction.
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(myCoordinates);
      if (mounted) {
        setState(() {
          _qiblaDirection = qibla.direction;
          _locationStatus = _LocationStatus.success;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() => _locationStatus = _LocationStatus.error);
      }
    }
  }

  /// ✅ Task 3.3: Opens the device's app/location settings so the user can
  /// grant permission or enable location services, then retries automatically.
  Future<void> _openSettingsAndRetry({required bool locationServiceSettings}) async {
    if (locationServiceSettings) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
    // Give the user a moment to change the setting before re-checking.
    if (mounted) {
      _getQiblaLocation();
    }
  }

  /// ✅ Task 3.3: Clean, centered retry/error UI shown whenever location
  /// resolution fails, instead of an indefinite "تحديد الموقع..." spinner.
  Widget _buildLocationErrorState() {
    late final IconData icon;
    late final String title;
    late final String subtitle;
    late final String actionLabel;
    late final VoidCallback onAction;

    switch (_locationStatus) {
      case _LocationStatus.serviceDisabled:
        icon = Icons.location_off_rounded;
        title = "خدمة الموقع معطلة";
        subtitle = "يرجى تفعيل خدمة الموقع (GPS) لتحديد اتجاه القبلة بدقة.";
        actionLabel = "تفعيل الموقع";
        onAction = () => _openSettingsAndRetry(locationServiceSettings: true);
        break;
      case _LocationStatus.permissionDenied:
        icon = Icons.location_disabled_rounded;
        title = "تم رفض إذن الموقع";
        subtitle = "نحتاج إذن الوصول للموقع لحساب اتجاه القبلة الصحيح.";
        actionLabel = AppStrings.retry;
        onAction = _getQiblaLocation;
        break;
      case _LocationStatus.permissionDeniedForever:

        icon = Icons.location_disabled_rounded;
        title = "الإذن مرفوض نهائياً";
        subtitle = "يرجى تفعيل إذن الموقع يدوياً من إعدادات التطبيق.";
        actionLabel = "فتح الإعدادات";
        onAction = () => _openSettingsAndRetry(locationServiceSettings: false);
        break;
      case _LocationStatus.error:
      default:
        icon = Icons.error_outline_rounded;
        title = "تعذر تحديد الموقع";
        subtitle = "حدث خطأ أثناء محاولة تحديد موقعك. يرجى المحاولة مرة أخرى.";
        actionLabel = AppStrings.retry;
        onAction = _getQiblaLocation;
        break;
    }


    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                actionLabel,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: const Color(0xFF1F2937),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. جلب الإعدادات
    final settings = Provider.of<SettingsProvider>(context);

    if (!_hasSensor) {
      return const Scaffold(
        backgroundColor: Color(0xFF1F2937),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        title: const Text(
          "اتجاه القبلة",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // ✅ Task 3.3: Show a clean retry/error state if location resolution
      // failed, instead of silently keeping the compass UI stuck on
      // "تحديد الموقع..." forever with no way to recover.
      body: _locationStatus != _LocationStatus.success &&
              _locationStatus != _LocationStatus.loading
          ? _buildLocationErrorState()
          : StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error", style: TextStyle(color: Colors.white)),
                  );
                }

                double? direction = snapshot.data?.heading;

                if (direction == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                double qiblaAngle = (_qiblaDirection ?? 0);

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        // ✅ 2. تحويل رقم الدرجة (Heading)
                        "${settings.replaceDigits(direction.ceil().toString())}°",
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _qiblaDirection == null
                            ? "تحديد الموقع..."
                            // ✅ 3. تحويل رقم زاوية مكة
                            : "مكة: ${settings.replaceDigits(qiblaAngle.toStringAsFixed(1))}°",
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        height: 320,
                        width: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: (direction * (math.pi / 180) * -1),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF374151),
                                  border: Border.all(
                                    color: Colors.grey.shade700,
                                    width: 4,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.north,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            if (_qiblaDirection != null)
                              Transform.rotate(
                                angle: ((qiblaAngle - direction) *
                                    (math.pi / 180)),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 60,
                                      color: Color(0xFFC5A059),
                                    ),
                                    SizedBox(height: 110),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
