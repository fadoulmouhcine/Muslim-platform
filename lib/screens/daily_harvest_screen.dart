import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim/models/daily_athar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_colors.dart';

class DailyHarvestScreen extends StatefulWidget {
  const DailyHarvestScreen({super.key});

  @override
  State<DailyHarvestScreen> createState() => _DailyHarvestScreenState();
}

class _DailyHarvestScreenState extends State<DailyHarvestScreen> {
  List<DailyAthar> _questions = [];
  final Map<int, bool> _answers = {};
  final Map<int, bool> _autoDetected = {};
  bool _isLoading = true;
  bool _isSubmitted = false;
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

      setState(() {
        _questions = jsonList.map((json) => DailyAthar.fromJson(json)).toList();
      });

      await _checkHistory();
      await _checkTodayStatus();
    } catch (e) {
      debugPrint('Error loading Daily Harvest: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = <String, double>{};

    // Check last 30 days
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

    setState(() {
      _historyScores = history;
    });
  }

  Future<void> _checkTodayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayDataStr = prefs.getString('daily_harvest_data_$_todayDate');

    if (todayDataStr != null) {
      // Already submitted today
      final data = json.decode(todayDataStr);
      final savedAnswers = (data['answers'] as Map<String, dynamic>);

      setState(() {
        _isSubmitted = true;
        for (var q in _questions) {
          if (savedAnswers.containsKey(q.id.toString())) {
            _answers[q.id] = savedAnswers[q.id.toString()];
          }
        }
      });
    } else {
      // Not submitted, run auto-tracking
      await _runAutoTracking(prefs);
    }
  }

  Future<void> _runAutoTracking(SharedPreferences prefs) async {
    for (var q in _questions) {
      if (q.autoTrackKey != null) {
        final trackKey = '${q.autoTrackKey}_$_todayDate';
        final isDone = prefs.getBool(trackKey) ?? false;

        if (isDone) {
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

    // Calculate Score
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

    setState(() {
      _isSubmitted = true;
      _historyScores[_todayDate] = score;
    });
  }

  void _onAnswer(int questionId, bool answer) {
    setState(() {
      _answers[questionId] = answer;
    });

    // Auto advance after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHistoryGraph(),
                  const SizedBox(height: 20),
                  _isSubmitted ? _buildSummaryView() : _buildQuizView(),
                ],
              ),
            ),
    );
  }

  Widget _buildHistoryGraph() {
    final now = DateTime.now();
    // Build list of last 30 days
    final days = List.generate(30, (i) {
      return now.subtract(Duration(days: 29 - i));
    });

    final c = AppColors.of(context);
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجّل الـ 30 يوماً الماضية',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: c.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) => _buildDayDot(date)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final score = _historyScores[dateKey];
    final c = AppColors.of(context);

    Color color = c.isDark ? c.borderColor : Colors.grey[200]!;
    if (score != null) {
      if (score >= 0.8) {
        color = Colors.green;
      } else if (score >= 0.5) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
    }

    return Container(
      width: 6,
      height: 20, // tall bars
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildQuizView() {
    return SizedBox(
      height: 500,
      child: PageView.builder(
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
      ),
    );
  }

  Widget _buildQuestionCard(DailyAthar question) {
    final bool? currentAnswer = _answers[question.id];
    final bool isAuto = _autoDetected[question.id] ?? false;

    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isAuto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'تم الرصد تلقائياً',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            question.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 24),
          Text(
            question.category,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: c.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.3,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  label: 'لا',
                  color: c.isDark
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.red.shade50,
                  textColor: Colors.red,
                  isSelected: currentAnswer == false,
                  onTap: () => _onAnswer(question.id, false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnswerButton(
                  label: 'نعم',
                  color: c.isDark
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.green.shade50,
                  textColor: Colors.green,
                  isSelected: currentAnswer == true,
                  onTap: () => _onAnswer(question.id, true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Show "Finish" button if it's the last page
          if (_currentIndex == _questions.length - 1)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _answers.length == _questions.length ? _saveProgress : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        c.isDark ? c.primaryDarkGreen : const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? textColor : color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? textColor : textColor.withValues(alpha: 0.3),
            width: 2,
          ),
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
    );
  }

  Widget _buildSummaryView() {
    final score = _historyScores[_todayDate] ?? 0.0;
    int percentage = (score * 100).round();

    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'تم حفظ حصاد اليوم',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'أداء اليوم: $percentage%',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: c.isDark ? c.goldAccent : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            percentage >= 80
                ? 'ما شاء الله! استمر على هذا الخير.'
                : percentage >= 50
                    ? 'جيد، ولكن يمكنك التحسن أكثر!'
                    : 'حاول أن تجتهد أكثر غداً، الله يوفقك.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
