import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../services/settings_provider.dart';
import '../services/tafsir_service.dart';
import '../services/quran_meta_data.dart';
import '../services/tajweed_service.dart';
import '../services/quran_audio_service.dart';

class QuranReadingScreen extends StatefulWidget {
  final int initialSurahId;
  final int initialPageIndex;
  final int? highlightAyahId;

  const QuranReadingScreen({
    super.key,
    this.initialSurahId = 1,
    this.initialPageIndex = -1,
    this.highlightAyahId,
  });

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  List<QuranPage> _allPages = [];
  int _currentPageIndex = 0;

  String _popupText = "";
  bool _showPopup = false;
  Timer? _popupTimer;
  String _currentHeaderInfo = "";

  late AnimationController _animController;
  late Animation<Color?> _colorAnimation;

  int? _targetAyahId;
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _surahStartKey = GlobalKey();
  bool _shouldHighlight = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showBars = true;

  void _toggleBars() {
    setState(() {
      _showBars = !_showBars;
    });
  }

  final QuranAudioService _audioService = QuranAudioService();

  int? _bookmarkedPageIndex;

  @override
  void initState() {
    super.initState();
    _targetAyahId = widget.highlightAyahId;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: const Color(0xFFD4AF37).withValues(alpha: 0.5),
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    _ensureDataReady();
  }

  Future<void> _ensureDataReady() async {
    try {
      final b = await StorageService.getBookmark();
      if (b != null && b['page_index'] != null) {
        _bookmarkedPageIndex = (b['page_index'] as num).toInt();
      }

      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await QuranService.loadQuran(settings.currentJsonPath);
      _allPages = QuranService.getGlobalPages();

      if (_allPages.isEmpty) {
        debugPrint(
            "⚠️ Warning: Data empty for ${settings.qiraaName}, loading fallback (Hafs)...");
        await QuranService.loadQuran('assets/json/quran/hafs.json',
            forceReload: true);
        _allPages = QuranService.getGlobalPages();

        if (mounted && _allPages.isNotEmpty) {
          final qiraaName = settings.qiraaName;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "تعذر تحميل $qiraaName، تم عرض رواية حفص بدلاً منها",
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.orange[800],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      }

      if (_allPages.isNotEmpty) {
        if (_targetAyahId != null) {
          _shouldHighlight = true;
          int foundIndex = _findPageIndexByGlobalId(_targetAyahId!);
          if (foundIndex != -1) {
            _currentPageIndex = foundIndex;
          } else {
            _currentPageIndex =
                QuranService.getStartPageIndexForSurah(widget.initialSurahId);
          }
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _executeMagicScroll());
        } else if (widget.initialPageIndex != -1) {
          _currentPageIndex = widget.initialPageIndex;
        } else {
          _currentPageIndex =
              QuranService.getStartPageIndexForSurah(widget.initialSurahId);
          if (_currentPageIndex == -1) _currentPageIndex = 0;
        }
      }

      _pageController = PageController(initialPage: _currentPageIndex);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = _allPages.isEmpty;
        });

        if (!_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateHeaderInfo(_currentPageIndex);
            _checkAndTriggerPopup(_currentPageIndex);
            _autoSaveLastRead(_currentPageIndex);
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error in _ensureDataReady: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  int _findPageIndexByGlobalId(int id) {
    if (_allPages.isEmpty) return -1;
    return _allPages
        .indexWhere((page) => page.verses.any((v) => v['id'] == id));
  }

  void _executeMagicScroll() async {
    if (!_shouldHighlight || _targetKey.currentContext == null) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (_targetKey.currentContext != null) {
      await Scrollable.ensureVisible(
        _targetKey.currentContext!,
        duration: const Duration(milliseconds: 800),
        alignment: 0.4,
        curve: Curves.easeInOutCubic,
      );
    }
    for (int i = 0; i < 2; i++) {
      await _animController.forward();
      await _animController.reverse();
    }
    if (mounted) {
      setState(() => _shouldHighlight = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _popupTimer?.cancel();
    _animController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _updateHeaderInfo(int index) {
    if (_allPages.isEmpty || index >= _allPages.length) return;
    var page = _allPages[index];
    var firstVerse = page.verses.first;
    setState(() {
      _currentHeaderInfo = QuranMetaData.getCurrentJuzAndHizbLabel(
          page.surahId, firstVerse['aya_no']);
    });
  }

  void _checkAndTriggerPopup(int index) {
    if (_allPages.isEmpty || index >= _allPages.length) return;
    var page = _allPages[index];
    for (var verse in page.verses) {
      String? label =
          QuranMetaData.getPartitionLabel(page.surahId, verse['aya_no']);
      if (label != null) {
        setState(() {
          _popupText = label;
          _showPopup = true;
        });
        _popupTimer?.cancel();
        _popupTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showPopup = false);
        });
        break;
      }
    }
  }

  void _autoSaveLastRead(int index) {
    if (_allPages.isNotEmpty && index >= 0 && index < _allPages.length) {
      StorageService.saveLastRead(
        _allPages[index].surahId,
        _allPages[index].surahName,
        index,
      );
    }
  }

  void _saveBookmark() async {
    if (_allPages.isEmpty) return;
    final page = _allPages[_currentPageIndex];
    await StorageService.saveBookmark(
        page.surahId, page.surahName, _currentPageIndex.toDouble());
    if (mounted) {
      setState(() {
        _bookmarkedPageIndex = _currentPageIndex;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "تم حفظ العلامة المرجعية بنجاح (سورة ${page.surahName})",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFC5A059),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showReciterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("اختر القارئ",
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: QuranAudioService.reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = QuranAudioService.reciters[index];
                    return ListTile(
                      title: Text(reciter.name,
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Text("الرواية: ${reciter.riwaya}",
                          style: GoogleFonts.cairo(color: Colors.grey)),
                      leading: _audioService.currentReciter.id == reciter.id
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFFC5A059))
                          : const Icon(Icons.circle_outlined,
                              color: Colors.grey),
                      onTap: () {
                        setState(() {
                          _audioService.setReciter(reciter.id);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "تم تغيير القارئ إلى ${reciter.name} بنجاح",
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFFC5A059),
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTafsir(
      BuildContext context, int surahId, int ayahNum, String verseText) {
    int hafsAyahNum =
        QuranService.getHafsAyahNumberForTafsir(surahId, ayahNum, verseText);
    String tafsirText = TafsirService.getTafsir(surahId, hafsAyahNum);

    // ✅ استعمال replaceDigits لتحويل رقم الآية في التفسير حسب الإعدادات
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    String displayedAyahNum = settings.replaceDigits(ayahNum.toString());

    final bool isTafsirDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: isTafsirDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: isTafsirDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC5A059)
                          .withValues(alpha: isTafsirDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: const Color(0xFFC5A059)
                              .withValues(alpha: isTafsirDark ? 0.35 : 0.2))),
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFC5A059),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white),
                          onPressed: () {
                            _audioService.playAyah(surahId, ayahNum, verseText);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("استماع للآية",
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isTafsirDark
                                        ? Colors.white
                                        : const Color(0xFF2C2C2C))),
                            Text("القارئ: ${_audioService.currentReciter.name}",
                                style: GoogleFonts.cairo(
                                    color: isTafsirDark
                                        ? Colors.white54
                                        : Colors.grey[600],
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_voice,
                            color: isTafsirDark ? Colors.white54 : Colors.grey),
                        onPressed: () {
                          _showReciterSelector(context);
                        },
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 10,
                    color: isTafsirDark ? Colors.white12 : Colors.grey[300]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("التفسير الميسر",
                        style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC5A059))),
                    Row(
                      children: [
                        IconButton(
                            icon: Icon(Icons.copy_rounded,
                                color:
                                    isTafsirDark ? Colors.white54 : Colors.grey,
                                size: 22),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: "$verseText\n\n$tafsirText"));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "تم نسخ الآية والتفسير بنجاح",
                                          style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      backgroundColor: const Color(0xFFC5A059),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2)));
                            }),
                        IconButton(
                            icon: const Icon(Icons.share_rounded,
                                color: Color(0xFFC5A059), size: 22),
                            onPressed: () {
                              SharePlus.instance.share(ShareParams(
                                  text:
                                      "$verseText\n\n﴿سورة $_currentHeaderInfo﴾\n\nالتفسير الميسر:\n$tafsirText\n\nتم الإرسال عبر تطبيق مسلم"));
                            }),
                      ],
                    )
                  ],
                ),
                Divider(
                    height: 25,
                    color: isTafsirDark ? Colors.white12 : Colors.grey[300]),
                Expanded(
                  child: ListView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 25),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F2027),
                                  Color(0xFF203A43),
                                  Color(0xFF2C5364)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5))
                            ]),
                        child: Column(children: [
                          const Icon(Icons.format_quote_rounded,
                              color: Colors.white24, size: 40),
                          Text(verseText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily:
                                      Provider.of<SettingsProvider>(context)
                                          .currentFontFamily,
                                  fontSize: 22,
                                  color: Colors.white,
                                  height: 1.6)),
                          const SizedBox(height: 15),
                          Text(
                              // ✅ هنا استعملنا الرقم المعدل
                              "سورة ${_allPages.isNotEmpty ? _allPages[_currentPageIndex].surahName : ''} - الآية $displayedAyahNum",
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: Colors.white70))
                        ]),
                      ),
                      Text(tafsirText,
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              height: 1.8,
                              color: isTafsirDark
                                  ? Colors.white70
                                  : Colors.black87,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahHeader(String surahName, {Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const svgColor = Color(0xFFC5A059);

    return Container(
      key: key,
      margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/svg/Sura_border.svg',
            width: double.infinity,
            height: 65,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(svgColor, BlendMode.srcIn),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 55,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFFFDF7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF8C733E)
                          : const Color(0xFFC5A059),
                      width: 1.5),
                ),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "سورة $surahName",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SurahFont',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Settings Provider
    final settings = Provider.of<SettingsProvider>(context);

    // ✅ تحويل أرقام الهيدر (الجزء والحزب)
    String headerInfo = _currentHeaderInfo;
    if (headerInfo.isNotEmpty) {
      headerInfo = settings.replaceDigits(headerInfo);
    }

    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC5A059))));
    }

    if (_hasError || _allPages.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.grey),
              Text("تعذر تحميل البيانات", style: GoogleFonts.cairo()),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _ensureDataReady();
                },
                child: Text("إعادة المحاولة", style: GoogleFonts.cairo()),
              )
            ],
          ),
        ),
      );
    }

    final currentPage = _allPages[_currentPageIndex];
    // ✅ تحويل رقم الصفحة
    String pageNum =
        settings.replaceDigits((currentPage.pageIndex + 1).toString());

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFFFFDF5), // Warm paper color in light mode
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Stack(
            children: [
              // 100% Viewport Quran Text Page Area
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleBars,
                  behavior: HitTestBehavior.translucent,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _allPages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPageIndex = index);
                      _updateHeaderInfo(index);
                      _checkAndTriggerPopup(index);
                      _autoSaveLastRead(index);
                    },
                    itemBuilder: (context, index) {
                      return settings.isMushafMode
                          ? _buildMushafMode(
                              _allPages[index], settings, context)
                          : _buildListMode(_allPages[index], settings);
                    },
                  ),
                ),
              ),
              // Popup Notification Indicator
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _showPopup ? 1.0 : 0.0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(30)),
                        child: Text(_popupText,
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
              // Top Header Bar (Permanently Visible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.85)
                            : const Color(0xFFFFFDF7).withValues(alpha: 0.95),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF8C733E).withValues(alpha: 0.5)
                                : const Color(0xFFC5A059)
                                    .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(Icons.arrow_forward_ios,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        size: 22),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(width: 15),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                        _bookmarkedPageIndex ==
                                                _currentPageIndex
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: const Color(0xFFC5A059),
                                        size: 28),
                                    onPressed: _saveBookmark,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        headerInfo.split("•").length > 1
                                            ? headerInfo.split("•")[1].trim()
                                            : "",
                                        style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFC5A059),
                                            height: 1.0),
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        headerInfo.split("•")[0].trim(),
                                        style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF8C733E),
                                            height: 1.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                child: Text("سورة ${currentPage.surahName}",
                                    style: TextStyle(
                                        fontFamily: 'SurahFont',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF2C2C2C),
                                        height: 1.0)),
                              ),
                              Text("صفحة $pageNum",
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Modern Floating Dock Control Bar
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: true,
                  child: IgnorePointer(
                    ignoring: !_showBars,
                    child: AnimatedSlide(
                      offset: _showBars ? Offset.zero : const Offset(0, 2.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: _showBars ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF0F172A)
                                            .withValues(alpha: 0.85)
                                        : const Color(0xFFFFFDF7)
                                            .withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF8C733E)
                                              .withValues(alpha: 0.8)
                                          : const Color(0xFFC5A059)
                                              .withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          settings.isMushafMode
                                              ? Icons.view_headline_rounded
                                              : Icons.menu_book_rounded,
                                          color: const Color(0xFFC5A059),
                                        ),
                                        tooltip: settings.isMushafMode
                                            ? "وضع القائمة"
                                            : "وضع المصحف",
                                        onPressed: () =>
                                            settings.toggleViewMode(
                                                !settings.isMushafMode),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.volume_off_rounded,
                                          color: Color(0xFFC5A059),
                                        ),
                                        tooltip: "إيقاف الصوت",
                                        onPressed: () async {
                                          await _audioService.stop();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    "تم إيقاف التلاوة بنجاح",
                                                    style: GoogleFonts.cairo(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                duration:
                                                    const Duration(seconds: 2),
                                                backgroundColor:
                                                    const Color(0xFFC5A059),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.text_decrease_rounded,
                                          color: Color(0xFFC5A059),
                                        ),
                                        tooltip: "تقليل الخط",
                                        onPressed: settings.fontSize > 18
                                            ? () => settings.setFontSize(
                                                settings.fontSize - 2)
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.text_increase_rounded,
                                          color: Color(0xFFC5A059),
                                        ),
                                        tooltip: "تكبير الخط",
                                        onPressed: settings.fontSize < 45
                                            ? () => settings.setFontSize(
                                                settings.fontSize + 2)
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.bookmark_add_rounded,
                                          color: Color(0xFFC5A059),
                                        ),
                                        tooltip: "حفظ العلامة",
                                        onPressed: _saveBookmark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(
      List<dynamic> verses, SettingsProvider settings) {
    // ✅ L-01 FIX: Cache isDark ONCE before loop — avoids Theme.of(context) per verse.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);

    List<InlineSpan> spans = [];
    for (var verse in verses) {
      bool isTarget = (verse['id'] == _targetAyahId);

      if (isTarget) {
        spans.add(
            WidgetSpan(child: SizedBox(key: _targetKey, width: 0, height: 0)));
      }

      Color bgColor = isTarget && _shouldHighlight
          ? (_colorAnimation.value ?? Colors.transparent)
          : Colors.transparent;

      String verseText = verse['aya_text'];

      if (settings.isTajweedMode) {
        // ✅ C-05 FIX: Use cached textColor — correct high-contrast base for Tajweed engine.
        var tajweedSpans = TajweedService.parseTajweed(
          "$verseText ",
          settings.fontSize,
          settings.currentFontFamily,
          textColor: textColor,
        );
        spans.addAll(tajweedSpans);
      } else {
        spans.add(
          TextSpan(
            text: "$verseText ",
            style: TextStyle(
              fontFamily: settings.currentFontFamily,
              fontSize: settings.fontSize,
              color: textColor,
              height: 1.55,
              backgroundColor: bgColor,
            ),
            recognizer: LongPressGestureRecognizer()
              ..onLongPress = () => _showTafsir(
                  context, verse['sura_no'], verse['aya_no'], verseText),
          ),
        );
      }

      if (QuranMetaData.getPartitionLabel(verse['sura_no'], verse['aya_no']) !=
          null) {
        spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: const Icon(Icons.star_border,
                    color: Color(0xFFC5A059), size: 16))));
      }
    }
    return spans;
  }

  Widget _buildMushafMode(
      QuranPage page, SettingsProvider settings, BuildContext context) {
    Map<int, List<dynamic>> groupedVerses = {};
    for (var verse in page.verses) {
      int sId = verse['sura_no'];
      if (!groupedVerses.containsKey(sId)) {
        groupedVerses[sId] = [];
      }
      groupedVerses[sId]!.add(verse);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 76,
          bottom: 95,
        ),
        child: Column(
          children: [
            for (var entry in groupedVerses.entries) ...[
              Builder(builder: (context) {
                int surahId = entry.key;
                List<dynamic> verses = entry.value;
                String surahName = verses.first['sura_name_ar'];
                bool isStartOfSurah = verses.any((v) => v['aya_no'] == 1);

                bool shouldShowBasmala = true;
                if (surahId == 9) {
                  shouldShowBasmala = false;
                } else if (surahId == 1 && settings.quranType == 'hafs') {
                  shouldShowBasmala = false;
                } else {
                  shouldShowBasmala = true;
                }

                return Column(
                  children: [
                    if (isStartOfSurah)
                      _buildSurahHeader(surahName,
                          key: (surahId == widget.initialSurahId &&
                                  _targetAyahId == null)
                              ? _surahStartKey
                              : null),
                    if (isStartOfSurah && shouldShowBasmala)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                        child: Image.asset(
                          'assets/images/basmala.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(height: 20);
                          },
                        ),
                      ),
                    Text.rich(
                      TextSpan(children: _buildTextSpans(verses, settings)),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 15),
                  ],
                );
              })
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildListMode(QuranPage page, SettingsProvider settings) {
    Map<int, List<dynamic>> groupedVerses = {};
    for (var verse in page.verses) {
      int sId = verse['sura_no'];
      if (!groupedVerses.containsKey(sId)) {
        groupedVerses[sId] = [];
      }
      groupedVerses[sId]!.add(verse);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 76,
          bottom: 95,
        ),
        child: Column(
          children: [
            for (var entry in groupedVerses.entries) ...[
              Builder(builder: (context) {
                int surahId = entry.key;
                List<dynamic> verses = entry.value;
                String surahName = verses.first['sura_name_ar'];
                bool isStartOfSurah = verses.any((v) => v['aya_no'] == 1);

                bool shouldShowBasmala = true;
                if (surahId == 9) {
                  shouldShowBasmala = false;
                } else if (surahId == 1 && settings.quranType == 'hafs') {
                  shouldShowBasmala = false;
                } else {
                  shouldShowBasmala = true;
                }

                return Column(
                  children: [
                    if (isStartOfSurah)
                      _buildSurahHeader(surahName,
                          key: (surahId == widget.initialSurahId &&
                                  _targetAyahId == null)
                              ? _surahStartKey
                              : null),
                    if (isStartOfSurah && shouldShowBasmala)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Image.asset(
                          'assets/images/basmala.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(height: 20);
                          },
                        ),
                      ),
                    for (var verse in verses) ...[
                      GestureDetector(
                        onTap: _toggleBars,
                        onLongPress: () => _showTafsir(context, page.surahId,
                            verse['aya_no'], verse['aya_text']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          key: (_targetAyahId == verse['id'])
                              ? _targetKey
                              : null,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (_targetAyahId == verse['id'])
                                ? (_colorAnimation.value ??
                                    (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white))
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: (_targetAyahId == verse['id'])
                                    ? const Color(0xFFC5A059)
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF2D3748)
                                        : Colors.grey.withValues(alpha: 0.1))),
                            boxShadow: [
                              BoxShadow(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            children: [
                              settings.isTajweedMode
                                  ? RichText(
                                      text: TextSpan(
                                          children: TajweedService.parseTajweed(
                                      verse['aya_text'],
                                      settings.fontSize,
                                      settings.currentFontFamily,
                                      textColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF2C2C2C),
                                    )))
                                  : Text(verse['aya_text'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily:
                                              settings.currentFontFamily,
                                          fontSize: settings.fontSize,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : const Color(0xFF2C2C2C),
                                          height: 1.8)),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    IconButton(
                                        icon: const Icon(Icons.copy,
                                            size: 20, color: Colors.grey),
                                        onPressed: () => Clipboard.setData(
                                            ClipboardData(
                                                text: verse['aya_text']))),
                                    IconButton(
                                        icon: const Icon(Icons.share,
                                            size: 20, color: Color(0xFFC5A059)),
                                        onPressed: () => SharePlus.instance
                                            .share(ShareParams(
                                                text: verse['aya_text'])))
                                  ]),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF334155)
                                                .withValues(alpha: 0.3)
                                            : const Color(0xFFC5A059)
                                                .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(
                                        // ✅ استخدام getVerseNumber لحل المشكلة
                                        "الآية ${settings.getVerseNumber(verse['aya_no'])}",
                                        style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF8C733E),
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                );
              })
            ]
          ],
        ),
      ),
    );
  }
}
