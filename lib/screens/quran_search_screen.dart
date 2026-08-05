import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ ضروري
import '../services/settings_provider.dart'; // ✅ ضروري
import '../services/quran_service.dart';
import 'quran_reading_screen.dart';
import '../services/app_colors.dart';
import '../constants/app_strings.dart';


class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  List<dynamic> _allVerses = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _loadedJsonPath;

  // Colors
  final Color _primaryColor = const Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        _loadedJsonPath = settings.currentJsonPath;
        await QuranService.loadQuran(_loadedJsonPath!);
      }
      var pages = QuranService.getGlobalPages();

      List<dynamic> tempVerses = [];
      for (var page in pages) {
        tempVerses.addAll(page.verses);
      }

      if (mounted) {
        setState(() {
          _allVerses = tempVerses;
          _isLoading = false;
          _hasError = tempVerses.isEmpty;
        });
        if (_controller.text.trim().isNotEmpty) {
          _search(_controller.text);
        }
      }
    } catch (e) {
      debugPrint("Error loading search data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(query);
    });
  }

  String _normalizeArabic(String text) {
    String data = text;
    // 1. Remove Tashkeel, Harakat, Dagger Alef, Maddah, Hamza marks, Small High letters & Quranic symbols
    data = data.replaceAll(
        RegExp(
            r'[\u0610-\u061A\u064B-\u065F\u0670\u0671\u0640\u0653-\u0655\u06D6-\u06ED\u06E5-\u06E8]'),
        '');

    // 2. Normalize Alef variants
    data = data.replaceAll(RegExp(r'[أإآٱٲٳ]'), 'ا');

    // 3. Normalize Teh Marbuta & Yeh & Waw/Hamza
    data = data.replaceAll('ة', 'ه');
    data = data.replaceAll('ى', 'ي');
    data = data.replaceAll('ئ', 'ي');
    data = data.replaceAll('ؤ', 'و');
    data = data.replaceAll('ء', '');

    // 4. Uthmani orthography mappings (e.g. ابرهيم / ابرهم -> ابراهيم)
    data = data.replaceAll('ابرهيم', 'ابراهيم');
    data = data.replaceAll('ابرهم', 'ابراهيم');
    data = data.replaceAll('الرحمن', 'الرحمان');
    data = data.replaceAll('سموت', 'سموات');
    data = data.replaceAll('صلوه', 'صلاه');
    data = data.replaceAll('زكوه', 'زكاه');
    data = data.replaceAll('حيوه', 'حياه');

    // 5. Strip non-Arabic alphanumeric and collapse whitespaces
    data = data.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
    data = data.replaceAll(RegExp(r'\s+'), ' ');
    return data.trim().toLowerCase();
  }

  void _search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    final normalizedQuery = _normalizeArabic(trimmed);
    if (normalizedQuery.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    final results = _allVerses.where((verse) {
      final textEmlaey = (verse['aya_text_emlaey'] ?? '').toString();
      final textOthmani = (verse['aya_text'] ?? '').toString();
      final normEmlaey = _normalizeArabic(textEmlaey);
      final normOthmani = _normalizeArabic(textOthmani);
      return normEmlaey.contains(normalizedQuery) ||
          normOthmani.contains(normalizedQuery);
    }).toList();

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final c = AppColors.of(context);

    if (_loadedJsonPath != null &&
        _loadedJsonPath != settings.currentJsonPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.cardBg,
        elevation: 0,
        leading: BackButton(color: c.textPrimary),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "ابحث في القرآن الكريم...",
            border: InputBorder.none,
            hintStyle: GoogleFonts.cairo(color: c.textMuted),
          ),
          style: GoogleFonts.cairo(color: c.textPrimary),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _controller.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : _hasError
              ? _buildErrorRetry(context)
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 80,
                              color: c.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 10),
                          Text(
                            _controller.text.isEmpty
                                ? "اكتب كلمة للبحث"
                                : "لا توجد نتائج للبحث",
                            style: GoogleFonts.cairo(
                                color: c.textMuted, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final verse = _searchResults[index];
                        return _buildResultItem(verse, settings);
                      },
                    ),
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
          Text("تعذر تحميل بيانات البحث",
              style: GoogleFonts.cairo(color: c.textPrimary, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppStrings.retry,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(dynamic verse, SettingsProvider settings) {
    final c = AppColors.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: c.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuranReadingScreen(
                initialSurahId: verse['sura_no'],
                highlightAyahId: verse['id'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "سورة ${verse['sura_name_ar']}",
                      style: GoogleFonts.cairo(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "الآية ${settings.replaceDigits(verse['aya_no'].toString())}",
                    style: GoogleFonts.cairo(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                verse['aya_text'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: settings.currentFontFamily == 'Amiri'
                    ? GoogleFonts.amiri(
                        fontSize: 18,
                        color: c.textPrimary,
                      )
                    : TextStyle(
                        fontFamily: settings.currentFontFamily,
                        fontSize: 18,
                        color: c.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
