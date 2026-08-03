import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ ضروري
import '../services/settings_provider.dart'; // ✅ ضروري
import '../services/sunnah_service.dart';
import 'sunnah_reading_screen.dart';

class SunnahChaptersScreen extends StatelessWidget {
  final Map<String, dynamic> bookInfo; // Title, Color, File

  const SunnahChaptersScreen({super.key, required this.bookInfo});

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings Provider
    final settings = Provider.of<SettingsProvider>(context);

    final Color bookColor = bookInfo['color'];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bookColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          bookInfo['title'],
          style: GoogleFonts.arefRuqaa(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: SunnahService.loadBookData(bookInfo['file']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: bookColor));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text("لا توجد بيانات", style: GoogleFonts.cairo()));
          }

          final chapters = snapshot.data!['chapters'] as List<Chapter>;
          final hadithsMap =
              snapshot.data!['hadithsMap'] as Map<int, List<Hadith>>;

          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: chapters.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final count = hadithsMap[chapter.id]?.length ?? 0;

              return Card(
                elevation: 0, // Flat premium look
                color: isDark ? const Color(0xFF161616) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isDark
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bookColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      // ✅ 2. تحويل رقم الباب
                      settings.replaceDigits("${index + 1}"),
                      style: GoogleFonts.cairo(
                          color: bookColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    chapter.arabicTitle,
                    style: GoogleFonts.amiri(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  subtitle: Text(
                    // ✅ 3. تحويل عدد الأحاديث
                    "${settings.replaceDigits(count.toString())} حديث",
                    style: GoogleFonts.cairo(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontSize: 12),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.grey[400]),
                  onTap: () {
                    // Navigate to Reading Screen with Data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SunnahReadingScreen(
                          chapter: chapter,
                          hadiths: hadithsMap[chapter.id] ?? [],
                          bookColor: bookColor,
                          bookTitle: bookInfo['title'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
