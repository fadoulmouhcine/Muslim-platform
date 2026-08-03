import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_colors.dart';
import '../services/settings_provider.dart';
import 'sunnah_chapters_screen.dart';

class SunnahScreen extends StatelessWidget {
  const SunnahScreen({super.key});

  // ==========================================================
  // 1. DATA (L-Ktouba Kamlin)
  // ==========================================================
  final List<Map<String, dynamic>> kutubSitta = const [
    {
      "title": "صحيح البخاري",
      "author": "الإمام البخاري",
      "count": 7563,
      "color": Color(0xFF064E3B),
      "file": "bukhari.json"
    },
    {
      "title": "صحيح مسلم",
      "author": "الإمام مسلم",
      "count": 7459,
      "color": Color(0xFF065F46),
      "file": "muslim.json"
    },
    {
      "title": "جامع الترمذي",
      "author": "الإمام الترمذي",
      "count": 4053,
      "color": Color(0xFF1E3A8A),
      "file": "tirmidhi.json"
    },
    {
      "title": "سنن أبي داود",
      "author": "أبو داود",
      "count": 5276,
      "color": Color(0xFF1E40AF),
      "file": "abudawud.json"
    },
    {
      "title": "سنن النسائي",
      "author": "الإمام النسائي",
      "count": 5768,
      "color": Color(0xFF1E3A8A),
      "file": "nasai.json"
    },
    {
      "title": "سنن ابن ماجه",
      "author": "ابن ماجه",
      "count": 4345,
      "color": Color(0xFF1E40AF),
      "file": "ibnmajah.json"
    },
  ];

  final List<Map<String, dynamic>> asanid = const [
    {
      "title": "موطأ مالك",
      "author": "الإمام مالك",
      "count": 1985,
      "color": Color(0xFF451A03),
      "file": "malik.json"
    },
    {
      "title": "مسند أحمد",
      "author": "الإمام أحمد",
      "count": 28000,
      "color": Color(0xFF78350F),
      "file": "ahmed.json"
    },
    {
      "title": "سنن الدارمي",
      "author": "الإمام الدارمي",
      "count": 3406,
      "color": Color(0xFF78350F),
      "file": "darimi.json"
    },
  ];

  final List<Map<String, dynamic>> jawami = const [
    {
      "title": "رياض الصالحين",
      "author": "الإمام النووي",
      "count": 1896,
      "color": Color(0xFF581C87),
      "file": "riyad_assalihin.json"
    },
    {
      "title": "مشكاة المصابيح",
      "author": "التبريزي",
      "count": 6294,
      "color": Color(0xFF6D28D9),
      "file": "mishkat_almasabih.json"
    },
    {
      "title": "بلوغ المرام",
      "author": "ابن حجر",
      "count": 1596,
      "color": Color(0xFF7C3AED),
      "file": "bulugh_almaram.json"
    },
    {
      "title": "الأدب المفرد",
      "author": "الإمام البخاري",
      "count": 1326,
      "color": Color(0xFF4C1D95),
      "file": "aladab_almufrad.json"
    },
    {
      "title": "الشمائل المحمدية",
      "author": "الإمام الترمذي",
      "count": 402,
      "color": Color(0xFFBE185D),
      "file": "shamail_muhammadiyah.json"
    },
  ];

  final List<Map<String, dynamic>> mukhtasarat = const [
    {
      "title": "الأحاديث القدسية",
      "author": "الأربعون",
      "count": 40,
      "color": Color(0xFFB45309),
      "file": "qudsi40.json"
    },
    {
      "title": "حصن المسلم",
      "author": "القحطاني",
      "count": 260,
      "color": Color(0xFFD97706),
      "file": "hisn_almuslim.json"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    // Check Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque, color: Color(0xFFC5A059)),
            const SizedBox(width: 10),
            Text(
              "خزانة السنة",
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 1. HERO SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHeroSection(),
            ),

            const SizedBox(height: 30),

            // 2. SHELVES
            _buildLibraryShelfTitle("الكتب الستة", textColor),
            _buildWoodShelf(context, kutubSitta, settings),

            const SizedBox(height: 20),

            _buildLibraryShelfTitle("المسانيد والموطآت", textColor),
            _buildWoodShelf(context, asanid, settings),

            const SizedBox(height: 20),

            _buildLibraryShelfTitle("الجوامع والأخلاق", textColor),
            _buildWoodShelf(context, jawami, settings),

            const SizedBox(height: 20),

            _buildLibraryShelfTitle("المختصرات والأذكار", textColor),
            _buildWoodShelf(context, mukhtasarat, settings),

            const SizedBox(height: kBottomNavigationBarHeight + 40),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // WIDGETS
  // ==========================================================

  Widget _buildLibraryShelfTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWoodShelf(BuildContext context, List<Map<String, dynamic>> books,
      SettingsProvider settings) {
    final c = AppColors.of(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 1. THE WOOD SHELF (Background)
        Container(
          margin: const EdgeInsets.only(top: 20),
          height: 15,
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.sunnahShelfWood,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
            gradient: LinearGradient(
              colors: [
                c.sunnahShelfWood.withValues(alpha: 0.7),
                c.sunnahShelfWood,
                c.sunnahShelfWood.withValues(alpha: 0.7)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),

        // 2. THE BOOKS ON THE SHELF
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _buildRealBook(context, books[index], settings);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRealBook(BuildContext context, Map<String, dynamic> book,
      SettingsProvider settings) {
    // ✅ M-04 FIX: Adapt book color brightness for Dark Mode.
    // Dark book covers (deep greens, blues, browns) become near-invisible on dark bg.
    // We brighten them in dark mode so text/badges remain readable.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color rawColor = book['color'] as Color;
    final Color bookColor = isDark
        ? HSLColor.fromColor(rawColor).withLightness(0.60).toColor()
        : rawColor;

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SunnahChaptersScreen(bookInfo: book),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            // 1. GRADIENT (JILD)
            gradient: LinearGradient(
              colors: [
                bookColor.withValues(alpha: 0.8), // Spine
                bookColor, // Face
                bookColor.withValues(alpha: 0.9), // Edge
              ],
              stops: const [0.0, 0.12, 1.0],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
              topLeft: Radius.circular(2),
              bottomLeft: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(-4, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 2. SPINE LINES
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Container(
                    width: 2,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Container(
                    width: 1,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
              ),

              // 3. BACKGROUND PATTERN
              Positioned(
                top: -20,
                left: -20,
                child: Icon(
                  Icons.star_border_purple500_outlined,
                  size: 100,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),

              // 4. GOLD FRAME (العنوان)
              Positioned(
                top: 30,
                bottom: 50, // ✅ عطينا التيساع لتحت باش الكتابة ماتجيش مزحومة
                left: 12,
                right: 22,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        book['title'],
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.arefRuqaa(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 5. AUTHOR NAME (بوحدو ومقاد لتحت)
              Positioned(
                bottom: 15, // ✅ بلاصة نقية لتحت
                left: 10,
                right: 20,
                child: Center(
                  // ✅ الوسط
                  child: Text(
                    book['author'],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11, // صغرنا شوية باش تجي أنيقة
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "حديث اليوم",
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "«إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ»",
                  style: GoogleFonts.amiri(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "رواه البخاري ومسلم",
                  style: GoogleFonts.cairo(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bookmark_border,
                color: Colors.white, size: 30),
          )
        ],
      ),
    );
  }
}
