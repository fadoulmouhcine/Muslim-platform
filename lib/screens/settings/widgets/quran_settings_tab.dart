import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services/app_colors.dart';
import '../../../services/quran_service.dart';
import '../../../services/settings_provider.dart';
import '../../../services/vibration_service.dart';
import '../../../constants/app_strings.dart';


class QuranSettingsTab extends StatefulWidget {
  const QuranSettingsTab({super.key});

  @override
  State<QuranSettingsTab> createState() => _QuranSettingsTabState();
}

class _QuranSettingsTabState extends State<QuranSettingsTab> {
  Future<void> _changeQiraa(BuildContext context, String qiraaKey) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.quranType == qiraaKey) return;

    final isDownloaded = await QuranService.isQiraaDownloaded(qiraaKey);
    if (!context.mounted) return;

    if (isDownloaded) {
      VibrationService.triggerHaptic(settings, type: HapticType.selection);
      await settings.setQuranType(qiraaKey);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "تم تغيير الرواية إلى: ${settings.qiraaName}",
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF003527),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _showDownloadDialog(context, qiraaKey, settings);
  }

  void _showDownloadDialog(
      BuildContext context, String qiraaKey, SettingsProvider settings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        double progress = 0.0;
        bool isError = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (progress == 0.0 && !isError) {
              QuranService.downloadQiraa(qiraaKey, (p) {
                setDialogState(() => progress = p);
              }).then((_) async {
                await settings.setQuranType(qiraaKey);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "تم تغيير الرواية إلى: ${settings.qiraaName}",
                          style: GoogleFonts.cairo(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF003527),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }).catchError((err) {
                setDialogState(() => isError = true);
              });
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isError ? "فشل التحميل" : "جاري تحميل المصحف...",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isError) ...[
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                        "حدث خطأ أثناء تحميل الرواية. يرجى التحقق من الاتصال والمحاولة لاحقاً.",
                        style: GoogleFonts.cairo(fontSize: 13),
                        textAlign: TextAlign.center),
                  ] else ...[
                    LinearProgressIndicator(
                        value: progress,
                        color: const Color(0xFF003527),
                        backgroundColor: Colors.grey[200]),
                    const SizedBox(height: 12),
                    Text("%${(progress * 100).toInt()}",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ]
                ],
              ),
              actions: [
                if (isError)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppStrings.close,
                        style: GoogleFonts.cairo(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),

              ],
            );
          },
        );
      },
    );
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
                const Icon(Icons.menu_book_rounded,
                    color: Color(0xFFC9A96E), size: 24),
                const SizedBox(width: 10),
                Text(
                  "إعدادات القرآن الكريم",
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFC9A96E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Item A: Qira'at Dropdown
            _buildQiraatDropdown(
                context, settings, primaryDarkGreen, mutedGreen, cardWhite),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),

            // Item B: Font Style Selector
            _buildFontStyleSelector(settings, primaryDarkGreen),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE1E3E2), height: 1),
            ),

            // Item C: Font Size Slider & Live Preview Card
            _buildFontSizeSlider(
                context, settings, primaryDarkGreen, mutedGreen),
          ],
        );
      },
    );
  }

  Widget _buildQiraatDropdown(BuildContext context, SettingsProvider settings,
      Color primaryDarkGreen, Color mutedGreen, Color cardWhite) {
    final riwayat = {
      'hafs': 'حفص عن عاصم',
      'warsh': 'ورش عن نافع',
      'qaloun': 'قالون عن نافع',
      'shuba': 'شعبة عن عاصم',
      'sousi': 'السوسي عن أبي عمرو',
      'douri': 'الدوري عن أبي عمرو',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("الرواية",
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryDarkGreen)),
              Text("اختر القراءة المفضلة",
                  style:
                      GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: mutedGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: settings.quranType,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: primaryDarkGreen),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: primaryDarkGreen,
                    fontSize: 13),
                dropdownColor: cardWhite,
                borderRadius: BorderRadius.circular(12),
                items: riwayat.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _changeQiraa(context, val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontStyleSelector(
      SettingsProvider settings, Color primaryDarkGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("نوع الخط",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryDarkGreen)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FontSelectionCard(
                title: "القرآن العثماني",
                isSelected: settings.quranFontStyleIndex == 0,
                onTap: () => settings.setQuranFontStyleIndex(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FontSelectionCard(
                title: "القرآن النسخ",
                isSelected: settings.quranFontStyleIndex == 1,
                onTap: () => settings.setQuranFontStyleIndex(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FontSelectionCard(
                title: "القرآن بسيط",
                isSelected: settings.quranFontStyleIndex == 2,
                onTap: () => settings.setQuranFontStyleIndex(2),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFontSizeSlider(BuildContext context, SettingsProvider settings,
      Color primaryDarkGreen, Color mutedGreen) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("حجم الخط",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: mutedGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text("A-",
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
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
                    value: settings.fontSize,
                    min: 18.0,
                    max: 45.0,
                    onChanged: (val) => settings.setFontSize(val),
                  ),
                ),
              ),
              Text("A+",
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ✅ Live Font Preview Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryDarkGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text("معاينة الخط",
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                textAlign: TextAlign.center,
                style: settings.currentFontFamily == 'Amiri'
                    ? GoogleFonts.amiri(
                        fontSize: settings.fontSize,
                        color: c.textPrimary,
                      )
                    : TextStyle(
                        fontFamily: settings.currentFontFamily,
                        fontSize: settings.fontSize,
                        color: c.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FontSelectionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontSelectionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryDarkGreen =
        isDark ? const Color(0xFFC5A059) : const Color(0xFF003527);
    final mutedGreen =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0EC);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryDarkGreen : mutedGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryDarkGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
