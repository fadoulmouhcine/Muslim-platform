import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/app_colors.dart';

const Color _kPrimaryGreen = Color(0xFF1A3626);

class AyahOfTheDayCard extends StatelessWidget {
  const AyahOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? [c.cardBg, c.cardBg]
              : [
                  _kPrimaryGreen.withValues(alpha: 0.05),
                  _kPrimaryGreen.withValues(alpha: 0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: c.isDark
                ? c.borderColor
                : _kPrimaryGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("آية اليوم",
                  style: GoogleFonts.cairo(
                      color: c.isDark ? c.goldAccent : _kPrimaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "﴿ وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ﴾",
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
                color: c.isDark ? Colors.white : _kPrimaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.8),
          ),
          const SizedBox(height: 12),
          Text(
            "تفسير مبسط... أَيَّةُ كُلِّ الْفُنُونِ الْغَيْرِ، فَقُرْآنُ الْعَيْنِ",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                color: c.isDark
                    ? c.textMuted
                    : _kPrimaryGreen.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.6),
          ),
        ],
      ),
    );
  }
}
