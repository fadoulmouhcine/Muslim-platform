import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ ضروري
import '../services/settings_provider.dart'; // ✅ ضروري
import '../services/app_colors.dart';
import '../constants/app_strings.dart';


class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  List<dynamic> _names = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      // Load JSON file
      final String response =
          await rootBundle.loadString('assets/json/Names_Of_Allah.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _names = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading names: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings Provider
    final settings = Provider.of<SettingsProvider>(context);

    // Check Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "أسماء الله الحسنى",
          style: GoogleFonts.arefRuqaa(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 per row
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _names.length,
              itemBuilder: (context, index) {
                final nameData = _names[index];
                // ✅ تمرير settings
                return _buildNameCard(
                    context, nameData, cardColor, textColor, settings);
              },
            ),
    );
  }

  Widget _buildNameCard(BuildContext context, dynamic data, Color bgColor,
      Color textColor, SettingsProvider settings) {
    return GestureDetector(
      onTap: () {
        _showNameDetails(context, data);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                const Color(0xFFD4AF37).withValues(alpha: 0.3), // Gold Border
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Pattern (Optional)
            Positioned(
              top: -10,
              right: -10,
              child: Icon(
                Icons.star_border_purple500_outlined,
                size: 60,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ID Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    // ✅ 2. تحويل الرقم الترتيبي
                    settings.replaceDigits("${data['id']}"),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Name (Calligraphy)
                Text(
                  data['name'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNameDetails(BuildContext context, dynamic data) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              image: const DecorationImage(
                  image: AssetImage(
                      'assets/images/basmala.png'), // Ila 3ndk background
                  opacity: 0.05,
                  fit: BoxFit.cover)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['name'],
                style: GoogleFonts.amiri(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37), // Gold
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: c.borderColor, thickness: 1),
              const SizedBox(height: 10),
              Text(
                data['text'],
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A059),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppStrings.close,
                    style: GoogleFonts.cairo(color: Colors.white)),

              )
            ],
          ),
        ),
      ),
    );
  }
}
