import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Services
import '../services/settings_provider.dart';
import '../services/silent_mode_service.dart';

// Screens
import 'friday_hub_screen.dart';
// Dashboard Widgets
import 'dashboard/widgets/hero_prayer_card.dart';
import 'dashboard/widgets/quick_access_grid.dart';
import 'dashboard/widgets/ayah_of_day_card.dart';
import '../widgets/main_drawer.dart';
import '../services/app_colors.dart';

// Premium Constants
const Color _kPrimaryGreen = Color(0xFF1A3626);
const Color _kGoldAccent = Color(0xFFC9A96E);

class DashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  final PrayerTimes? prayerTimes;
  final String city;
  final Coordinates? coordinates;
  final CalculationParameters? params;
  final VoidCallback onRetryLocation;

  const DashboardScreen({
    super.key,
    required this.onTabChange,
    required this.prayerTimes,
    required this.city,
    required this.coordinates,
    required this.params,
    required this.onRetryLocation,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late Timer _timer;
  late ValueNotifier<DateTime> _timeNotifier;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _timeNotifier = ValueNotifier(DateTime.now());
    _startClock();
    // ✅ DND LIFECYCLE: Listen for app foreground resume to re-validate permission.
    WidgetsBinding.instance.addObserver(this);
  }

  void _startClock() {
    // Isolated Time State: ValueNotifier prevents full-tree rebuilds
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _timeNotifier.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _timeNotifier.dispose();
    super.dispose();
  }

  // ✅ DND LIFECYCLE FIX: When the user returns from the DND settings screen,
  // re-check permission. If it was revoked while the app was paused, disable
  // autoSilent so it doesn't silently fail on the next prayer transition.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateDndPermissionOnResume();
    }
  }

  Future<void> _validateDndPermissionOnResume() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.autoSilentEnabled) return;
    final bool hasPerm = await SilentModeService.hasDndPermission();
    if (!hasPerm) {
      // Permission was revoked — turn off the feature automatically.
      await settings.setAutoSilentEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final c = AppColors.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      backgroundColor: c.scaffoldBg,
      body: Stack(
        children: [
          // ✨ Subtle Islamic Background Elements / Orbs
          Positioned(
            top: -100,
            right: -50,
            child: RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGoldAccent.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderSection(
                      onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ RepaintBoundary isolates the Timer rebuilds
                        RepaintBoundary(
                          child: HeroPrayerCard(
                            prayerTimes: widget.prayerTimes,
                            city: widget.city,
                            timeNotifier: _timeNotifier,
                            settings: settings,
                            onRetryLocation: widget.onRetryLocation,
                            coordinates: widget.coordinates,
                            params: widget.params,
                          ),
                        ),
                        if (DateTime.now().weekday == DateTime.friday) ...[
                          const SizedBox(height: 20),
                          const _FridayHomeBanner(),
                        ],
                        const SizedBox(height: 30),
                        QuickAccessGrid(onTabChange: widget.onTabChange),
                        const SizedBox(height: 30),
                        const AyahOfTheDayCard(),
                        const SizedBox(height: 30),
                        const _DailySunnahCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _HeaderSection({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded,
                color: c.isDark ? Colors.white : _kPrimaryGreen, size: 28),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            "مسلم",
            style: GoogleFonts.amiri(
              color: c.isDark ? Colors.white : _kPrimaryGreen,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : _kPrimaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded,
                color: c.isDark ? Colors.white : _kPrimaryGreen, size: 24),
          ),
        ],
      ),
    );
  }
}

class _DailySunnahCard extends StatelessWidget {
  const _DailySunnahCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("تحدي السنن اليومية",
              style: GoogleFonts.cairo(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSunnahRow(context, "قراءة أذكار الصباح", 3, 5),
          const SizedBox(height: 16),
          _buildSunnahRow(context, "استخدام السواك", 3, 5),
          const SizedBox(height: 16),
          _buildSunnahRow(context, "ركعتي الضحى", 4, 5),
        ],
      ),
    );
  }

  Widget _buildSunnahRow(
      BuildContext context, String title, int current, int total) {
    double progress = current / total;
    final c = AppColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text("$current / $total",
              style: GoogleFonts.outfit(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // RTL handled natively
            children: [
              Text(title,
                  style: GoogleFonts.cairo(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: c.isDark
                      ? c.borderColor
                      : _kPrimaryGreen.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      c.isDark ? c.primaryDarkGreen : _kPrimaryGreen),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: c.isDark ? c.primaryDarkGreen : _kPrimaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        ),
      ],
    );
  }
}

class _FridayHomeBanner extends StatelessWidget {
  const _FridayHomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3A2C), Color(0xFF1B5E45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30C5A059),
            blurRadius: 14,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FridayHubScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFC5A059),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "جمعة مباركة طيّبة 🌿",
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC5A059),
                        ),
                      ),
                      Text(
                        "سنن الجمعة، سورة الكهف والصلاة على النبي ﷺ",
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFC5A059),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePrayerMessageTicker extends StatefulWidget {
  final String message1;
  final String message2;

  const _ActivePrayerMessageTicker({
    required this.message1,
    required this.message2,
  });

  @override
  State<_ActivePrayerMessageTicker> createState() =>
      _ActivePrayerMessageTickerState();
}

class _ActivePrayerMessageTickerState
    extends State<_ActivePrayerMessageTicker> {
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
