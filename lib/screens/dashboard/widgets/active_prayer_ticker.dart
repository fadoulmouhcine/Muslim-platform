import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late Timer _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % 2;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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
      child: AnimatedSwitcher(
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
          key: ValueKey<int>(_currentIndex),
          child: Text(
            messages[_currentIndex],
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
