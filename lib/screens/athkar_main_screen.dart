import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_colors.dart';
import '../services/hisn_muslim_service.dart';
import '../services/settings_provider.dart';
import '../services/vibration_service.dart';
import 'athkar_detail_screen.dart';
import 'adhkar_screen.dart'; // Legacy Athkar counter preserved

class AthkarMainScreen extends StatefulWidget {
  const AthkarMainScreen({super.key});

  @override
  State<AthkarMainScreen> createState() => _AthkarMainScreenState();
}

class _AthkarMainScreenState extends State<AthkarMainScreen> {
  late Future<List<HisnCategory>> _hisnFuture;
  String _searchQuery = '';
  String _activeTab = 'all';

  @override
  void initState() {
    super.initState();
    _hisnFuture = HisnMuslimService.loadHisnMuslim();
  }

  IconData _getCategoryIcon(String title) {
    if (title.contains('الصباح')) return Icons.wb_sunny_outlined;
    if (title.contains('المساء')) return Icons.nights_stay_outlined;
    if (title.contains('النوم') || title.contains('الاستيقاظ')) {
      return Icons.bedtime_outlined;
    }
    if (title.contains('الصلاة') ||
        title.contains('الوضوء') ||
        title.contains('المسجد')) {
      return Icons.mosque_outlined;
    }
    if (title.contains('الطعام') || title.contains('الشراب')) {
      return Icons.restaurant_outlined;
    }
    if (title.contains('السفر') || title.contains('الركوب')) {
      return Icons.directions_car_outlined;
    }
    if (title.contains('المرض') || title.contains('الجنازة')) {
      return Icons.health_and_safety_outlined;
    }
    if (title.contains('الخلاء') || title.contains('الثوب')) {
      return Icons.dry_cleaning_outlined;
    }
    return Icons.menu_book_rounded;
  }

  bool _matchesTab(String title, String tab) {
    if (tab == 'all') return true;
    if (tab == 'daily') {
      return title.contains('الصباح') ||
          title.contains('المساء') ||
          title.contains('النوم') ||
          title.contains('الاستيقاظ');
    }
    if (tab == 'prayer') {
      return title.contains('الصلاة') ||
          title.contains('الوضوء') ||
          title.contains('المسجد') ||
          title.contains('الأذان');
    }
    if (tab == 'doaa') {
      return title.contains('دعاء') ||
          title.contains('أدعية') ||
          title.contains('استغفار');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "حصن المسلم والأذكار",
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
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.cairo(fontSize: 14, color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: "ابحث في أذكار حصن المسلم...",
                    hintStyle:
                        GoogleFonts.cairo(fontSize: 13, color: c.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFFC5A059), size: 22),
                    filled: true,
                    fillColor: c.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? c.borderColor : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? c.borderColor : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFFC5A059), width: 1.4),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip("الكل", "all", settings),
                      const SizedBox(width: 8),
                      _buildFilterChip("الأذكار اليومية", "daily", settings),
                      const SizedBox(width: 8),
                      _buildFilterChip("الصلاة والوضوء", "prayer", settings),
                      const SizedBox(width: 8),
                      _buildFilterChip("الأدعية المأثورة", "doaa", settings),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Legacy Hassad Counter Shortcut Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: InkWell(
              onTap: () {
                VibrationService.triggerHaptic(settings,
                    type: HapticType.selection);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdhkarScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFFFFBEF), const Color(0xFFF7E8C9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Color(0xFFC5A059),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "عداد التسابيح والأذكار الحرة",
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            "سبح، كبر، واستغفر بحرية مع العداد الرقمي",
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFFC5A059),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Categories Grid
          Expanded(
            child: FutureBuilder<List<HisnCategory>>(
              future: _hisnFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC5A059)),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "تعذر تحميل بيانات حصن المسلم",
                      style: GoogleFonts.cairo(color: c.textMuted),
                    ),
                  );
                }

                final filtered = snapshot.data!.where((cat) {
                  final matchesQuery = _searchQuery.isEmpty ||
                      cat.title.contains(_searchQuery) ||
                      cat.items.any((item) => item.text.contains(_searchQuery));
                  final matchesTab = _matchesTab(cat.title, _activeTab);
                  return matchesQuery && matchesTab;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "لم يتم العثور على أذكار مطابقة",
                      style: GoogleFonts.cairo(color: c.textMuted),
                    ),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.02,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cat = filtered[index];
                    final icon = _getCategoryIcon(cat.title);

                    return InkWell(
                      onTap: () {
                        VibrationService.triggerHaptic(settings,
                            type: HapticType.selection);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AthkarDetailScreen(category: cat),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? c.borderColor
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.shadowColor,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC5A059)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon,
                                      color: const Color(0xFFC5A059), size: 22),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    settings
                                        .replaceDigits("${cat.items.length}"),
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              cat.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: c.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String value, SettingsProvider settings) {
    final isSelected = _activeTab == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFC5A059),
      backgroundColor: AppColors.of(context).cardBg,
      labelStyle: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.of(context).textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFFC5A059)
              : (AppColors.of(context).isDark
                  ? AppColors.of(context).borderColor
                  : const Color(0xFFE2E8F0)),
        ),
      ),
      onSelected: (_) {
        VibrationService.triggerHaptic(settings, type: HapticType.selection);
        setState(() => _activeTab = value);
      },
    );
  }
}
