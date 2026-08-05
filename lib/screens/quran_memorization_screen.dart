import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ H-02: needed for SettingsProvider
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/settings_provider.dart'; // ✅ H-02
import '../services/app_colors.dart';
import '../services/quran_service.dart';
import '../constants/app_strings.dart';


class QuranMemorizationScreen extends StatefulWidget {
  const QuranMemorizationScreen({super.key});

  @override
  State<QuranMemorizationScreen> createState() =>
      _QuranMemorizationScreenState();
}

class _QuranMemorizationScreenState extends State<QuranMemorizationScreen> {
  late stt.SpeechToText _speech;

  // حالات التحكم
  bool _isListening = false;
  bool _isPaused = false;
  bool _sessionStarted = false;
  bool _manuallyStopped = false;
  bool _hardwareMicRunning = false;

  // النصوص
  String _accumulatedText = "";
  String _currentWords = "";

  // البيانات
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _currentAyahs = [];

  bool _isLoading = true;
  int _selectedIndex = -1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // ✅ H-02 FIX: defer load until after first frame so SettingsProvider is accessible.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuranData());
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuranData() async {
    try {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await QuranService.loadQuran(settings.currentJsonPath);
      final pages = QuranService.getGlobalPages();

      Map<int, Map<String, dynamic>> groupedSurahs = {};

      for (var page in pages) {
        for (var item in page.verses) {
          int suraNo = item['sura_no'];
          String suraName = item['sura_name_ar'];

          Map<String, dynamic> ayahData = {
            'text_othmani': item['aya_text'],
            'text_emlaey': item['aya_text_emlaey'] ?? item['aya_text'],
            'aya_no': item['aya_no'],
            'is_revealed': false,
          };

          if (!groupedSurahs.containsKey(suraNo)) {
            groupedSurahs[suraNo] = {
              'name': suraName,
              'ayahs': <Map<String, dynamic>>[],
            };
          }
          groupedSurahs[suraNo]!['ayahs'].add(ayahData);
        }
      }

      List<Map<String, dynamic>> finalSurahs = [];
      groupedSurahs.forEach((key, value) {
        finalSurahs.add({
          "name": value['name'],
          "ayahs": value['ayahs'],
        });
      });

      if (mounted) {
        setState(() {
          _surahs = finalSurahs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading Quran JSON in memorization: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _selectedIndex == -1
              ? "اختر السورة للحفظ"
              : (_surahs.isNotEmpty && _selectedIndex < _surahs.length
                  ? _surahs[_selectedIndex]['name']
                  : ""),
          style: GoogleFonts.amiri(
              color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.textPrimary),
        leading: _selectedIndex != -1
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: c.textPrimary),
                onPressed: () {
                  setState(() {
                    _selectedIndex = -1;
                    _resetSession();
                  });
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC5A059)))
          : _surahs.isEmpty
              ? _buildErrorRetry(context)
              : (_selectedIndex == -1
                  ? _buildSurahList(context)
                  : _buildQuranPage(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _selectedIndex != -1 ? _buildControlButtons() : null,
    );
  }

  Widget _buildErrorRetry(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text("تعذر تحميل بيانات القرآن",
              style: GoogleFonts.cairo(color: c.textPrimary, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadQuranData();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppStrings.retry,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.white),

          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildControlButtons() {
    if (!_sessionStarted) {
      return AvatarGlow(
        animate: false,
        glowColor: const Color(0xFFC5A059),
        duration: const Duration(milliseconds: 2000),
        child: FloatingActionButton.extended(
          onPressed: _startSession,
          backgroundColor: const Color(0xFFC5A059),
          icon: const Icon(Icons.mic, size: 30),
          label: Text("ابدأ الحفظ",
              style:
                  GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: _togglePause,
            backgroundColor: _isPaused ? Colors.green : Colors.orange,
            child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 35),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: "btn3",
            onPressed: () {
              setState(() {
                for (var ayah in _currentAyahs) {
                  ayah['is_revealed'] = false;
                }
                _resetSession();
              });
            },
            backgroundColor: Colors.grey,
            mini: true,
            child: const Icon(Icons.refresh, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(BuildContext context) {
    final c = AppColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _surahs.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 2,
          color: c.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFC5A059).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text("${index + 1}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC5A059))),
              ),
            ),
            title: Text(
              _surahs[index]['name'],
              style: GoogleFonts.amiri(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: c.textPrimary),
            ),
            trailing:
                Icon(Icons.arrow_forward_ios, size: 16, color: c.textSecondary),
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _currentAyahs = List.from(_surahs[index]['ayahs']);
                for (var ayah in _currentAyahs) {
                  ayah['is_revealed'] = false;
                }
                _resetSession();
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildQuranPage(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: Image.asset('assets/images/pattern.png',
                fit: BoxFit.cover, errorBuilder: (c, o, s) => Container()),
          ),
        ),
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            children: [
              if (_selectedIndex != 8)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                    style:
                        GoogleFonts.amiri(fontSize: 24, color: c.textPrimary),
                  ),
                ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 10,
                  spacing: 5,
                  children: _currentAyahs.map((ayah) {
                    bool isRevealed = ayah['is_revealed'];
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: 1.0,
                      child: isRevealed
                          ? Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: ayah['text_othmani'] + " ",
                                    style: GoogleFonts.amiri(
                                      fontSize: 26,
                                      color: c.textPrimary,
                                      height: 1.8,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "﴿${ayah['aya_no']}﴾ ",
                                    style: GoogleFonts.amiri(
                                      fontSize: 22,
                                      color: const Color(0xFFD4AF37),
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          Colors.grey.withValues(alpha: 0.3))),
                              child: Text(
                                "${ayah['aya_no']}",
                                style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: c.textSecondary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        if (_sessionStarted && !_isPaused)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: const Color(0xFFC5A059).withValues(alpha: 0.5),
              minHeight: 4,
            ),
          ),
      ],
    );
  }

  // --- LOGIC ---

  void _resetSession() {
    _manuallyStopped = true;
    _speech.stop();
    _accumulatedText = "";
    _currentWords = "";
    _sessionStarted = false;
    _isPaused = false;
    _isListening = false;
    _hardwareMicRunning = false;
  }

  void _startSession() async {
    _manuallyStopped = false;
    _startListeningInternal();
  }

  void _startListeningInternal() async {
    if (_manuallyStopped || _isPaused) return;
    if (_hardwareMicRunning) return;

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'listening') {
          _hardwareMicRunning = true;
        } else if (val == 'done' || val == 'notListening') {
          _hardwareMicRunning = false;
          if (_isListening && !_isPaused) {
            if (mounted) {
              setState(() {
                if (_currentWords.isNotEmpty) {
                  _accumulatedText = "$_accumulatedText $_currentWords";
                  _currentWords = "";
                }
              });
            }
            _startListeningInternal();
          }
        }
      },
      onError: (val) {
        _hardwareMicRunning = false;
        if (_isListening && !_isPaused) {
          Future.delayed(const Duration(milliseconds: 500),
              () => _startListeningInternal());
        }
      },
    );

    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "تعذر الوصول للميكروفون. المرجو تفعيل إذن الميكروفون من الإعدادات.",
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (available) {
      setState(() {
        _sessionStarted = true;
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _currentWords = result.recognizedWords;
              _checkAndRevealVerses();
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          autoPunctuation: false,
          localeId: 'ar_SA',
          pauseFor: const Duration(minutes: 5),
        ),
      );
    }
  }

  void _togglePause() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _isListening = true;
      });
      _startListeningInternal();
    } else {
      _speech.stop();
      setState(() {
        _isPaused = true;
        _accumulatedText = "$_accumulatedText $_currentWords";
        _currentWords = "";
      });
    }
  }

  void _checkAndRevealVerses() {
    String totalSpoken = "$_accumulatedText $_currentWords".trim();
    String normalizedSpoken = _normalizeArabic(totalSpoken);

    for (int i = 0; i < _currentAyahs.length; i++) {
      if (_currentAyahs[i]['is_revealed'] == false) {
        String targetAyah = _currentAyahs[i]['text_emlaey'];
        String normalizedTarget = _normalizeArabic(targetAyah);

        // ✅ استعمال contains كافي هنا عوض similarity المعقد
        bool isMatch = normalizedSpoken.contains(normalizedTarget);

        if (isMatch) {
          setState(() {
            _currentAyahs[i]['is_revealed'] = true;
          });

          if (_scrollController.hasClients) {
            _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 50,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut);
          }
        } else {
          break;
        }
      }
    }
  }

  String _normalizeArabic(String text) {
    String data = text;
    data = data.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    data = data.replaceAll(RegExp(r'[أإآ]'), 'ا');
    data = data.replaceAll('ة', 'ه');
    data = data.replaceAll('ى', 'ي');
    data = data.replaceAll('ؤ', 'و');
    data = data.replaceAll('ئ', 'ي');
    data = data.replaceAll(RegExp(r'[^\w\s]'), '');
    data = data.replaceAll(RegExp(r'\s+'), ' ');
    return data.trim();
  }
}
