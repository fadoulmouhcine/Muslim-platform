import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅
import '../services/settings_provider.dart'; // ✅

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

  void _startSystemCheck() {
    if (FlutterCompass.events == null) {
      _showErrorAndExit();
      return;
    }

    _compassSub = FlutterCompass.events!.listen((event) {
      double? heading = event.heading;
      if (heading != null && heading != 0) {
        _compassSub?.cancel();
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

  Future<void> _getQiblaLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(myCoordinates);
      if (mounted) setState(() => _qiblaDirection = qibla.direction);
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
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
      body: StreamBuilder<CompassEvent>(
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
                          angle: ((qiblaAngle - direction) * (math.pi / 180)),
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
