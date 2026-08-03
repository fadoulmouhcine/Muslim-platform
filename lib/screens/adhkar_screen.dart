import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../models/adhkar_data.dart';
import 'adhkar_detail_screen.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  // قائمة فئات الأذكار (ثابتة)
  final List<Map<String, dynamic>> _categories = const [
    {
      "title": "أذكار الصباح",
      "icon": Icons.wb_sunny_rounded,
      "color1": Color(0xFFFF9A9E),
      "color2": Color(0xFFFECFEF),
    },
    {
      "title": "أذكار المساء",
      "icon": Icons.nights_stay_rounded,
      "color1": Color(0xFF667EEA),
      "color2": Color(0xFF764BA2),
    },
    {
      "title": "أذكار النوم",
      "icon": Icons.bed_rounded,
      "color1": Color(0xFF2E3192),
      "color2": Color(0xFF1BFFFF),
    },
    {
      "title": "أذكار الاستيقاظ",
      "icon": Icons.wb_twilight_rounded,
      "color1": Color(0xFFD4FC79),
      "color2": Color(0xFF96E6A1),
    },
    {
      "title": "أذكار الصلاة",
      "icon": Icons.mosque_rounded,
      "color1": Color(0xFF43E97B),
      "color2": Color(0xFF38F9D7),
    },
    {
      "title": "أذكار الوضوء",
      "icon": Icons.water_drop_rounded,
      "color1": Color(0xFF4FACFE),
      "color2": Color(0xFF00F2FE),
    },
    {
      "title": "أذكار المسجد",
      "icon": Icons.account_balance_rounded,
      "color1": Color(0xFFFA709A),
      "color2": Color(0xFFFEE140),
    },
    {
      "title": "أدعية قرآنية",
      "icon": Icons.menu_book_rounded,
      "color1": Color(0xFF0BA360),
      "color2": Color(0xFF3CBA92),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings Provider
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "الأذكار والأدعية",
          style: GoogleFonts.amiri(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
            20, 20, 20, kBottomNavigationBarHeight + 40),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cards per row
          childAspectRatio: 1.1,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];

          // نجيبو عدد الأذكار من AdhkarData باش نعرضوه
          int count = AdhkarData.getAdhkarByCategory(cat['title']).length;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(50 * (1 - value), 0), // RTL Slide from Right
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildAdhkarCard(
              context,
              cat['title'],
              cat['icon'],
              cat['color1'],
              cat['color2'],
              count,
              settings,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdhkarCard(
    BuildContext context,
    String title,
    IconData icon,
    Color c1,
    Color c2,
    int count,
    SettingsProvider settings,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdhkarDetailScreen(categoryTitle: title),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: c1.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Icon (Watermark)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          // ✅ تحويل الرقم (عدد الأذكار)
                          "${settings.replaceDigits(count.toString())} ذكر",
                          style: GoogleFonts.cairo(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
