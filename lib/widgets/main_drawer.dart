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

  static const List<String> _dynamicGreetings = [
    "اجعل لسانك رطباً بذكر الله",
    "صلوا على من بكى شوقاً لرؤيتنا",
    "ألا بذكر الله تطمئن القلوب",
    "وما توفيقي إلا بالله",
    "فَاذْكُرُونِي أَذْكُرْكُمْ",
    "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
    "سبحان الله وبحمده، سبحان الله العظيم",
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Pick a random greeting
    final String randomGreeting = (List.of(_dynamicGreetings)..shuffle()).first;

    return Theme(
      data: Theme.of(context).copyWith(
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Drawer(
        child: Container(
          margin: EdgeInsets.only(
            top:
                MediaQuery.of(context).padding.top, // strictly below status bar
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.scaffoldBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              bottomLeft: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(-2, 0),
              )
            ],
          ),
          child: Column(
            children: [
              // --- HEADER ---
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A3626), // Premium Dark Green
                      Color(0xFFC5A059), // Elegant Gold
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  top: false, // top is handled by margin
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.0),
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF1A3626),
                            child: Icon(Icons.person_rounded,
                                color: Color(0xFFC5A059), size: 30),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "أهلاً بك يا ${settings.userName}",
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                randomGreeting,
                                style: GoogleFonts.cairo(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- MENU ITEMS ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionHeader("الخدمات الرئيسية", c),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shield_moon_rounded,
                      title: "أذكار حصن المسلم",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AthkarMainScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.auto_awesome_rounded,
                      title: "ملتقى الجمعة المباركة",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FridayHubScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.mosque_rounded,
                      title: "المساجد القريبة",
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildSectionHeader("أدوات وحسابات", c),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.calculate_rounded,
                      title: "حاسبة الزكاة",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.history_edu_rounded,
                      title: "قضاء الفوائت",
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    Divider(
                        indent: 24,
                        endIndent: 24,
                        color: c.borderColor,
                        height: 1),
                    const SizedBox(height: 16),
                    _buildSectionHeader("عام", c),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_rounded,
                      title: "الإعدادات",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.share_rounded,
                      title: "شارك التطبيق",
                      onTap: () {
                        final s = Provider.of<SettingsProvider>(context,
                            listen: false);
                        VibrationService.triggerHaptic(s,
                            type: HapticType.selection);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      title: "عن التطبيق",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.privacy_tip_outlined,
                      title: "سياسة الخصوصية",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- FOOTER ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : const Color(0xFFF8F9F8),
                  border: Border(
                    top: BorderSide(color: c.borderColor, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 16, color: c.textMuted.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        "الإصدار ",
                        style: GoogleFonts.cairo(
                          color: c.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        settings.replaceDigits("1.0.0"),
                        style: GoogleFonts.outfit(
                          color: c.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8, top: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w800, // Ultra bold
          color: const Color(0xFFC5A059), // Premium gold
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isNew = false,
  }) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFC5A059).withValues(alpha: 0.15),
        highlightColor: const Color(0xFFC5A059).withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFC5A059),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC5A059), Color(0xFFE5C17C)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "جديد",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: const Color(0xFF1A3626),
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: c.textMuted.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
