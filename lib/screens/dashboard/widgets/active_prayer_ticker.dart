import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/app_clock_service.dart';

/// Rotates between two short in-prayer messages every ~5 seconds.
///
/// ✅ PERF/BATTERY FIX: This widget previously created its own independent
/// `Timer.periodic(seconds: 5)`. It now derives its 5-second cadence from
/// the single shared `AppClockService` (which already ticks every second
/// app-wide) instead of running a second, separate timer — removing one of
/// the several concurrent timers that used to run simultaneously whenever
/// this ticker was visible alongside the dashboard/prayer screens.
class ActivePrayerMessageTicker extends StatefulWidget {
  final String message1;
  final String message2;

  const ActivePrayerMessageTicker({
    super.key,
    required this.message1,
    required this.message2,
  });

  @override
  State<ActivePrayerMessageTicker> createState() =>
      _ActivePrayerMessageTickerState();
}

class _ActivePrayerMessageTickerState extends State<ActivePrayerMessageTicker> {
  @override
  Widget build(BuildContext context) {
    final messages = [widget.message1, widget.message2];

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFC5A059).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: ValueListenableBuilder<DateTime>(
        valueListenable: AppClockService.instance.now,
        builder: (context, now, child) {
          // Derive a 5-second-cadence index purely from the shared clock,
          // avoiding the need for a second independent timer.
          final currentIndex = (now.second ~/ 5) % 2;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final inAnimation = Tween<Offset>(
                begin: const Offset(0.0, 0.8),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: inAnimation,
                  child: child,
                ),
              );
            },
            child: Align(
              alignment: Alignment.centerRight,
              key: ValueKey<int>(currentIndex),
              child: Text(
                messages[currentIndex],
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}
