import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For blur effects
import '../../services/settings_provider.dart';
import '../../services/arabic_plural_helper.dart';
import '../../services/vibration_service.dart';
import '../main_screen.dart';
import '../../constants/app_strings.dart';


class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

enum _LocationStepState { idle, requesting, granted, denied }

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  _LocationStepState _locationState = _LocationStepState.idle;
  String? _resolvedCity;
  final TextEditingController _nameController = TextEditingController();

  // ألوان البريميوم
  final Color _bgDark = const Color(0xFF0B1016);
  final Color _primary = const Color(0xFFC5A059);

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ استدعاء Settings هنا باش نطبقو الأرقام على Header
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _currentPage > 0 ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: _currentPage == 0,
                          child: InkWell(
                            onTap: () {
                              VibrationService.triggerHaptic(settings,
                                  type: HapticType.selection);
                              _goToPage(_currentPage - 1);
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // ✅ Dot progress indicator (more visual than text-only counter)
                      _buildDotIndicator(),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _AnimatedSetupPage(
                        pageKey: 'numerals',
                        child: _buildLanguagePage(settings),
                      ),
                      _AnimatedSetupPage(
                        pageKey: 'name',
                        child: _buildNamePage(settings),
                      ),
                      _AnimatedSetupPage(
                        pageKey: 'location',
                        child: _buildLocationPage(settings),
                      ),
                      _AnimatedSetupPage(
                        pageKey: 'goals',
                        child: _buildGoalsPage(settings),
                      ),
                      _AnimatedSetupPage(
                        pageKey: 'quran',
                        child: _buildQuranPage(settings),
                      ),
                    ],
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        VibrationService.triggerHaptic(settings,
                            type: HapticType.medium);
                        if (_currentPage < _totalPages - 1) {
                          _goToPage(_currentPage + 1);
                        } else {
                          _finishSetup();
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _currentPage == _totalPages - 1
                              ? "ابدأ الرحلة"
                              : "متابعة",
                          key: ValueKey(_currentPage == _totalPages - 1),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildDotIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalPages, (index) {
        final bool isActive = index == _currentPage;
        final bool isPast = index < _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive || isPast
                ? _primary
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // --- Pages ---

  Widget _buildLanguagePage(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("مرحباً بك",
              style: GoogleFonts.cairo(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2)),
          const SizedBox(height: 10),
          Text("اختر شكل الأرقام المفضل لديك في التطبيق.",
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.white54)),
          const SizedBox(height: 50),
          Text("نظام الأرقام",
              style: GoogleFonts.cairo(
                  color: _primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildOptionItem(
                      "١٢٣",
                      settings.numberType == 'arabic',
                      () => _selectNumberType(settings, 'arabic'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildOptionItem(
                      "123",
                      settings.numberType == 'latin',
                      () => _selectNumberType(settings, 'latin'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("نتشرف بمعرفتك",
              style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2)),
          const SizedBox(height: 10),
          Text("كيف تحب أن نناديك؟",
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.white54)),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: "مثال: محسن",
              hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 18),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _primary),
              ),
              prefixIcon: Icon(Icons.person_outline_rounded, color: _primary),
            ),
          ),
        ],
      ),
    );
  }

  void _selectNumberType(SettingsProvider settings, String type) {
    VibrationService.triggerHaptic(settings, type: HapticType.selection);
    settings.setNumberType(type);
  }

  Widget _buildLocationPage(SettingsProvider settings) {
    final bool isGranted = _locationState == _LocationStepState.granted;
    final bool isDenied = _locationState == _LocationStepState.denied;
    final bool isRequesting = _locationState == _LocationStepState.requesting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: (isGranted ? Colors.greenAccent : _primary)
                        .withValues(alpha: 0.3),
                    width: 1),
                color: (isGranted ? Colors.greenAccent : _primary)
                    .withValues(alpha: 0.1)),
            child: isRequesting
                ? Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: CircularProgressIndicator(
                      color: _primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(
                    isGranted
                        ? Icons.check_circle_rounded
                        : Icons.near_me_rounded,
                    size: 40,
                    color: isGranted ? Colors.greenAccent : _primary,
                  ),
          ),
          const SizedBox(height: 40),
          Text("تحديد الموقع",
              style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          Text(
              isGranted
                  ? (_resolvedCity != null
                      ? "يسعدنا تواجدك معنا في مدينة $_resolvedCity، سنقوم بحساب مواقيت الصلاة واتجاه القبلة بدقة لأجلك"
                      : "تم منح صلاحية الموقع بنجاح! سنحسب أوقات الصلاة واتجاه القبلة بدقة متناهية حسب منطقتك.")
                  : "نحتاج إلى تفعيل الموقع لحساب أوقات الصلاة واتجاه القبلة بدقة متناهية حسب منطقتك — تُحسب بالكامل بدون إنترنت.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 16, color: Colors.white54, height: 1.6)),
          const SizedBox(height: 40),
          if (isDenied) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "تم رفض الصلاحية. يمكنك المتابعة وتفعيلها لاحقاً من الإعدادات.",
                      style: GoogleFonts.cairo(
                          color: Colors.redAccent.shade100, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isGranted || isRequesting
                  ? null
                  : () async {
                      VibrationService.triggerHaptic(settings,
                          type: HapticType.light);
                      setState(() => _locationState =
                          _LocationStepState.requesting);
                      LocationPermission permission =
                          await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                      }
                      if (!mounted) return;
                      final granted =
                          permission == LocationPermission.always ||
                              permission == LocationPermission.whileInUse;
                      setState(() {
                        _locationState = granted
                            ? _LocationStepState.granted
                            : _LocationStepState.denied;
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
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(position.latitude, position.longitude)
                                  .timeout(const Duration(seconds: 3));
                          if (placemarks.isNotEmpty) {
                            final p = placemarks.first;
                            String? extractedCity = p.locality;
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
                        } catch (_) {
                          // Ignore geocoding failure during setup, will fallback gracefully
                        }

                        VibrationService.triggerHaptic(settings,
                            type: HapticType.medium);
                        await Future.delayed(
                            const Duration(milliseconds: 1500));
                        if (mounted) _goToPage(_currentPage + 1);
                      }
                    },
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                      color: (isGranted ? Colors.greenAccent : Colors.white)
                          .withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor:
                      isGranted ? Colors.greenAccent : Colors.white),
              child: Text(
                  isGranted
                      ? "تم منح الصلاحية ✓"
                      : (isDenied ? AppStrings.retry : "منح الصلاحية"),

                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGoalsPage(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("وردك اليومي",
              style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text("حدد هدفك لنساعدك على الالتزام.",
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.white54)),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("القرآن الكريم",
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                // ✅ تطبيق الأرقام على عدد الأحزاب
                child: Text(
                    settings.replaceDigits(
                        ArabicPluralHelper.formatHizb(settings.dailyHizbGoal)),
                    style: GoogleFonts.cairo(
                        color: _primary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
                activeTrackColor: _primary,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
                overlayColor: _primary.withValues(alpha: 0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
            child: Slider(
              value: settings.dailyHizbGoal.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                VibrationService.triggerHaptic(settings,
                    type: HapticType.selection);
                settings.updateGoals(hizb: val.toInt());
              },
            ),
          ),
          const SizedBox(height: 40),
          _buildMinimalSwitch(settings, "تذكير أذكار الصباح",
              settings.remindAdhkarSabah, (v) => settings.updateGoals(sabah: v)),
          const SizedBox(height: 15),
          _buildMinimalSwitch(settings, "تذكير أذكار المساء",
              settings.remindAdhkarMasaa, (v) => settings.updateGoals(masaa: v)),
        ],
      ),
    );
  }

  Widget _buildQuranPage(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("المصحف الشريف",
              style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text("بأي رواية تفضل القراءة؟",
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.white54)),
          const SizedBox(height: 30),

          // ✅ القائمة الكاملة للروايات (6 روايات)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildRiwayaChip("حفص", "عن عاصم", "hafs", settings),
              _buildRiwayaChip("ورش", "عن نافع", "warsh", settings),
              _buildRiwayaChip("قالون", "عن نافع", "qaloun", settings),
              _buildRiwayaChip("شعبة", "عن عاصم", "shuba", settings),
              _buildRiwayaChip("السوسي", "عن أبي عمرو", "sousi", settings),
              _buildRiwayaChip("الدوري", "عن أبي عمرو", "douri", settings),
            ],
          ),
        ],
      ),
    );
  }

  // --- Components ---

  Widget _buildOptionItem(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
            color: isSelected
                ? _primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
                color: isSelected ? _primary : Colors.white10, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(title,
            style: GoogleFonts.cairo(
                color: isSelected ? _primary : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRiwayaChip(
      String title, String subtitle, String value, SettingsProvider settings) {
    bool isSelected = settings.quranType == value;
    double width = (MediaQuery.of(context).size.width - 48 - 12) / 2;

    return GestureDetector(
      onTap: () {
        VibrationService.triggerHaptic(settings, type: HapticType.selection);
        settings.setQuranType(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? _primary : Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.cairo(
                    color: isSelected ? Colors.white : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.2)),
            Text(subtitle,
                style: GoogleFonts.cairo(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white38,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalSwitch(SettingsProvider settings, String title,
      bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16)),
        Switch(
            value: value,
            onChanged: (v) {
              VibrationService.triggerHaptic(settings,
                  type: HapticType.selection);
              onChanged(v);
            },
            activeThumbColor: _bgDark,
            activeTrackColor: _primary,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10)
      ],
    );
  }

  void _finishSetup() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_nameController.text.trim().isNotEmpty) {
      await settings.setUserName(_nameController.text.trim());
    }
    await settings.completeSetup();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MainScreen()));
    }
  }
}

/// ✅ Subtle fade + slide-up entrance animation wrapper for each setup page,
/// giving the onboarding flow a more premium, polished feel as the user
/// swipes between steps instead of an abrupt page cut.
class _AnimatedSetupPage extends StatelessWidget {
  final String pageKey;
  final Widget child;

  const _AnimatedSetupPage({required this.pageKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(pageKey),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 24),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
