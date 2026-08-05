import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For blur effects
import '../../services/settings_provider.dart';
import '../../services/arabic_plural_helper.dart';
import '../main_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ألوان البريميوم
  final Color _bgDark = const Color(0xFF0B1016);
  final Color _primary = const Color(0xFFC5A059);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings هنا باش نطبقو الأرقام على Header
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
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        InkWell(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutQuart,
                            );
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
                        )
                      else
                        const SizedBox(width: 40),

                      const Spacer(),
                      // ✅ 2. تطبيق الأرقام على العداد (الخطوة 1 من 4)
                      Text(
                        "الخطوة ${settings.replaceDigits('${_currentPage + 1}')} من ${settings.replaceDigits('4')}",
                        style: GoogleFonts.cairo(
                          color: Colors.white30,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
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
                      _buildLanguagePage(settings),
                      _buildLocationPage(),
                      _buildGoalsPage(settings),
                      _buildQuranPage(settings),
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
                        if (_currentPage < 3) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuart,
                          );
                        } else {
                          _finishSetup();
                        }
                      },
                      child: Text(
                        _currentPage == 3 ? "ابدأ الرحلة" : "متابعة",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
          Text("الأرقام",

              style: GoogleFonts.cairo(
                  color: _primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildOptionItem(
                      "١٢٣",
                      settings.numberType == 'arabic',
                      () => settings.setNumberType('arabic'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildOptionItem("123", settings.numberType == 'latin',
                      () => settings.setNumberType('latin'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _primary.withValues(alpha: 0.3), width: 1),
                color: _primary.withValues(alpha: 0.1)),
            child: Icon(Icons.near_me_rounded, size: 40, color: _primary),
          ),
          const SizedBox(height: 40),
          Text("تحديد الموقع",
              style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          Text(
              "نحتاج إلى تفعيل الموقع لحساب أوقات الصلاة واتجاه القبلة بدقة متناهية حسب منطقتك.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 16, color: Colors.white54, height: 1.6)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Geolocator.requestPermission();
              },
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: Colors.white),
              child: Text("منح الصلاحية",
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
                // ✅ 3. تطبيق الأرقام على عدد الأحزاب
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
              onChanged: (val) => settings.updateGoals(hizb: val.toInt()),
            ),
          ),
          const SizedBox(height: 40),
          _buildMinimalSwitch("تذكير أذكار الصباح", settings.remindAdhkarSabah,
              (v) => settings.updateGoals(sabah: v)),
          const SizedBox(height: 15),
          _buildMinimalSwitch("تذكير أذكار المساء", settings.remindAdhkarMasaa,
              (v) => settings.updateGoals(masaa: v)),
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

          // ✅ 4. القائمة الكاملة للروايات (6 روايات)
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
      onTap: () => settings.setQuranType(value),
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

  Widget _buildMinimalSwitch(
      String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16)),
        Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _bgDark,
            activeTrackColor: _primary,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10)
      ],
    );
  }

  void _finishSetup() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.completeSetup();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MainScreen()));
    }
  }
}
