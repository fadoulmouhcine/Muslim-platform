import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/app_colors.dart';
import '../../athkar_main_screen.dart';
import '../../friday_hub_screen.dart';
import '../../hijri_calendar_screen.dart';
import '../../names_of_allah_screen.dart';
import '../../prophet_doaa_screen.dart';
import '../../qibla_screen.dart';
import '../../daily_harvest_screen.dart';
import '../../tasbih_screen.dart';

const Color _kPrimaryGreen = Color(0xFF1A3626);
const Color _kGoldAccent = Color(0xFFC9A96E);

class QuickAccessGrid extends StatelessWidget {
  final Function(int) onTabChange;
  const QuickAccessGrid({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.72,
      children: [
        _ActionItem("أسماء الله\nالحسنى", Icons.local_library_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const NamesOfAllahScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }),
        _ActionItem("حصن\nالمسلم", Icons.verified_user_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const AthkarMainScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }, "adhkar_hero"),
        _ActionItem("سنن\nالجمعة", Icons.auto_awesome_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const FridayHubScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }),
        _ActionItem("السبحة\nالرقمية", Icons.touch_app_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const TasbihScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }),
        _ActionItem("التقويم\nالهجري", Icons.calendar_month_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HijriCalendarScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }),
        _ActionItem("أدعية نبوية\nوقرآنية", Icons.auto_stories_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ProphetDoaaScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }),
        _ActionItem("اتجاه\nالقبلة", Icons.explore_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    QiblaScreen(backToHome: () => Navigator.pop(context)),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }, "qibla_hero"),
        _ActionItem(
            "القرآن\nالكريم", Icons.menu_book_rounded, () => onTabChange(2)),
        _ActionItem("حصاد\nاليوم", Icons.track_changes_rounded, () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const DailyHarvestScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ));
        }),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? heroTag;

  const _ActionItem(this.title, this.icon, this.onTap, [this.heroTag]);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget iconBlock = Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1E293B) : _kPrimaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : _kPrimaryGreen.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Icon(icon, color: _kGoldAccent, size: 28),
    );

    if (heroTag != null) iconBlock = Hero(tag: heroTag!, child: iconBlock);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          iconBlock,
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                color: c.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
