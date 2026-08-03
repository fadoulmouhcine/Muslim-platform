import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_colors.dart';
import '../services/settings_provider.dart';
import '../services/vibration_service.dart';
import 'quran_reading_screen.dart';

class FridayHubScreen extends StatefulWidget {
  const FridayHubScreen({super.key});

  @override
  State<FridayHubScreen> createState() => _FridayHubScreenState();
}

class _FridayHubScreenState extends State<FridayHubScreen> {
  int _salawatCount = 0;
  final Set<int> _completedSunnahs = {};

  @override
  void initState() {
    super.initState();
    _loadSalawatAndSunnahs();
  }

  Future<void> _loadSalawatAndSunnahs() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final count = prefs.getInt('friday_salawat_$todayStr') ?? 0;

    final completedList = prefs.getStringList('friday_sunnahs_$todayStr') ?? [];
    final set = completedList.map((e) => int.tryParse(e) ?? -1).toSet();

    setState(() {
      _salawatCount = count;
      _completedSunnahs.clear();
      _completedSunnahs.addAll(set.where((e) => e >= 0));
    });
  }

  Future<void> _incrementSalawat(SettingsProvider settings) async {
    VibrationService.triggerHaptic(settings, type: HapticType.medium);
    setState(() {
      _salawatCount++;
    });

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt('friday_salawat_$todayStr', _salawatCount);

    if (_salawatCount == 100 || _salawatCount == 300 || _salawatCount == 1000) {
      if (mounted) {
        VibrationService.triggerHaptic(settings, type: HapticType.heavy);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "ما شاء الله! وصلت إلى $_salawatCount صلاة على النبي ﷺ 🌸",
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFC5A059),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleSunnah(int index, SettingsProvider settings) async {
    VibrationService.triggerHaptic(settings, type: HapticType.selection);
    setState(() {
      if (_completedSunnahs.contains(index)) {
        _completedSunnahs.remove(index);
      } else {
        _completedSunnahs.add(index);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final strList = _completedSunnahs.map((e) => e.toString()).toList();
    await prefs.setStringList('friday_sunnahs_$todayStr', strList);
  }

  void _openSurahAlKahf() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.selection);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuranReadingScreen(
          initialSurahId: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;
    final settings = Provider.of<SettingsProvider>(context);

    final sunnahItems = [
      {
        "icon": Icons.bathtub_outlined,
        "title": "الاغتسال والتطيب",
        "desc": "من سنن الجمعة المؤكدة للرجال والنساء"
      },
      {
        "icon": Icons.dry_cleaning_outlined,
        "title": "لبس أفضل الثياب",
        "desc": "التجمل لحضور صلاة الجمعة والاجتماع"
      },
      {
        "icon": Icons.clean_hands_outlined,
        "title": "استعمال السواك",
        "desc": "تطهير الفم وتطيب الرائحة"
      },
      {
        "icon": Icons.directions_walk_outlined,
        "title": "التبكير للمسجد",
        "desc": "المشي بسكينة والتبكير للحصول على الأجر"
      },
      {
        "icon": Icons.menu_book_rounded,
        "title": "قراءة سورة الكهف",
        "desc": "نورٌ للمؤمن ما بين الجمعتين"
      },
      {
        "icon": Icons.favorite_border_rounded,
        "title": "كثرة الصلاة على النبي ﷺ",
        "desc": "تُعرض صلاتك عليه ﷺ في هذا اليوم"
      },
      {
        "icon": Icons.access_time_rounded,
        "title": "الدعاء في ساعة الاستجابة",
        "desc": "آخر ساعة بعد العصر قبل غروب الشمس"
      },
    ];

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "ملتقى الجمعة المباركة",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. FRIDAY HERO BANNER ─────────────────────────────────────────
            _buildFridayHeroBanner(isDark),

            const SizedBox(height: 12),

            // ── 2. SHORTCUT: READ SURAH AL-KAHF ──────────────────────────────
            _buildKahfShortcutCard(context, isDark),

            const SizedBox(height: 12),

            // ── 3. SALAWAT COUNTER CARD ───────────────────────────────────────
            _buildSalawatCounterCard(context, isDark, settings),

            const SizedBox(height: 16),

            // ── 4. FRIDAY SUNNAHS CHECKLIST ───────────────────────────────────
            Text(
              "سنن يوم الجمعة المبارك",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "حافظ على تطبيق السنن واكسب أجر يوم الجمعة كاملًا",
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sunnahItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = sunnahItems[index];
                final isDone = _completedSunnahs.contains(index);

                return InkWell(
                  onTap: () => _toggleSunnah(index, settings),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFFC5A059)
                              .withValues(alpha: isDark ? 0.15 : 0.08)
                          : c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFFC5A059).withValues(alpha: 0.5)
                            : (isDark
                                ? c.borderColor
                                : const Color(0xFFE2E8F0)),
                        width: isDone ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFC5A059).withValues(alpha: 0.2)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color:
                                isDone ? const Color(0xFFC5A059) : c.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDone
                                      ? const Color(0xFFC5A059)
                                      : c.textPrimary,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                item['desc'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: isDone,
                          activeColor: const Color(0xFFC5A059),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          onChanged: (_) => _toggleSunnah(index, settings),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── 5. HOUR OF RESPONSE BANNER ───────────────────────────────────
            _buildHourOfResponseCard(isDark),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── FRIDAY HERO BANNER ──────────────────────────────────────────────────
  Widget _buildFridayHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0A2B1E),
                  const Color(0xFF134532),
                  const Color(0xFF0A2B1E)
                ]
              : [
                  const Color(0xFF1B3B2B),
                  const Color(0xFF2E5B45),
                  const Color(0xFF1B3B2B)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A059).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFC5A059),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "جمعة مباركة طيّبة 🌿",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFFC5A059),
                    ),
                  ),
                  Text(
                    "خير يوم طلعت عليه الشمس",
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0x33C5A059), height: 1),
          ),
          Text(
            "﴿إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا﴾",
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── SURAH AL-KAHF SHORTCUT CARD ───────────────────────────────────────────
  Widget _buildKahfShortcutCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFC5A059).withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A059).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFC5A059),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "سورة الكهف",
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                Text(
                  "نور ما بين الجمعتين 📖",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A059),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            onPressed: _openSurahAlKahf,
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: Text(
              "قراءة الآن",
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SALAWAT COUNTER CARD ──────────────────────────────────────────────────
  Widget _buildSalawatCounterCard(
      BuildContext context, bool isDark, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B18), const Color(0xFF28231C)]
              : [const Color(0xFFFFFBEF), const Color(0xFFFAF0D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFE11D48), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "عداد الصلاة على النبي ﷺ",
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Color(0xFFC5A059), size: 20),
                onPressed: () async {
                  VibrationService.triggerHaptic(settings,
                      type: HapticType.selection);
                  setState(() => _salawatCount = 0);
                  final prefs = await SharedPreferences.getInstance();
                  final todayStr =
                      DateTime.now().toIso8601String().substring(0, 10);
                  await prefs.setInt('friday_salawat_$todayStr', 0);
                },
                tooltip: "تصفير العداد",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            settings.replaceDigits(_salawatCount.toString()),
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC5A059),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: () => _incrementSalawat(settings),
              child: Text(
                "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد 🌸",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HOUR OF RESPONSE CARD ─────────────────────────────────────────────────
  Widget _buildHourOfResponseCard(bool isDark) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.responseCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.responseCardBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.responseCardText.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_filled_rounded,
              color: c.responseCardText,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ساعة الاستجابة في يوم الجمعة",
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.responseCardText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "«فِيهِ سَاعَةٌ لا يُوَافِقُهَا عَبْدٌ مُسْلِمٌ يَدْعُو اللَّهَ إِلَّا أَعْطَاهُ إِيَّاهُ» - أرجى الأوقات بعد العصر حتى غروب الشمس.",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.of(context).textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
