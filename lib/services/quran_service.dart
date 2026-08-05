import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Top-level function for compute isolate
List<dynamic> _parseJsonIsolate(String jsonString) =>
    json.decode(jsonString) as List<dynamic>;

// Model
class QuranPage {
  final int surahId;
  final String surahName;
  final List<dynamic> verses;
  final int pageIndex;

  QuranPage({
    required this.surahId,
    required this.surahName,
    required this.verses,
    required this.pageIndex,
  });
}

class QuranService {
  static List<dynamic> _allVersesFlat = [];
  // ✅ المرجع ديال حفص ضروري للصوت والتفسير
  // ✅ Task 4.4: This is no longer eagerly loaded whenever a non-Hafs
  // Qira'a (Warsh, Qalun, etc.) is active. Instead it is lazy-loaded only
  // the first time it's actually needed (audio playback / Tafsir lookup)
  // via `_ensureHafsReference()`, avoiding ~604 pages of extra Quran data
  // sitting permanently in memory for users who never trigger those
  // features.
  static List<dynamic> _hafsReferenceVerses = [];
  static Future<void>? _hafsLoadingFuture;
  static final List<QuranPage> _cachedPages = [];
  static final List<Map<String, dynamic>> _surahsList = [];
  static String? _currentLoadedJsonPath;

  static final List<int> _madaniyaSurahs = [
    2,
    3,
    4,
    5,
    8,
    9,
    13,
    22,
    24,
    33,
    47,
    48,
    49,
    55,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    76,
    98,
    99,
    110
  ];

  static Future<void> loadQuran(String jsonPath,
      {bool forceReload = false}) async {
    if (!forceReload &&
        _currentLoadedJsonPath == jsonPath &&
        _allVersesFlat.isNotEmpty) {
      return;
    }

    try {
      String jsonString;
      if (jsonPath.startsWith('assets/')) {
        jsonString = await rootBundle.loadString(jsonPath);
      } else {
        final file = File(jsonPath);
        if (await file.exists()) {
          jsonString = await file.readAsString();
        } else {
          final assetPath = jsonPath.contains('assets/')
              ? jsonPath.substring(jsonPath.indexOf('assets/'))
              : 'assets/json/quran/${jsonPath.split('/').last}';
          jsonString = await rootBundle.loadString(assetPath);
        }
      }

      _allVersesFlat = await compute(_parseJsonIsolate, jsonString);
      _currentLoadedJsonPath = jsonPath;

      // ✅ Task 4.4: The Hafs reference is no longer eagerly loaded here.
      // If the loaded Qira'a IS Hafs, reuse the already-parsed verses as the
      // reference (no extra memory cost). Otherwise, the reference JSON is
      // lazy-loaded on-demand later via `_ensureHafsReference()` the first
      // time audio playback or Tafsir lookup actually needs it.
      if (jsonPath.contains('hafs')) {
        _hafsReferenceVerses = _allVersesFlat;
      }

      _buildPagesCache();
      _extractSurahs();

      debugPrint(
          "✅ Quran Data Loaded for $jsonPath: ${_allVersesFlat.length} verses");
    } catch (e) {
      debugPrint("❌ Error loading Quran JSON ($jsonPath): $e");
      rethrow;
    }
  }

  static void _buildPagesCache() {
    _cachedPages.clear();
    if (_allVersesFlat.isEmpty) return;

    Map<int, List<dynamic>> pagesMap = {};

    for (var verse in _allVersesFlat) {
      String pageStr = verse['page'].toString();
      int pageNum;
      if (pageStr.contains('-')) {
        pageNum = int.tryParse(pageStr.split('-')[0]) ?? 0;
      } else {
        pageNum = int.tryParse(pageStr) ?? 0;
      }

      if (pageNum == 0) continue;

      if (!pagesMap.containsKey(pageNum)) {
        pagesMap[pageNum] = [];
      }
      pagesMap[pageNum]!.add(verse);
    }

    var sortedKeys = pagesMap.keys.toList()..sort();

    for (int i = 0; i < sortedKeys.length; i++) {
      int pageNum = sortedKeys[i];
      List<dynamic> pageVerses = pagesMap[pageNum]!;
      if (pageVerses.isEmpty) continue;

      int surahId = pageVerses.first['sura_no'];
      String surahName = pageVerses.first['sura_name_ar'];

      _cachedPages.add(QuranPage(
        surahId: surahId,
        surahName: surahName,
        verses: pageVerses,
        pageIndex: i,
      ));
    }
  }

  static void _extractSurahs() {
    _surahsList.clear();
    Set<int> processedSurahs = {};

    for (var verse in _allVersesFlat) {
      int id = verse['sura_no'];
      if (!processedSurahs.contains(id)) {
        _surahsList.add({
          'id': id,
          'name_ar': verse['sura_name_ar'],
          'name_en': verse['sura_name_en'],
          'type': _madaniyaSurahs.contains(id) ? 'مدنية' : 'مكية',
          'verses_count': 0
        });
        processedSurahs.add(id);
      }
    }
  }

  static List<Map<String, dynamic>> searchQuran(String query) {
    if (query.isEmpty) return [];

    List<Map<String, dynamic>> results = [];
    String normalizedQuery = _normalize(query);

    for (var surah in _surahsList) {
      if (_normalize(surah['name_ar']).contains(normalizedQuery)) {
        results.add({
          'type': 'surah',
          'surah_id': surah['id'],
          'surah_name': surah['name_ar'],
          'match_text': "سورة ${surah['name_ar']}",
          'id': 0
        });
      }
    }

    int maxResults = 100;

    for (var verse in _allVersesFlat) {
      if (results.length >= maxResults) break;
      String verseTextClean = _normalize(verse['aya_text']);
      if (verseTextClean.contains(normalizedQuery)) {
        results.add({
          'type': 'ayah',
          'surah_id': verse['sura_no'],
          'surah_name': verse['sura_name_ar'],
          'ayah_number': verse['aya_no'],
          'match_text': verse['aya_text'],
          'id': verse['id'],
        });
      }
    }
    return results;
  }

  // 🔥🔥🔥 دالة التنظيف الجبارة (Super Normalizer) 🔥🔥🔥
  // كتحيد التشكيل، الرموز المغربية، ونهايات الآيات باش المقارنة تنجح
  static String _normalize(String text) {
    if (text.isEmpty) return "";
    String data = text;

    // 1. إزالة رموز نهاية الآية (مثل ﰀ) والأرقام
    // \uFC00-\uFDFF : رموز نهاية الآية المتصلة
    data = data.replaceAll(
        RegExp(r'[\uFD3E\uFD3F\u06DD\u06DE\u06E9\uFC00-\uFDFF]'), '');

    // 2. إزالة التشكيل المعقد والرموز المغربية
    // \u06EC : النقطة المصمتة (الموجودة في ورش "اِ۬")
    // \u065C : الشدة من تحت
    data = data.replaceAll(
        RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '');

    // 3. توحيد الحروف المختلف عليها
    data = data.replaceAll(RegExp(r'[أإآٱٵ]'), 'ا');
    data = data.replaceAll(RegExp(r'[ىي]'), 'ي');
    data = data.replaceAll('ة', 'ه');
    data = data.replaceAll('ؤ', 'و');
    data = data.replaceAll('ئ', 'ي');

    // 4. إزالة أي رموز غير عربية ومسافات زائدة
    data = data.replaceAll(RegExp(r'[^\u0600-\u06FF ]'), '');

    return data.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<QuranPage> getGlobalPages() => _cachedPages;
  static List<Map<String, dynamic>> getAllSurahs() => _surahsList;

  static int getStartPageIndexForSurah(int surahId) {
    int index = _cachedPages.indexWhere((page) =>
        page.verses.any((v) => v['sura_no'] == surahId && v['aya_no'] == 1));
    return index != -1 ? index : 0;
  }

  // ✅ Task 4.4: Lazily loads (and caches) the Hafs reference JSON the very
  // first time it's actually needed, instead of it being force-loaded
  // in-memory for the entire app lifetime as soon as any Quran data is
  // opened. Subsequent calls reuse the same cached in-memory data - no
  // repeat disk reads.
  static Future<List<dynamic>> _ensureHafsReference() async {
    if (_hafsReferenceVerses.isNotEmpty) return _hafsReferenceVerses;

    // Prevent duplicate concurrent loads if multiple callers request it
    // around the same time (e.g. rapid successive ayah taps).
    _hafsLoadingFuture ??= () async {
      try {
        String hafsString =
            await rootBundle.loadString('assets/json/quran/hafs.json');
        _hafsReferenceVerses = await compute(_parseJsonIsolate, hafsString);
        debugPrint("✅ Hafs Reference Loaded Lazily (Audio/Tafsir Ready)");
      } catch (e) {
        debugPrint("⚠️ Hafs JSON not found - Audio mapping might fail: $e");
      }
    }();

    await _hafsLoadingFuture;
    return _hafsReferenceVerses;
  }

  // 🔥🔥🔥 دالة تحويل الرقم للصوت 🔥🔥🔥
  static Future<int> getHafsAyahNumberForTafsir(
      int surahId, int originalAyahNum, String verseText) async {
    // ✅ Task 4.4: Lazy-load the Hafs reference on first use.
    final hafsReferenceVerses = await _ensureHafsReference();
    // إيلا كنا ديجا ف حفص، ماكنحتاجوش تحويل
    if (hafsReferenceVerses.isEmpty) return originalAyahNum;

    // نظف النص اللي جاي من (ورش/قالون)
    String cleanOriginal = _normalize(verseText);

    // جبد غير آيات السورة المطلوبة من حفص باش نسرعو البحث
    var hafsSurahVerses =
        hafsReferenceVerses.where((v) => v['sura_no'] == surahId).toList();

    for (var hafsVerse in hafsSurahVerses) {
      String cleanHafs = _normalize(hafsVerse['aya_text']);
      // زيادة: حتى الإملاء العادي إيلا كان كاين فالـ JSON
      String cleanHafsEmlaey = _normalize(hafsVerse['aya_text_emlaey'] ?? "");

      // 1. تطابق تام (Exact Match)
      if (cleanOriginal == cleanHafs || cleanOriginal == cleanHafsEmlaey) {
        return hafsVerse['aya_no'];
      }

      // 2. تطابق جزئي (مهم جداً لاختلاف تقسيم الآيات)
      // كنتأكدوا أن النص طويل شوية باش ماتكونش كلمة عشوائية
      if (cleanOriginal.length > 8) {
        if (cleanHafs.contains(cleanOriginal) ||
            cleanOriginal.contains(cleanHafs)) {
          return hafsVerse['aya_no'];
        }
      }
    }

    // إيلا ملقينا والو، رجع الرقم الأصلي (يقدر يخدم إيلا كان الترتيب بحال بحال)
    return originalAyahNum;
  }

  static Future<bool> isQiraaDownloaded(String qiraaKey) async {
    return true;
  }

  static Future<void> downloadQiraa(
      String qiraaKey, Function(double) onProgress) async {
    onProgress(1.0);
  }
}
