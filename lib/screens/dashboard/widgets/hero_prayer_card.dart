import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/app_colors.dart';
import '../../../services/prayer_time_service.dart';
import '../../../services/prayer_times_controller.dart';
import '../../../services/settings_provider.dart';
import '../../../services/silent_mode_service.dart';
import '../../prayer_screen.dart';
import 'active_prayer_ticker.dart';

const Color _kPrimaryGreen = Color(0xFF1A3626);
const Color _kGoldAccent = Color(0xFFC9A96E);

class HeroPrayerCard extends StatelessWidget {
  final PrayerTimes? prayerTimes;
  final String city;
  final ValueNotifier<DateTime> timeNotifier;
  final SettingsProvider settings;
  final VoidCallback onRetryLocation;
  final Coordinates? coordinates;
  final CalculationParameters? params;

  static bool _wasInPrayer = false;

  const HeroPrayerCard({
    super.key,
    required this.prayerTimes,
    required this.city,
    required this.timeNotifier,
    required this.settings,
    required this.onRetryLocation,
    this.coordinates,
    this.params,
  });

  void _checkAutoSilentMode(
      PrayerDisplayState state, SettingsProvider settings) {
    if (!settings.autoSilentEnabled) return;

    if (state.phase == PrayerPhase.prayerInProgress) {
      if (!_wasInPrayer) {
        _wasInPrayer = true;
        SilentModeService.enableSilentMode();
      }
    } else {
      if (_wasInPrayer) {
        _wasInPrayer = false;
        SilentModeService.restoreNormalMode(triggerCatchUpNotification: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isHeroCard = (child.key as ValueKey?)?.value == 'hero_card';
        if (isHeroCard) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
              child: child,
            ),
          );
        } else {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        }
      },
      child: prayerTimes == null
          ? _buildOfflineOrSyncingCard(context, c)
          : _buildActiveCard(context, c),
    );
  }

  Widget _buildOfflineOrSyncingCard(BuildContext context, AppColors c) {
    final bool isSyncing = city == "جاري تحديد الموقع..." ||
        city == "جاري تحديث المواقيت تلقائياً...";

    return Container(
      key: const ValueKey('offline_banner'),
      constraints: const BoxConstraints(minHeight: 120),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1E293B) : _kPrimaryGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _kGoldAccent.withValues(alpha: isSyncing ? 0.4 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _kGoldAccent.withValues(alpha: isSyncing ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: isSyncing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _kGoldAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "جاري تحديث المواقيت تلقائياً...",

                    style: GoogleFonts.cairo(
                      color: _kGoldAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "جاري جلب إحداثيات الموقع وإعدادات الحساب",

                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_rounded,
                      color: _kGoldAccent, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    "يرجى التأكد من تفعيل خدمة الموقع (GPS) وإعادة المحاولة",

                    style:
                        GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: onRetryLocation,
                    icon: const Icon(Icons.refresh_rounded,
                        color: _kGoldAccent, size: 16),
                    label: Text(
                      "إعادة المحاولة",

                      style: GoogleFonts.cairo(
                          color: _kGoldAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      backgroundColor: Colors.white12,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, AppColors c) {
    return GestureDetector(
      key: const ValueKey('hero_card'),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                PrayerTimesScreen(prayerTimes: prayerTimes),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
          ),
        );
      },
      child: Container(
        width: double.infinity,
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
              color: const Color(0xFFC5A059).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ValueListenableBuilder<DateTime>(
          valueListenable: timeNotifier,
          builder: (context, currentTime, child) {
            // ✅ Task 4.2: Coordinates/params fallback logic is now
            // centralized in `PrayerTimesController` instead of being
            // duplicated here.
            final times = prayerTimes ??
                PrayerTimesController.computeTodayTimes(
                  coordinates: coordinates,
                  params: params,
                  settings: settings,
                );
            final state = PrayerDisplayState.calculateState(
              prayerTimes: times,
              currentTime: currentTime,
              coordinates: coordinates,
              params: params,
            );

            _checkAutoSilentMode(state, settings);

            // Timer display
            String timerText = "";
            if (state.phase != PrayerPhase.prayerInProgress) {
              final dur = state.remaining;
              timerText =
                  "${dur.inHours > 0 ? '${dur.inHours.toString().padLeft(2, '0')}:' : ''}${(dur.inMinutes % 60).toString().padLeft(2, '0')}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}";
              timerText = settings.replaceDigits(timerText);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Title + Location Badge + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (city.isNotEmpty && city != "جاري تحديد الموقع...")
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFC5A059).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  const Color(0xFFC5A059).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Color(0xFFE5C17C), size: 12),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  city,
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFFE5C17C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (state.phase == PrayerPhase.prayerInProgress) ...[
                      const SizedBox(width: 6),
                      const LivePrayerDot(),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Middle Row: Main Dynamic Content
                if (state.phase == PrayerPhase.prayerInProgress) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: ActivePrayerMessageTicker(
                      message1:
                          "الصلاة تقام الآن في المساجد - تقبل الله طاعتكم 🕌",
                      message2: "يرجى التأكد من تفعيل وضع الصامت 🔇",
                    ),
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
                              : _kGoldAccent,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kGoldAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _kGoldAccent.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.access_time_rounded,
                            color: _kGoldAccent, size: 22),
                      ),
                    ],
                  ),
                  if (state.phase == PrayerPhase.iqamahCountdown &&
                      state.wuduMessage != null) ...[
                    const SizedBox(height: 8),
                    PulsingWuduBanner(text: state.wuduMessage!),
                  ],
                ],

                const SizedBox(height: 12),

                // Modern Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.phase == PrayerPhase.prayerInProgress
                          ? const Color(0xFF00E676)
                          : (state.phase == PrayerPhase.iqamahCountdown
                              ? const Color(0xFFE5C17C)
                              : _kGoldAccent),
                    ),
                    minHeight: 4.0,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LivePrayerDot extends StatefulWidget {
  const LivePrayerDot({super.key});

  @override
  State<LivePrayerDot> createState() => _LivePrayerDotState();
}

class _LivePrayerDotState extends State<LivePrayerDot>
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

class PulsingWuduBanner extends StatefulWidget {
  final String text;
  const PulsingWuduBanner({super.key, required this.text});

  @override
  State<PulsingWuduBanner> createState() => _PulsingWuduBannerState();
}

class _PulsingWuduBannerState extends State<PulsingWuduBanner>
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
