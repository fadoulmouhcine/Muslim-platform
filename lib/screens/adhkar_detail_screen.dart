import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ ضروري
import '../models/adhkar_data.dart';
import '../services/settings_provider.dart'; // ✅ ضروري
import '../services/vibration_service.dart';
import '../theme/theme.dart';

class AdhkarDetailScreen extends StatefulWidget {
  final String categoryTitle;

  const AdhkarDetailScreen({super.key, required this.categoryTitle});

  @override
  State<AdhkarDetailScreen> createState() => _AdhkarDetailScreenState();
}

class _AdhkarDetailScreenState extends State<AdhkarDetailScreen> {
  late List<DhikrItem> _adhkarList;
  // Hna ghan-khbbiw l-progress dyal koulla dhikr (Key: Index, Value: Current Count)
  final Map<int, int> _currentCounts = {};

  @override
  void initState() {
    super.initState();
    // Jib data 3la 7sab l-category
    _adhkarList = AdhkarData.getAdhkarByCategory(widget.categoryTitle);

    // Initialiser les compteurs
    for (int i = 0; i < _adhkarList.length; i++) {
      _currentCounts[i] = _adhkarList[i].count;
    }
  }

  void _decrementCounter(int index) {
    if (_currentCounts[index]! > 0) {
      setState(() {
        _currentCounts[index] = _currentCounts[index]! - 1;
      });

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (_currentCounts[index] == 0) {
        VibrationService.triggerHaptic(settings, type: HapticType.medium);
      } else {
        VibrationService.triggerHaptic(settings, type: HapticType.light);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. استدعاء Settings Provider
    final settings = Provider.of<SettingsProvider>(context);

    // Calcul dyal ch7al bqa total (Progress Bar l-fouq)
    int totalTarget = _adhkarList.fold(0, (sum, item) => sum + item.count);
    int totalDone = _adhkarList.asMap().entries.fold(0, (sum, entry) {
      return sum + (entry.value.count - _currentCounts[entry.key]!);
    });
    double overallProgress = totalTarget == 0 ? 1 : totalDone / totalTarget;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: overallProgress,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.secondary),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _adhkarList.length,
        itemBuilder: (context, index) {
          final item = _adhkarList[index];
          final currentCount = _currentCounts[index]!;
          final isDone = currentCount == 0;

          // ANIMATION: AnimatedOpacity bach t-tkhbba melli tsali
          return AnimatedOpacity(
            duration: const Duration(
              milliseconds: 500,
            ), // Noss taniya bach t-ghber
            opacity: isDone ? 0.3 : 1.0, // Ila salat kat-welli Chffafa
            child: isDone
                ? const SizedBox() // Ila bghitiha t-7iyyd ga3, dir Container khawi hna
                : Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: context.glassBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.glassBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _decrementCounter(
                          index,
                        ), // Cliqui f ay blassa bach t-n9oss
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. COUNTER BUTTON (Daira)
                              GestureDetector(
                                onTap: () => _decrementCounter(index),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: currentCount / item.count,
                                      backgroundColor: Colors.grey.withValues(
                                        alpha: 0.1,
                                      ),
                                      color: const Color(0xFFC5A059),
                                      strokeWidth: 5,
                                    ),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFC5A059,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          // ✅ 2. تحويل العداد
                                          settings
                                              .replaceDigits("$currentCount"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFFC5A059),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 15),

                              // 2. TEXT & INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.text,
                                      style: GoogleFonts.amiri(
                                        fontSize: 20,
                                        height: 1.8,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        // ✅ 3. تحويل عدد المرات الكلي
                                        "${item.reference} • ${settings.replaceDigits(item.count.toString())} مرات",
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
