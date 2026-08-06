import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:muslim/models/daily_athar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_colors.dart';
import '../services/settings_provider.dart';

class DailyHarvestScreen extends StatefulWidget {
  const DailyHarvestScreen({super.key});

  @override
  State<DailyHarvestScreen> createState() => _DailyHarvestScreenState();
}

class _DailyHarvestScreenState extends State<DailyHarvestScreen> {
  static const double _greatScoreThreshold = 0.8;
  static const double _goodScoreThreshold = 0.5;

  List<DailyAthar> _questions = [];
  final Map<int, bool> _answers = {};
  final Map<int, bool> _autoDetected = {};
  
  bool _isLoading = true;
  bool _isSubmitted = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _todayDate = '';

  // History data: Map of Date -> Score (0.0 to 1.0)
  Map<String, double> _historyScores = {};

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/daily_athar.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;
      setState(() {
        _questions = jsonList.map((json) => DailyAthar.fromJson(json)).toList();
      });

      await _checkHistory(prefs);
      await _checkTodayStatus(prefs);
    } catch (e) {
      debugPrint('Error loading Daily Harvest: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'تعذر تحميل بيانات حصاد اليوم. يرجى المحاولة لاحقاً.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkHistory(SharedPreferences prefs) async {
    final history = <String, double>{};
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dataStr = prefs.getString('daily_harvest_data_$dateKey');
      if (dataStr != null) {
        try {
          final data = json.decode(dataStr);
          history[dateKey] = (data['score'] as num).toDouble();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _historyScores = history;
    });
  }

  Future<void> _checkTodayStatus(SharedPreferences prefs) async {
    final todayDataStr = prefs.getString('daily_harvest_data_$_todayDate');

    if (todayDataStr != null) {
      final data = json.decode(todayDataStr);
      final savedAnswers = (data['answers'] as Map<String, dynamic>);

      if (!mounted) return;
      setState(() {
        _isSubmitted = true;
        for (var q in _questions) {
          if (savedAnswers.containsKey(q.id.toString())) {
            _answers[q.id] = savedAnswers[q.id.toString()];
          }
        }
      });
    } else {
      await _runAutoTracking(prefs);
    }
  }

  Future<void> _runAutoTracking(SharedPreferences prefs) async {
    for (var q in _questions) {
      if (q.autoTrackKey != null) {
        final trackKey = '${q.autoTrackKey}_$_todayDate';
        final isDone = prefs.getBool(trackKey) ?? false;

        if (isDone) {
          if (!mounted) return;
          setState(() {
            _answers[q.id] = true;
            _autoDetected[q.id] = true;
          });
        }
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    int correctCount = 0;
    for (var q in _questions) {
      if (_answers[q.id] == q.targetAnswer) {
        correctCount++;
      }
    }
    final double score =
        _questions.isEmpty ? 0 : correctCount / _questions.length;

    final data = {
      'date': _todayDate,
      'score': score,
      'answers': _answers.map((k, v) => MapEntry(k.toString(), v)),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString('daily_harvest_data_$_todayDate', json.encode(data));

    if (!mounted) return;
    setState(() {
      _isSubmitted = true;
      _historyScores[_todayDate] = score;
    });
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) {
        final c = AppColors.of(context);
        return AlertDialog(
          backgroundColor: c.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "تأكيد الحصاد",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: c.textPrimary),
          ),
          content: Text(
            "هل أنت متأكد من رغبتك في حفظ حصاد اليوم؟ لا يمكن تعديل الإجابات بعد الحفظ.",
            style: GoogleFonts.cairo(fontSize: 16, color: c.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "إلغاء",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: c.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveProgress();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primaryDarkGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "تأكيد وحفظ",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onAnswer(int questionId, bool answer) {
    setState(() {
      _answers[questionId] = answer;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'حصاد اليوم',
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: c.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorView();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHistoryGraph(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _isSubmitted ? _buildSummaryView() : _buildQuizView(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 16, color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text("إعادة المحاولة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primaryDarkGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryGraph() {
    final now = DateTime.now();
    final days = List.generate(30, (i) {
      return now.subtract(Duration(days: 29 - i));
    });

    final c = AppColors.of(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.replaceDigits('سجّل الـ 30 يوماً الماضية'),
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: c.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((date) => _buildDayDot(date, settings)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(DateTime date, SettingsProvider settings) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final score = _historyScores[dateKey];
    final c = AppColors.of(context);

    Color color = c.isDark ? c.borderColor : Colors.grey[300]!;
    double barHeight = 6.0;
    String semanticsLabel = 'لم يتم تسجيل بيانات';

    if (score != null) {
      barHeight = math.max(8.0, score * 30.0);
      final int percentage = (score * 100).round();
      semanticsLabel = settings.replaceDigits('أداء $dateKey: $percentage٪');
      
      if (score >= _greatScoreThreshold) {
        color = Colors.green.shade500;
      } else if (score >= _goodScoreThreshold) {
        color = Colors.orange.shade400;
      } else {
        color = Colors.red.shade400;
      }
    }

    return Semantics(
      label: semanticsLabel,
      child: Container(
        width: 6,
        height: barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (idx) {
        setState(() {
          _currentIndex = idx;
        });
      },
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return _buildQuestionCard(_questions[index]);
      },
    );
  }

  Widget _buildQuestionCard(DailyAthar question) {
    final bool? currentAnswer = _answers[question.id];
    final bool isAuto = _autoDetected[question.id] ?? false;

    final c = AppColors.of(context);
    final isDark = c.isDark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.cardBg,
        gradient: LinearGradient(
          colors: [
            c.cardBg,
            isDark ? c.cardBg.withValues(alpha: 0.8) : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor.withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isAuto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.green.shade800 : Colors.green.shade200)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: isDark ? Colors.greenAccent : Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'تم الرصد تلقائياً',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark ? Colors.greenAccent : Colors.green[800],
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Text(
            question.emoji,
            style: const TextStyle(fontSize: 72),
          ),
          const SizedBox(height: 24),
          Text(
            question.category,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: c.goldAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  label: 'لا',
                  color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50,
                  textColor: isDark ? Colors.redAccent : Colors.red,
                  isSelected: currentAnswer == false,
                  onTap: () => _onAnswer(question.id, false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnswerButton(
                  label: 'نعم',
                  color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
                  textColor: isDark ? Colors.greenAccent : Colors.green,
                  isSelected: currentAnswer == true,
                  onTap: () => _onAnswer(question.id, true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_currentIndex == _questions.length - 1)
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                child: ElevatedButton(
                  onPressed:
                      _answers.length == _questions.length ? _confirmSubmit : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: c.primaryDarkGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.borderColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: Text(
                    'حفظ الحصاد',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? textColor : color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? textColor : textColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: textColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    final score = _historyScores[_todayDate] ?? 0.0;
    int percentage = (score * 100).round();

    final c = AppColors.of(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = c.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.cardBg,
        gradient: LinearGradient(
          colors: [
            c.cardBg,
            isDark ? c.cardBg.withValues(alpha: 0.8) : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor.withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, size: 80, color: isDark ? Colors.greenAccent : Colors.green),
          ),
          const SizedBox(height: 32),
          Text(
            'تم حفظ حصاد اليوم',
            style: GoogleFonts.cairo(
              fontSize: 26,
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? c.primaryDarkGreen.withValues(alpha: 0.2) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              settings.replaceDigits('أداء اليوم: $percentage٪'),
              style: GoogleFonts.cairo(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: c.goldAccent,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            percentage >= (_greatScoreThreshold * 100)
                ? 'ما شاء الله! استمر على هذا الخير.'
                : percentage >= (_goodScoreThreshold * 100)
                    ? 'جيد، ولكن يمكنك التحسن أكثر!'
                    : 'حاول أن تجتهد أكثر غداً، الله يوفقك.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
