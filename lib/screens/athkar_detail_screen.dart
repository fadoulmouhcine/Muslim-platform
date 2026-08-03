import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_colors.dart';
import '../services/hisn_muslim_service.dart';
import '../services/settings_provider.dart';
import '../services/vibration_service.dart';

class AthkarDetailScreen extends StatefulWidget {
  final HisnCategory category;

  const AthkarDetailScreen({super.key, required this.category});

  @override
  State<AthkarDetailScreen> createState() => _AthkarDetailScreenState();
}

class _AthkarDetailScreenState extends State<AthkarDetailScreen> {
  late Map<int, int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = {for (int i = 0; i < widget.category.items.length; i++) i: 0};
  }

  void _incrementCount(int index, int targetCount, SettingsProvider settings) {
    final current = _counts[index] ?? 0;
    if (current < targetCount) {
      VibrationService.triggerHaptic(settings, type: HapticType.selection);
      setState(() {
        _counts[index] = current + 1;
      });

      if (current + 1 == targetCount) {
        VibrationService.triggerHaptic(settings, type: HapticType.medium);
      }
    }
  }

  void _resetAll(SettingsProvider settings) {
    VibrationService.triggerHaptic(settings, type: HapticType.selection);
    setState(() {
      _counts = {for (int i = 0; i < widget.category.items.length; i++) i: 0};
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;
    final settings = Provider.of<SettingsProvider>(context);

    int completedCount = 0;
    for (int i = 0; i < widget.category.items.length; i++) {
      if ((_counts[i] ?? 0) >= widget.category.items[i].count) {
        completedCount++;
      }
    }

    final double progress = widget.category.items.isEmpty
        ? 0.0
        : completedCount / widget.category.items.length;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.category.title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFFC5A059), size: 22),
            onPressed: () => _resetAll(settings),
            tooltip: "إعادة تعيين الأذكار",
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : const Color(0xFFFAF8F5),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFC5A059)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  settings.replaceDigits(
                      "$completedCount / ${widget.category.items.length}"),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC5A059),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: widget.category.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = widget.category.items[index];
                final countDone = _counts[index] ?? 0;
                final isCompleted = countDone >= item.count;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFC5A059)
                            .withValues(alpha: isDark ? 0.12 : 0.06)
                        : c.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFFC5A059).withValues(alpha: 0.6)
                          : (isDark ? c.borderColor : const Color(0xFFE2E8F0)),
                      width: isCompleted ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCompleted
                            ? const Color(0xFFC5A059)
                                .withValues(alpha: isDark ? 0.12 : 0.05)
                            : c.shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Zikr Text
                      Text(
                        item.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                          height: 1.85,
                        ),
                      ),

                      if (item.footnote.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        Text(
                          item.footnote,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: c.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Counter Button / Completed Pill
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFC5A059),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 1,
                          ),
                          onPressed: () =>
                              _incrementCount(index, item.count, settings),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCompleted) ...[
                                const Icon(Icons.check_circle_rounded,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "مكتمل",
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                const Icon(Icons.fingerprint_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "التكرار: ${settings.replaceDigits('$countDone')} / ${settings.replaceDigits('${item.count}')}",
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
