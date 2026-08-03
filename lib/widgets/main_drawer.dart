import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/about_screen.dart';
import '../screens/friday_hub_screen.dart';
import '../screens/athkar_main_screen.dart';
import '../services/vibration_service.dart';
import '../services/app_colors.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final c = AppColors.of(context);

    return Drawer(
      backgroundColor: c.isDark ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // --- HEADER ---
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header_bg.jpg'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
            ),
            child: Stack(
              children: [
                Container(color: Colors.black.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            color: Color(0xFFC5A059), size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "أهلاً بك يا مسلم",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "اجعل لسانك رطباً بذكر الله",
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                    context, Icons.shield_moon_outlined, "أذكار حصن المسلم",
                    () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AthkarMainScreen()),
                  );
                }),
                _buildMenuItem(context, Icons.auto_awesome_rounded,
                    "ملتقى الجمعة المباركة", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FridayHubScreen()),
                  );
                }),
                _buildMenuItem(
                    context, Icons.mosque_outlined, "المساجد القريبة", () {}),
                _buildMenuItem(
                    context, Icons.calculate_outlined, "حاسبة الزكاة", () {}),
                _buildMenuItem(
                    context, Icons.history_edu_outlined, "قضاء الفوائت", () {}),
                Divider(indent: 20, endIndent: 20, color: c.borderColor),
                _buildMenuItem(context, Icons.settings_outlined, "الإعدادات",
                    () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                }),
                _buildMenuItem(context, Icons.share_outlined, "شارك التطبيق",
                    () {
                  final settings =
                      Provider.of<SettingsProvider>(context, listen: false);
                  VibrationService.triggerHaptic(settings,
                      type: HapticType.selection);
                }),
                _buildMenuItem(context, Icons.info_outline, "عن التطبيق", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()),
                  );
                }),
                _buildMenuItem(
                    context, Icons.privacy_tip_outlined, "سياسة الخصوصية", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen()),
                  );
                }),
              ],
            ),
          ),

          // --- FOOTER ---
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "الإصدار ",
                    style: GoogleFonts.outfit(color: c.textMuted, fontSize: 12),
                  ),
                  Text(
                    settings.replaceDigits("1.0.0"),
                    style: GoogleFonts.outfit(
                        color: c.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isNew = false}) {
    final c = AppColors.of(context);
    return ListTile(
      leading: Icon(icon, color: c.textPrimary),
      title: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          if (isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A059),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "جديد",
                style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      horizontalTitleGap: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
    );
  }
}
