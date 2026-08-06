import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../services/settings_provider.dart';
import '../../services/vibration_service.dart';
import '../main_screen.dart';
import '../../constants/app_strings.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _currentPage = 0;
  static const int _totalPages = 5;

  final TextEditingController _nameController = TextEditingController();

  // Premium colors
  final Color _bgDark = const Color(0xFF0B1016);
  final Color _primary = const Color(0xFFC5A059);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    FocusScope.of(context).unfocus();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.medium);

    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    } else {
      _finishSetup();
    }
  }

  void _goToPreviousPage() {
    FocusScope.of(context).unfocus();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.selection);

    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _finishSetup() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_nameController.text.trim().isNotEmpty) {
      await settings.setUserName(_nameController.text.trim());
    }
    await settings.completeSetup();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: const MainScreen(),
            );
          },
        ),
      );
    }
  }

  Widget _buildDotIndicator() {
    return Semantics(
      label: "الخطوة ${_currentPage + 1} من $_totalPages",
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_totalPages, (index) {
          final bool isActive = index == _currentPage;
          final bool isPast = index < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive || isPast ? _primary : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Ambient Gradient Background & Glassmorphism
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          // Blur Layer for Glassmorphism
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: _currentPage == 0,
                          child: InkWell(
                            onTap: _goToPreviousPage,
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white10),
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.02),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildDotIndicator(),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // Content Area with Smooth Custom Transitions
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(_currentPage),
                      alignment: Alignment.center,
                      child: _buildCurrentPage(),
                    ),
                  ),
                ),

                // Primary Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _goToNextPage,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _currentPage == _totalPages - 1 ? "ابدأ الرحلة" : "متابعة",
                            key: ValueKey<bool>(_currentPage == _totalPages - 1),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _NamePage(nameController: _nameController);
      case 1:
        return const _LocationPage();
      case 2:
        return const _NotificationPage();
      case 3:
        return const _QuranPage();
      case 4:
        return const _CalendarPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Helper for staggered animations on each page
class _StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Interval(
        (index * 0.15).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------
// Page 1: Name Page
// ---------------------------------------------------------
class _NamePage extends StatelessWidget {
  final TextEditingController nameController;

  const _NamePage({required this.nameController});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFC5A059);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StaggeredItem(
            index: 0,
            child: Text(
              "نتشرف بمعرفتك",
              style: GoogleFonts.cairo(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(
            index: 1,
            child: Text(
              "كيف تحب أن نناديك؟",
              style: GoogleFonts.cairo(fontSize: 18, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 48),
          _StaggeredItem(
            index: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: TextField(
                controller: nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\u0600-\u06FF\s]')),
                ],
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: "مثال: محسن",
                  hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 18),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: primary),
                  ),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StaggeredItem(
            index: 3,
            child: Text(
              "يرجى استخدام الحروف العربية فقط",
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Page 2: Location Page
// ---------------------------------------------------------
enum _PermissionState { idle, requesting, granted, denied }

class _LocationPage extends StatefulWidget {
  const _LocationPage();

  @override
  State<_LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<_LocationPage> {
  _PermissionState _locationState = _PermissionState.idle;
  String? _resolvedCity;
  final Color _primary = const Color(0xFFC5A059);

  Future<void> _requestLocation() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.light);
    
    setState(() => _locationState = _PermissionState.requesting);
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      if (!mounted) return;
      setState(() => _locationState = _PermissionState.denied);
      return;
    }
    
    if (!mounted) return;
    final granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    
    setState(() {
      _locationState = granted ? _PermissionState.granted : _PermissionState.denied;
    });

    if (granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        
        await setLocaleIdentifier('ar');
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude)
            .timeout(const Duration(seconds: 3));
        
        String? extractedCity;
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          extractedCity = p.locality;
          if (extractedCity == null || extractedCity.trim().isEmpty) {
            extractedCity = p.subAdministrativeArea;
          }
          if (extractedCity == null || extractedCity.trim().isEmpty) {
            extractedCity = p.administrativeArea;
          }
          if (extractedCity != null && extractedCity.trim().isNotEmpty) {
            if (mounted) {
              setState(() {
                _resolvedCity = extractedCity!.trim();
              });
            }
          }
        }
        await settings.setLocation(position.latitude, position.longitude, extractedCity);
      } catch (e) {
        debugPrint("Geocoding/Location Error during setup: $e");
      }
      VibrationService.triggerHaptic(settings, type: HapticType.medium);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGranted = _locationState == _PermissionState.granted;
    final bool isDenied = _locationState == _PermissionState.denied;
    final bool isRequesting = _locationState == _PermissionState.requesting;
    final activeColor = isGranted ? Colors.greenAccent : _primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StaggeredItem(
            index: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 2),
                color: activeColor.withValues(alpha: 0.1),
                boxShadow: isGranted ? [
                  BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
                ] : null,
              ),
              child: isRequesting
                  ? Padding(
                      padding: const EdgeInsets.all(36.0),
                      child: CircularProgressIndicator(color: activeColor, strokeWidth: 3),
                    )
                  : Icon(
                      isGranted ? Icons.check_circle_rounded : Icons.near_me_rounded,
                      size: 50,
                      color: activeColor,
                    ),
            ),
          ),
          const SizedBox(height: 48),
          _StaggeredItem(
            index: 1,
            child: Text(
              "تحديد الموقع",
              style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          _StaggeredItem(
            index: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                isGranted
                    ? (_resolvedCity != null
                        ? "تشرفنا بك، تم تحديد موقعك في $_resolvedCity بنجاح."
                        : "تم تحديد الموقع بنجاح!")
                    : "نحتاج لتحديد موقعك لحساب أوقات الصلاة واتجاه القبلة بدقة. العملية تتم محلياً بالكامل.",
                key: ValueKey(isGranted),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 48),
          if (isDenied)
            _StaggeredItem(
              index: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "تم رفض الصلاحية. يمكنك تفعيلها لاحقاً من الإعدادات.",
                        style: GoogleFonts.cairo(color: Colors.redAccent.shade100, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _StaggeredItem(
            index: 4,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: isGranted || isRequesting ? null : _requestLocation,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: activeColor.withValues(alpha: 0.3), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: activeColor,
                  backgroundColor: isGranted ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: Text(
                  isGranted ? "تم التفعيل بنجاح" : (isDenied ? AppStrings.retry : "منح صلاحية الموقع"),
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Page 3: Notifications Page
// ---------------------------------------------------------
class _NotificationPage extends StatefulWidget {
  const _NotificationPage();

  @override
  State<_NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<_NotificationPage> {
  _PermissionState _notificationState = _PermissionState.idle;
  final Color _primary = const Color(0xFFC5A059);

  Future<void> _requestNotification() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.light);
    
    setState(() => _notificationState = _PermissionState.requesting);
    
    bool granted = false;
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (Platform.isAndroid) {
        final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final result = await android?.requestNotificationsPermission();
        granted = result ?? false;
      } else if (Platform.isIOS) {
        final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final result = await ios?.requestPermissions(alert: true, badge: true, sound: true);
        granted = result ?? false;
      }
      
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (fcmError) {
        debugPrint("FCM Permission Error: $fcmError");
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
    
    if (!mounted) return;
    setState(() {
      _notificationState = granted ? _PermissionState.granted : _PermissionState.denied;
    });

    if (granted) {
      VibrationService.triggerHaptic(settings, type: HapticType.medium);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGranted = _notificationState == _PermissionState.granted;
    final bool isDenied = _notificationState == _PermissionState.denied;
    final bool isRequesting = _notificationState == _PermissionState.requesting;
    final activeColor = isGranted ? Colors.greenAccent : _primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StaggeredItem(
            index: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 2),
                color: activeColor.withValues(alpha: 0.1),
                boxShadow: isGranted ? [
                  BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
                ] : null,
              ),
              child: isRequesting
                  ? Padding(
                      padding: const EdgeInsets.all(36.0),
                      child: CircularProgressIndicator(color: activeColor, strokeWidth: 3),
                    )
                  : Icon(
                      isGranted ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      size: 50,
                      color: activeColor,
                    ),
            ),
          ),
          const SizedBox(height: 48),
          _StaggeredItem(
            index: 1,
            child: Text(
              "تفعيل الإشعارات",
              style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          _StaggeredItem(
            index: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                isGranted
                    ? "رائع! ستصلك إشعارات الأذان والأذكار في وقتها."
                    : "ابقَ على اتصال بصوت الأذان وأذكارك اليومية، واسمح لنا بتذكيرك بأوقات الصلاة.",
                key: ValueKey(isGranted),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 48),
          if (isDenied)
            _StaggeredItem(
              index: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "تم رفض الصلاحية. يمكنك تفعيلها لاحقاً من إعدادات النظام.",
                        style: GoogleFonts.cairo(color: Colors.redAccent.shade100, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _StaggeredItem(
            index: 4,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: isGranted || isRequesting ? null : _requestNotification,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: activeColor.withValues(alpha: 0.3), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: activeColor,
                  backgroundColor: isGranted ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: Text(
                  isGranted ? "تم التفعيل بنجاح" : "تفعيل الإشعارات",
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Page 4: Quran Page
// ---------------------------------------------------------
class _QuranPage extends StatelessWidget {
  const _QuranPage();

  Widget _buildRiwayaCard(
      BuildContext context, String title, String subtitle, String value, SettingsProvider settings) {
    final bool isSelected = settings.quranType == value;
    final primary = const Color(0xFFC5A059);

    return GestureDetector(
      onTap: () {
        VibrationService.triggerHaptic(settings, type: HapticType.selection);
        settings.setQuranType(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: primary, size: 20)
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.white38,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredItem(
            index: 0,
            child: Text("المصحف الشريف",
                style: GoogleFonts.cairo(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
          ),
          const SizedBox(height: 8),
          _StaggeredItem(
            index: 1,
            child: Text("بأي رواية تفضل القراءة؟",
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70)),
          ),
          const SizedBox(height: 40),
          _StaggeredItem(
            index: 2,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                _buildRiwayaCard(context, "حفص", "عن عاصم", "hafs", settings),
                _buildRiwayaCard(context, "ورش", "عن نافع", "warsh", settings),
                _buildRiwayaCard(context, "قالون", "عن نافع", "qaloun", settings),
                _buildRiwayaCard(context, "شعبة", "عن عاصم", "shuba", settings),
                _buildRiwayaCard(context, "السوسي", "عن أبي عمرو", "sousi", settings),
                _buildRiwayaCard(context, "الدوري", "عن أبي عمرو", "douri", settings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Page 5: Calendar Page
// ---------------------------------------------------------
class _CalendarPage extends StatelessWidget {
  const _CalendarPage();

  Widget _buildOptionCard(
      BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    final primary = const Color(0xFFC5A059);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isSelected ? primary : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final primary = const Color(0xFFC5A059);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StaggeredItem(
            index: 0,
            child: Text("إعدادات التقويم",
                style: GoogleFonts.cairo(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
          ),
          const SizedBox(height: 8),
          _StaggeredItem(
            index: 1,
            child: Text("اختر نمط التسمية وشكل الأرقام.",
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70)),
          ),
          const SizedBox(height: 40),
          _StaggeredItem(
            index: 2,
            child: Text("نظام الأرقام",
                style: GoogleFonts.cairo(color: primary, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _StaggeredItem(
            index: 3,
            child: Row(
              children: [
                Expanded(
                  child: _buildOptionCard(context, "١٢٣", settings.numberType == 'arabic', () {
                    VibrationService.triggerHaptic(settings, type: HapticType.selection);
                    settings.setNumberType('arabic');
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionCard(context, "123", settings.numberType == 'latin', () {
                    VibrationService.triggerHaptic(settings, type: HapticType.selection);
                    settings.setNumberType('latin');
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _StaggeredItem(
            index: 4,
            child: Text("الأشهر الميلادية",
                style: GoogleFonts.cairo(color: primary, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _StaggeredItem(
            index: 5,
            child: _buildOptionCard(context, "المشرقي (كانون الثاني، شباط...)",
                settings.gregorianMonthNaming == 'levantine', () {
              VibrationService.triggerHaptic(settings, type: HapticType.selection);
              settings.setGregorianMonthNaming('levantine');
            }),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(
            index: 6,
            child: _buildOptionCard(context, "المغاربي (يناير، فبراير...)",
                settings.gregorianMonthNaming == 'maghrebi', () {
              VibrationService.triggerHaptic(settings, type: HapticType.selection);
              settings.setGregorianMonthNaming('maghrebi');
            }),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(
            index: 7,
            child: _buildOptionCard(context, "القياسي (يناير، فبراير...)",
                settings.gregorianMonthNaming == 'standard', () {
              VibrationService.triggerHaptic(settings, type: HapticType.selection);
              settings.setGregorianMonthNaming('standard');
            }),
          ),
        ],
      ),
    );
  }
}
