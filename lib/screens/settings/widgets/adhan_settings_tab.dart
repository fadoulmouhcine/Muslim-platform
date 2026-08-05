import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/app_colors.dart';
import '../../../services/notification_service.dart';
import '../../../services/settings_provider.dart';
import '../../../services/vibration_service.dart';

class AdhanSettingsTab extends StatefulWidget {
  const AdhanSettingsTab({super.key});

  @override
  State<AdhanSettingsTab> createState() => _AdhanSettingsTabState();
}

class _AdhanSettingsTabState extends State<AdhanSettingsTab> {
  static const MethodChannel _adhanChannel =
      MethodChannel('com.example.muslim/adhan');
  bool _isPlayingAdhan = false;
  Timer? _pollingTimer;
  String _currentSound = 'adhan_hamza';

  @override
  void initState() {
    super.initState();
    _syncPlayingState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (mounted) setState(() => _currentSound = settings.adhanSound);
      if (settings.isAutoMethod) {
        settings.setAutoMethodEnabled(true,
            currentCountryCode: settings.lastCountryCode);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _stopPreview();
    super.dispose();
  }

  Future<void> _stopPreview() async {
    try {
      await _adhanChannel.invokeMethod('stopAdhanPreview');
    } catch (_) {}
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPlayingAdhan = false;
      });
    }
  }

  Future<void> _syncPlayingState() async {
    try {
      bool isPlaying =
          await _adhanChannel.invokeMethod('isPreviewPlaying') ?? false;
      if (mounted) {
        setState(() {
          _isPlayingAdhan = isPlaying;
        });
      }
      if (isPlaying) _startPolling();
    } catch (e) {
      debugPrint("Check playing error: $e");
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        bool isPlaying =
            await _adhanChannel.invokeMethod('isPreviewPlaying') ?? false;
        if (mounted && _isPlayingAdhan != isPlaying) {
          setState(() {
            _isPlayingAdhan = isPlaying;
          });
        }
        if (!isPlaying) timer.cancel();
      } catch (e) {
        timer.cancel();
      }
    });
  }

  Future<void> _playPreview(String soundName) async {
    try {
      await _adhanChannel
          .invokeMethod('playAdhanPreview', {'sound': soundName});
      if (mounted) {
        setState(() {
          _isPlayingAdhan = true;
        });
        _startPolling();
      }
    } catch (e) {
      debugPrint("Play preview error: $e");
    }
  }

  // ✅ 100% OFFLINE: Prayer times are always computed instantly via the
  // `adhan` astronomical calculation engine — no network round-trip needed.
  Future<void> _rescheduleNotifications({String? customMessage}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? lat = prefs.getDouble('latitude');
      double? lng = prefs.getDouble('longitude');
      if (lat != null && lng != null) {
        Coordinates coords = Coordinates(lat, lng);
        if (!mounted) return;
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        PrayerTimes prayerTimes =
            PrayerTimes.today(coords, settings.getCalculationParameters());

        if (!mounted) return;
        await NotificationService.schedulePrayerNotifications(
            prayerTimes, context);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(customMessage ?? "تم حفظ الإعدادات بنجاح",
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF003527),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint("Error rescheduling: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryDarkGreen =
        isDark ? const Color(0xFFC5A059) : const Color(0xFF003527);
    final mutedGreen =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0EC);
    final cardWhite = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mosque_rounded,
                    color: Color(0xFFC9A96E), size: 24),
                const SizedBox(width: 10),
                Text(
                  "إعدادات الأذان والمواقيت",
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFC9A96E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCalculationMethodDropdown(
                settings, primaryDarkGreen, mutedGreen, cardWhite),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),
            _buildMadhabDropdown(
                settings, primaryDarkGreen, mutedGreen, cardWhite),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),
            _buildPreFajrAlarmDropdown(
                settings, primaryDarkGreen, mutedGreen, cardWhite),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),
            _buildMuadhinDropdown(
                settings, primaryDarkGreen, mutedGreen, cardWhite),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),
            _buildAdhanVolumeSlider(settings, primaryDarkGreen, mutedGreen),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Text(
                "تنبيهات الصلوات",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryDarkGreen,
                ),
              ),
            ),
            _buildPrayerToggleRow(settings, "الفجر", "fajr", primaryDarkGreen),
            _buildPrayerToggleRow(settings, "الظهر", "dhuhr", primaryDarkGreen),
            _buildPrayerToggleRow(settings, "العصر", "asr", primaryDarkGreen),
            _buildPrayerToggleRow(
                settings, "المغرب", "maghrib", primaryDarkGreen),
            _buildPrayerToggleRow(settings, "العشاء", "isha", primaryDarkGreen),
          ],
        );
      },
    );
  }

  Widget _buildAutoMethodToggle(
      SettingsProvider settings, Color primaryDarkGreen, Color cardWhite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: settings.isAutoMethod
              ? primaryDarkGreen.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        activeThumbColor: primaryDarkGreen,
        contentPadding: EdgeInsets.zero,
        title: Text(
          "تحديد طريقة الحساب تلقائياً حسب الموقع",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryDarkGreen,
          ),
        ),
        subtitle: Text(
          settings.isAutoMethod
              ? "مُفعل - يتم التحديث تلقائياً عند التواجد أو السفر لبلد آخر"
              : "معطل - تم تثبيت طريقة الحساب يدوياً",
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        value: settings.isAutoMethod,
        onChanged: (bool value) async {
          if (value) {
            await settings.setAutoMethodEnabled(true,
                currentCountryCode: settings.lastCountryCode);
          } else {
            await settings.setAutoMethodEnabled(false);
          }
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildCalculationMethodDropdown(SettingsProvider settings,
      Color primaryDarkGreen, Color mutedGreen, Color cardWhite) {
    final methods = {
      'morocco': 'وزارة الأوقاف المغربية',
      'karachi': 'جامعة العلوم الإسلامية بكراتشي',
      'isna': 'الاتحاد الإسلامي بأمريكا الشمالية',
      'mwl': 'رابطة العالم الإسلامي',
      'egypt': 'الهيئة العامة المصرية للمساحة',
      'umm_al_qura': 'تقويم أم القرى',
      'france': 'اتحاد المنظمات الإسلامية في فرنسا',
      'algeria': 'وزارة الشؤون الدينية والأوقاف الجزائرية',
      'tunisia': 'وزارة الشؤون الدينية التونسية',
      'kuwait': 'وزارة الأوقاف والشئون الإسلامية الكويتية',
      'paris_mosque': 'مسجد باريس الكبير',
      'uae': 'الهيئة العامة للشؤون الإسلامية والأوقاف - الإمارات',
      'palestine': 'وزارة الأوقاف والشؤون الدينية الفلسطينية',
      'turkey': 'رئاسة الشؤون الدينية التركية (ديانت)',
      'belgium': 'المجلس التنفيذي الإسلامي ببلجيكا',
      'igmg_germany': 'منظمة ملي جوروش بألمانيا (IGMG)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAutoMethodToggle(settings, primaryDarkGreen, cardWhite),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("طريقة الحساب",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryDarkGreen)),
            Text("الهيئة المعتمدة",
                style:
                    GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: mutedGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: methods.containsKey(settings.calculationMethod)
                  ? settings.calculationMethod
                  : 'morocco',
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.onSurface),
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13.5),
              dropdownColor: cardWhite,
              borderRadius: BorderRadius.circular(14),
              items: methods.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      e.value,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  if (settings.isAutoMethod) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text("إيقاف التحديد التلقائي؟",
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        content: Text(
                          "سيؤدي اختيار طريقة حساب يدويًا إلى إيقاف التحديد التلقائي بحسب الموقع. هل تريد المتابعة؟",
                          style: GoogleFonts.cairo(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text("إلغاء",
                                style: GoogleFonts.cairo(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryDarkGreen),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text("متابعة",
                                style: GoogleFonts.cairo(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;
                  }

                  settings.setCalculationMethod(val, isUserAction: true);
                  _rescheduleNotifications(
                      customMessage: "تم تحديث طريقة حساب مواقيت الصلاة بنجاح");
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Madhab (Shafi'i / Hanafi) selector — affects Asr prayer time
  // calculation via the shadow-length factor used by the offline `adhan`
  // astronomical engine.
  Widget _buildMadhabDropdown(SettingsProvider settings,
      Color primaryDarkGreen, Color mutedGreen, Color cardWhite) {
    final madhabs = {
      'shafi': 'شافعي / مالكي / حنبلي',
      'hanafi': 'حنفي',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("المذهب الفقهي",
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryDarkGreen)),
              Text("يؤثر على حساب وقت صلاة العصر",
                  style:
                      GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: mutedGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: madhabs.containsKey(settings.madhab)
                    ? settings.madhab
                    : 'shafi',
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13),
                dropdownColor: cardWhite,
                borderRadius: BorderRadius.circular(14),
                items: madhabs.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) async {
                  if (val != null) {
                    await settings.setMadhab(val);
                    await _rescheduleNotifications(
                        customMessage: "تم تحديث المذهب الفقهي بنجاح");
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreFajrAlarmDropdown(SettingsProvider settings,
      Color primaryDarkGreen, Color mutedGreen, Color cardWhite) {
    final options = {
      0: 'معطل',
      15: 'قبل 15 دقيقة',
      30: 'قبل 30 دقيقة',
      45: 'قبل 45 دقيقة',
      60: 'قبل ساعة كاملة',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("منبه السحور / قيام الليل",
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryDarkGreen)),
              Text("تنبيه مسبق قبل أذان الفجر",
                  style:
                      GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: mutedGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: settings.preFajrMinutes,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13),
                dropdownColor: cardWhite,
                borderRadius: BorderRadius.circular(12),
                items: options.entries.map((e) {
                  return DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    settings.setPreFajrMinutes(val);
                    _rescheduleNotifications(
                        customMessage: val == 0
                            ? "تم إيقاف منبه قيام الليل"
                            : "تم ضبط منبه قيام الليل بنجاح");
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuadhinDropdown(SettingsProvider settings,
      Color primaryDarkGreen, Color mutedGreen, Color cardWhite) {
    final muadhins = {
      'adhan_hamza': 'أذان حمزة',
      'adhan_kourdi': 'أذان الكردي',
      'takbeer': 'تكبير',
    };

    if (!muadhins.containsKey(_currentSound)) _currentSound = 'adhan_hamza';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 1,
          child: Text("المؤذن",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryDarkGreen)),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: mutedGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _currentSound,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: primaryDarkGreen),
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: primaryDarkGreen,
                          fontSize: 13),
                      dropdownColor: cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      items: muadhins.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          if (_isPlayingAdhan) await _stopPreview();
                          setState(() => _currentSound = val);
                          await settings.setAdhanSound(val);
                          if (mounted) {
                            await _rescheduleNotifications(
                                customMessage: "تم تغيير صوت المؤذن بنجاح");
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _isPlayingAdhan
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_fill_rounded,
                  color: _isPlayingAdhan ? Colors.red : const Color(0xFFC9A96E),
                  size: 32,
                ),
                onPressed: () async {
                  if (_isPlayingAdhan) {
                    await _stopPreview();
                  } else {
                    await _playPreview(_currentSound);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdhanVolumeSlider(
      SettingsProvider settings, Color primaryDarkGreen, Color mutedGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("مستوى صوت الأذان",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryDarkGreen)),
            Text("%${(settings.adhanVolume * 100).toInt()}",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryDarkGreen)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: mutedGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.volume_down_rounded,
                  color: Colors.grey[700], size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryDarkGreen,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: primaryDarkGreen,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10, elevation: 2),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: settings.adhanVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      settings.setAdhanVolume(val);
                      if (!_isPlayingAdhan) {
                        _playPreview(_currentSound);
                      }
                    },
                  ),
                ),
              ),
              Icon(Icons.volume_up_rounded, color: primaryDarkGreen, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerToggleRow(SettingsProvider settings, String title,
      String prayerKey, Color primaryDarkGreen) {
    final isEnabled = settings.isPrayerEnabled(prayerKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryDarkGreen)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined,
                    color: Color(0xFFC9A96E), size: 22),
                onPressed: isEnabled
                    ? () =>
                        _showOffsetDialog(context, settings, title, prayerKey)
                    : null,
              ),
              Switch(
                value: isEnabled,
                onChanged: (val) async {
                  VibrationService.triggerHaptic(settings);
                  await settings.setPrayerNotification(prayerKey, val);
                  await _rescheduleNotifications(
                      customMessage: val
                          ? "تم تفعيل تنبيه صلاة $title"
                          : "تم إيقاف تنبيه صلاة $title");
                },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFC5A059),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOffsetDialog(BuildContext context, SettingsProvider settings,
      String title, String prayerKey) {
    int localOffset = settings.getPrayerOffset(prayerKey);
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("وقت التنبيه",
                      style: GoogleFonts.cairo(
                          color: c.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("تخصيص تنبيه لصلاة $title",
                      style: GoogleFonts.cairo(
                          color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 32),
                  Text(
                    _getPreAdhanText(localOffset),
                    style: GoogleFonts.cairo(
                        color: const Color(0xFFC9A96E),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: c.isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey[100],
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.remove_rounded),
                          color: const Color(0xFF003527),
                          onPressed: localOffset > 0
                              ? () => setModalState(() => localOffset--)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFC9A96E),
                            inactiveTrackColor:
                                c.isDark ? Colors.grey[800] : Colors.grey[200],
                            thumbColor: const Color(0xFFC9A96E),
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12, elevation: 4),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 24),
                          ),
                          child: Slider(
                            value: localOffset.toDouble(),
                            min: 0,
                            max: 20,
                            divisions: 20,
                            onChanged: (val) =>
                                setModalState(() => localOffset = val.toInt()),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: c.isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey[100],
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded),
                          color: const Color(0xFF003527),
                          onPressed: localOffset < 20
                              ? () => setModalState(() => localOffset++)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: c.textSecondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12)),
                        child: Text("إلغاء",
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await settings.setPrayerOffset(
                              prayerKey, localOffset);
                          await NotificationService
                              .rescheduleNotificationsFromBackground();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  localOffset == 0
                                      ? "تم إيقاف التنبيه المسبق لصلاة $title"
                                      : "تم ضبط التنبيه المسبق لصلاة $title (قبل $localOffset دقيقة)",
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF003527),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(20),
                              duration: const Duration(seconds: 2),
                            ));
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC9A96E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("موافق",
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getPreAdhanText(int offset) {
    if (offset == 0) return "عند وقت الأذان تماماً";
    if (offset == 1) return "قبل الأذان بدقيقة واحدة";
    if (offset == 2) return "قبل الأذان بدقيقتين";
    if (offset >= 3 && offset <= 10) return "قبل الأذان بـ $offset دقائق";
    return "قبل الأذان بـ $offset دقيقة";
  }
}
