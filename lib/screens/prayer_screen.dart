import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/prayer_time_service.dart';
import '../services/app_colors.dart';
import '../services/app_clock_service.dart';
import 'settings_screen.dart';


class PrayerTimesScreen extends StatefulWidget {
  final PrayerTimes? prayerTimes;

  const PrayerTimesScreen({super.key, this.prayerTimes});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver {
  PrayerTimes? _activePrayerTimes;
  String _lastCalculationMethod = '';
  // ✅ UX FIX: Tracks whether a background refresh (e.g. after changing the
  // calculation method or returning from Settings) is in progress, so we can
  // show subtle loading feedback instead of leaving the user without any
  // indication that data is being updated.
  bool _isRefreshing = false;


  // ✅ PERF/BATTERY FIX: This screen previously ran its own independent
  // `Timer.periodic(seconds: 1)` purely to force a `setState()` rebuild
  // every second for the live countdown display. It now listens to the
  // single shared `AppClockService` clock instead — removing one of the
  // several duplicate concurrent 1-second timers that used to run at once
  // when this screen was open alongside the dashboard.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activePrayerTimes = widget.prayerTimes;
    AppClockService.instance.now.addListener(_onTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppClockService.instance.now.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPrayerTimes();
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context);
    if (_lastCalculationMethod != settings.calculationMethod) {
      _lastCalculationMethod = settings.calculationMethod;
      _refreshPrayerTimes();
    }
  }

  // ✅ 100% OFFLINE: Prayer times are computed instantly via the `adhan`
  // astronomical calculation engine — no network round-trip is involved,
  // so this "refresh" is really just an instant recomputation whenever the
  // calculation method, madhab, or location changes.
  Future<void> _refreshPrayerTimes() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final coords = _activePrayerTimes?.coordinates ??
        widget.prayerTimes?.coordinates ??
        Coordinates(21.4225, 39.8262);

    try {
      final times = PrayerTimes.today(
        coords,
        settings.getCalculationParameters(),
      );
      if (mounted) {
        setState(() {
          _activePrayerTimes = times;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final c = AppColors.of(context);

    final effectiveTimes = _activePrayerTimes ??
        widget.prayerTimes ??
        PrayerTimes.today(
          Coordinates(21.4225, 39.8262),
          settings.getCalculationParameters(),
        );

    Prayer? next = effectiveTimes.nextPrayer();
    if (next == Prayer.none) {
      next = Prayer.fajr;
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          color: c.scaffoldBg,
        ),
        child: Stack(
          children: [
            // Background blur accent
            Positioned(
              top: -80,
              right: -80,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.isDark
                        ? const Color(0xFFC5A059).withValues(alpha: 0.12)
                        : c.primaryDarkGreen.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, settings, effectiveTimes),
                  // ✅ UX FIX: Subtle loading indicator so refreshing prayer
                  // times after a settings change never looks frozen/blank.
                  if (_isRefreshing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: Color(0xFFC5A059),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  const SizedBox(height: 8),

                  _buildNextPrayerCard(next, effectiveTimes, settings, context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      children: [
                        _buildPremiumPrayerCard(
                            context,
                            "الفجر",
                            effectiveTimes.fajr,
                            settings,
                            "Fajr",
                            next == Prayer.fajr,
                            Icons.wb_twilight),
                        _buildPremiumPrayerCard(
                            context,
                            "الشروق",
                            effectiveTimes.sunrise,
                            settings,
                            "Sunrise",
                            next == Prayer.sunrise,
                            Icons.wb_sunny_outlined,
                            isPrayer: false),
                        _buildPremiumPrayerCard(
                            context,
                            "الظهر",
                            effectiveTimes.dhuhr,
                            settings,
                            "Dhuhr",
                            next == Prayer.dhuhr,
                            Icons.wb_sunny),
                        _buildPremiumPrayerCard(
                            context,
                            "العصر",
                            effectiveTimes.asr,
                            settings,
                            "Asr",
                            next == Prayer.asr,
                            Icons.wb_cloudy_outlined),
                        _buildPremiumPrayerCard(
                            context,
                            "المغرب",
                            effectiveTimes.maghrib,
                            settings,
                            "Maghrib",
                            next == Prayer.maghrib,
                            Icons.nights_stay_outlined),
                        _buildPremiumPrayerCard(
                            context,
                            "العشاء",
                            effectiveTimes.isha,
                            settings,
                            "Isha",
                            next == Prayer.isha,
                            Icons.nights_stay),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Slim Header Widget
  Widget _buildHeader(BuildContext context, SettingsProvider settings,
      PrayerTimes prayerTimes) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "مواقيت الصلاة",
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                "حافظ على صلاتك",
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : c.primaryDarkGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.tune,
                  color: c.isDark ? Colors.white : c.primaryDarkGreen,
                  size: 22),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SettingsScreen(initialTabIndex: 1),
                  ),
                );
                if (mounted) {
                  await _refreshPrayerTimes();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Compact Multi-State Hero Card
  Widget _buildNextPrayerCard(Prayer? next, PrayerTimes times,
      SettingsProvider settings, BuildContext context) {
    final c = AppColors.of(context);
    final currentTime = DateTime.now();
    final state = PrayerDisplayState.calculateState(
      prayerTimes: times,
      currentTime: currentTime,
    );

    String timerText = "";
    if (state.phase != PrayerPhase.prayerInProgress) {
      final dur = state.remaining;
      timerText =
          "${dur.inHours > 0 ? '${dur.inHours.toString().padLeft(2, '0')}:' : ''}${(dur.inMinutes % 60).toString().padLeft(2, '0')}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}";
      timerText = settings.replaceDigits(timerText);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? [const Color(0xFF1B241E), const Color(0xFF101712)]
              : [const Color(0xFF1D3325), const Color(0xFF102016)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A059).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Title + Target Time / Live Dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.titleText,
                style: GoogleFonts.cairo(
                  color: state.phase == PrayerPhase.prayerInProgress
                      ? const Color(0xFFE5C17C)
                      : (state.phase == PrayerPhase.iqamahCountdown
                          ? const Color(0xFFE5C17C)
                          : Colors.white70),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.phase == PrayerPhase.prayerInProgress)
                const _ScreenLiveDot()
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    settings.formatPrayerTime(state.targetTime,
                        context: context),
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFE5C17C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Middle Row: Dynamic Timer or In-Prayer Message
          if (state.phase == PrayerPhase.prayerInProgress) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mosque_rounded,
                        color: Color(0xFFC5A059),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (state.inPrayerMessage ??
                                  "الصلاة تقام الآن في المساجد - تقبل الله طاعتكم")
                              .replaceAll('🕌', '')
                              .trim(),
                          style: GoogleFonts.cairo(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volume_off_rounded,
                        color: Color(0xFFE5C17C),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (state.silentModeMessage ??
                                  "يرجى التأكد من تفعيل وضع الصامت")
                              .replaceAll('🔇', '')
                              .replaceAll('🔕', '')
                              .trim(),
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFE5C17C),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  timerText,
                  style: GoogleFonts.outfit(
                    color: state.phase == PrayerPhase.iqamahCountdown
                        ? const Color(0xFFE5C17C)
                        : const Color(0xFFC5A059),
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: Color(0xFFC5A059), size: 22),
                ),
              ],
            ),
            if (state.phase == PrayerPhase.iqamahCountdown &&
                state.wuduMessage != null) ...[
              const SizedBox(height: 8),
              _ScreenWuduBanner(text: state.wuduMessage!),
            ],
          ],

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.phase == PrayerPhase.prayerInProgress
                    ? const Color(0xFF00E676)
                    : (state.phase == PrayerPhase.iqamahCountdown
                        ? const Color(0xFFE5C17C)
                        : const Color(0xFFC5A059)),
              ),
              minHeight: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 High-Contrast Prayer List Item (Supports Light & Dark Modes)
  Widget _buildPremiumPrayerCard(
      BuildContext context,
      String name,
      DateTime time,
      SettingsProvider settings,
      String key,
      bool isNext,
      IconData icon,
      {bool isPrayer = true}) {
    final c = AppColors.of(context);
    bool isMuted = isPrayer ? settings.isPrayerMuted(key) : true;
    String timeStr = settings.formatPrayerTime(time, context: context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isNext
            ? const Color(0xFFC5A059).withValues(alpha: c.isDark ? 0.15 : 0.12)
            : c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isNext
            ? Border.all(
                color: const Color(0xFFC5A059).withValues(alpha: 0.6),
                width: 1.5)
            : Border.all(color: c.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isNext
                ? const Color(0xFFC5A059)
                : (c.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : c.primaryDarkGreen.withValues(alpha: 0.08)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isNext
                ? Colors.white
                : (c.isDark ? const Color(0xFFC5A059) : c.primaryDarkGreen),
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.amiri(
            color: isNext
                ? (c.isDark ? Colors.white : const Color(0xFF003527))
                : c.textPrimary,
            fontSize: 18,
            fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeStr,
              style: GoogleFonts.outfit(
                color: isNext ? const Color(0xFFC5A059) : c.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            if (isPrayer)
              GestureDetector(
                onTap: () async {
                  await settings.togglePrayerMute(key);
                  bool nowMuted = settings.isPrayerMuted(key);
                  if (!context.mounted) return;
                  await NotificationService
                      .rescheduleNotificationsFromBackground();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nowMuted
                            ? "تنبيه أذان $name: صامت"
                            : "تنبيه أذان $name: مفعّل",
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFF003527),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(20),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isMuted
                        ? Colors.red.withValues(alpha: 0.12)
                        : const Color(0xFFC5A059).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: isMuted ? Colors.redAccent : const Color(0xFFC5A059),
                    size: 20,
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  color: c.isDark
                      ? const Color(0xFFC5A059).withValues(alpha: 0.5)
                      : const Color(0xFF8E8E93),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScreenWuduBanner extends StatefulWidget {
  final String text;
  const _ScreenWuduBanner({required this.text});

  @override
  State<_ScreenWuduBanner> createState() => _ScreenWuduBannerState();
}

class _ScreenWuduBannerState extends State<_ScreenWuduBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = widget.text.replaceAll('🕌', '').trim();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFC5A059).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  const Color(0xFFC5A059).withValues(alpha: _animation.value),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC5A059)
                    .withValues(alpha: _animation.value * 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Icon(
                Icons.mosque_rounded,
                color: Color(0xFFC5A059),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cleanText,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFE5C17C),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScreenLiveDot extends StatefulWidget {
  const _ScreenLiveDot();

  @override
  State<_ScreenLiveDot> createState() => _ScreenLiveDotState();
}

class _ScreenLiveDotState extends State<_ScreenLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00E676)
                  .withValues(alpha: 0.25 + (_animation.value * 0.45)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676)
                    .withValues(alpha: _animation.value * 0.3),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676)
                      .withValues(alpha: _animation.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676)
                          .withValues(alpha: _animation.value),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "مباشر",
                style: GoogleFonts.cairo(
                  color: const Color(0xFF00E676),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
