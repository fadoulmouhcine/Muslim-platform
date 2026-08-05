import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart'; // ✅ ضروري
import '../services/settings_provider.dart'; // ✅ ضروري
import '../services/sunnah_service.dart';
import '../constants/app_strings.dart';


class SunnahReadingScreen extends StatelessWidget {
  final Chapter chapter;
  final List<Hadith> hadiths;
  final Color bookColor;
  final String bookTitle;

  const SunnahReadingScreen({
    super.key,
    required this.chapter,
    required this.hadiths,
    required this.bookColor,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings Provider
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real Book Theme Colors
    final bgColor =
        isDark ? Colors.black : const Color(0xFFFFFDF5); // Creamy Paper Color

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          chapter.arabicTitle,
          style: GoogleFonts.amiri(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: bookColor),
            onPressed: () {
              // Optional: Share chapter title logic
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Texture Overlay (Optional)
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.01 : 0.03,
              child: Image.asset(
                'assets/images/basmala.png',
                repeat: ImageRepeat.repeat,
                color: isDark ? Colors.white : null,
                errorBuilder: (c, o, s) => const SizedBox(),
              ),
            ),
          ),

          ListView.builder(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 40),
            itemCount: hadiths.length,
            itemBuilder: (context, index) {
              // ✅ تمرير settings للويدجت
              return _buildPremiumHadithCard(context, hadiths[index], settings);
            },
          ),
        ],
      ),
    );
  }

  // ✅ استقبال SettingsProvider كبارامتر
  Widget _buildPremiumHadithCard(
      BuildContext context, Hadith hadith, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE2E8F0),
            width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFFB45309)
                    .withValues(alpha: 0.05), // Warm Gold Shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header (Number & Metadata)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: bookColor.withValues(alpha: isDark ? 0.15 : 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hadith Number Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: bookColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    // ✅ 2. تحويل رقم الحديث
                    "رقم ${settings.replaceDigits(hadith.idInBook.toString())}",
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // Book Title (Watermark style)
                Text(
                  bookTitle,
                  style: GoogleFonts.arefRuqaa(
                      color: bookColor.withValues(alpha: isDark ? 0.7 : 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 2. Arabic Text (ONLY ARABIC NOW)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 30, 20, 30), // Zidna padding hit hayedna english
            child: Text(
              hadith.arabicText,
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 22, // Readable Size
                height: 2.2, // Comfortable line height for Arabic
                color: isDark ? Colors.white : const Color(0xFF1A202C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ❌ REMOVED: English Text & Narrator (Translation Disabled)

          // 3. Actions Footer (Copy/Share - Arabic Only)
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF7FAFC))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // 👇 Copy ONLY Arabic
                      Clipboard.setData(ClipboardData(text: hadith.arabicText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("تم نسخ نص الحديث الشريف بنجاح",
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFF003527),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2)),
                      );
                    },
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy,
                              size: 18,
                              color:
                                  isDark ? Colors.white70 : Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(AppStrings.copy,
                              style: GoogleFonts.cairo(

                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    height: 25,
                    color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[200]),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // 👇 Share ONLY Arabic
                      SharePlus.instance.share(ShareParams(
                          text:
                              "${hadith.arabicText}\n\n$bookTitle - حديث ${hadith.idInBook}\n\nتطبيق مسلم"));
                    },
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, size: 18, color: bookColor),
                          const SizedBox(width: 8),
                          Text(AppStrings.share,
                              style: GoogleFonts.cairo(

                                  fontSize: 12,
                                  color: bookColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
