import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../services/settings_provider.dart';
import 'settings_screen.dart';
import 'quran_reading_screen.dart';
import 'quran_search_screen.dart';
import 'khatm_doaa_screen.dart'; // ✅ Import new screen
import '../services/app_colors.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<Map<String, dynamic>> allSurahs = [];
  Map<String, dynamic>? _lastBookmark;
  Map<String, dynamic>? _lastRead;
  bool _isLoading = true;
  bool _hasError = false;

  // Colors
  final Color _primaryColor = const Color(0xFFC5A059);
  final Color _makkiColor = const Color(0xFF8D6E63); // Brown
  final Color _madaniColor = const Color(0xFFC5A059); // Green

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final bookmark = await StorageService.getBookmark();
      final read = await StorageService.getLastRead();

      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        await QuranService.loadQuran(settings.currentJsonPath);
      }
      var surahs = QuranService.getAllSurahs();

      if (mounted) {
        setState(() {
          _lastBookmark = bookmark;
          _lastRead = read;
          allSurahs = surahs;
          _isLoading = false;
          _hasError = surahs.isEmpty;
        });
      }
    } catch (e) {
      debugPrint("Error loading Quran data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _openLastRead() async {
    final lastReadData = await StorageService.getLastRead();

    if (!mounted) return;

    if (lastReadData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuranReadingScreen(
            initialSurahId: lastReadData['surah_id'],
            initialPageIndex: lastReadData['page_index'],
          ),
        ),
      ).then((_) => _loadData());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QuranReadingScreen(
            initialSurahId: 1,
            initialPageIndex: 0,
          ),
        ),
      ).then((_) => _loadData());
    }
  }

  void _openSurah(int id, {int pageIndex = -1}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReadingScreen(
          initialSurahId: id,
          initialPageIndex: pageIndex,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings Provider
    final settings = Provider.of<SettingsProvider>(context);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "المصحف الشريف",
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: _primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.cardBg,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.shadowColor, blurRadius: 5)],
            ),
            child: Icon(Icons.search, color: _primaryColor),
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.cardBg,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: c.shadowColor, blurRadius: 5)],
              ),
              child: Icon(Icons.settings, color: _primaryColor),
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- 1. TOP CARDS (Bookmark & Last Read) ---
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "آخر قراءة",
                    subtitle: "سورة ${_lastRead?['surah_name'] ?? 'الفاتحة'}",
                    icon: Icons.history_edu,
                    color: const Color(0xFF3B82F6),
                    onTap: _openLastRead,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInfoCard(
                    title: "المرجع المحفوظ",
                    subtitle: _lastBookmark != null
                        ? "سورة ${_lastBookmark!['surah_name']}"
                        : "لا يوجد",
                    icon: Icons.bookmark,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      if (_lastBookmark != null) {
                        _openSurah(_lastBookmark!['surah_id'],
                            pageIndex: (_lastBookmark!['page_index'] as double)
                                .toInt());
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- 2. SURAHS LIST (Line by Line) ---
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor))
                  : _hasError || allSurahs.isEmpty
                      ? _buildErrorRetry(context)
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                              bottom: kBottomNavigationBarHeight + 40),
                          // ✅ نزيدو 1 باش يبان دعاء الختم في اللخر
                          itemCount: allSurahs.length + 1,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            // ✅ إيلا كان العنصر اللخر، هو دعاء الختم
                            if (index == allSurahs.length) {
                              return _buildKhatmDoaaTile();
                            }

                            final surah = allSurahs[index];
                            return _buildSurahListTile(surah, settings);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.amiri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ استقبال SettingsProvider كبارامتر
  Widget _buildSurahListTile(
      Map<String, dynamic> surah, SettingsProvider settings) {
    bool isMakkiya = (surah['type'] == 'Makki' || surah['type'] == 'مكية');
    String typeText = isMakkiya ? "مكية" : "مدنية";
    Color typeColor = isMakkiya ? _makkiColor : _madaniColor;
    IconData typeIcon = isMakkiya ? Icons.location_city : Icons.mosque;
    final c = AppColors.of(context);

    return GestureDetector(
      onTap: () => _openSurah(surah['id']),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: c.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // 1. الرقم (Number)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  // ✅ 2. تطبيق replaceDigits على رقم السورة
                  settings.replaceDigits("${surah['id']}"),
                  style: GoogleFonts.cairo(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // 2. الاسم (Names)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "سورة ${surah['name_ar']}",
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surah['name_en'],
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // 3. النوع (Type Badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: typeColor.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(typeIcon, size: 12, color: typeColor),
                  const SizedBox(width: 5),
                  Text(
                    typeText,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKhatmDoaaTile() {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KhatmDoaaScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: c.isDark
              ? c.cardBg
              : const Color(0xFFF59E0B)
                  .withValues(alpha: 0.1), // Gold/Orange tint
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: c.isDark
                  ? c.borderColor
                  : const Color(0xFFF59E0B).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(width: 15),

            // Text
            Expanded(
              child: Text(
                "دعاء ختم القرآن الكريم",
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.isDark
                      ? c.goldAccent
                      : const Color(0xFFB45309), // Darker orange/brown
                ),
              ),
            ),

            // Arrow
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorRetry(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text("تعذر تحميل السور",
              style: GoogleFonts.cairo(color: c.textPrimary, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text("إعادة المحاولة",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
