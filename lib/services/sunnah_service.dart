import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- MODELS ---

class Hadith {
  final int id;
  final int idInBook;
  final int chapterId;
  final String arabicText;
  final String englishText;
  final String narrator;

  Hadith({
    required this.id,
    required this.idInBook,
    required this.chapterId,
    required this.arabicText,
    required this.englishText,
    required this.narrator,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    String narratorText = "";
    String contentText = "";

    if (json['english'] != null) {
      if (json['english'] is Map) {
        narratorText = json['english']['narrator']?.toString() ?? "";
        contentText = json['english']['text']?.toString() ?? "";
      } else if (json['english'] is String) {
        contentText = json['english'];
      }
    }

    return Hadith(
      id: json['id'] ?? 0,
      idInBook: json['idInBook'] ?? 0,
      chapterId: json['chapterId'] ?? 0,
      arabicText: json['arabic']?.toString() ?? "",
      englishText: contentText,
      narrator: narratorText,
    );
  }
}

class Chapter {
  final int id;
  final String arabicTitle;
  final String englishTitle;

  Chapter(
      {required this.id,
      required this.arabicTitle,
      required this.englishTitle});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      arabicTitle: json['arabic']?.toString() ?? "",
      englishTitle: json['english']?.toString() ?? "",
    );
  }
}

// --- SERVICE ---

class SunnahService {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static Future<Map<String, dynamic>> loadBookData(String fileName) async {
    if (_cache.containsKey(fileName)) return _cache[fileName]!;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/sunnah/$fileName');
      // N-khaliwh dynamic hna bach n-checkiw wach Hisn wla la
      final dynamic decodedData = json.decode(jsonString);

      // ============================================================
      // 1. SPECIAL CASE: HISN AL-MUSLIM
      // ============================================================
      if (fileName.contains('hisn') ||
          decodedData is! Map ||
          !decodedData.containsKey('chapters')) {
        return _parseHisnAlMuslim(decodedData, fileName);
      }

      // ============================================================
      // 2. STANDARD BOOKS (Bukhari, Muslim...)
      // ============================================================

      final Map<String, dynamic> data = decodedData as Map<String, dynamic>;

      List<Chapter> chapters = [];
      if (data['chapters'] != null) {
        chapters = (data['chapters'] as List)
            .map((c) => Chapter.fromJson(
                c as Map<String, dynamic>)) // Zidna cast hna ta howa
            .toList();
      }

      List<Hadith> hadiths = [];
      if (data['hadiths'] != null) {
        hadiths = (data['hadiths'] as List)
            .map((h) => Hadith.fromJson(
                h as Map<String, dynamic>)) // Zidna cast hna ta howa
            .toList();
      }

      Map<int, List<Hadith>> hadithsByChapter = {};
      for (var h in hadiths) {
        if (!hadithsByChapter.containsKey(h.chapterId)) {
          hadithsByChapter[h.chapterId] = [];
        }
        hadithsByChapter[h.chapterId]!.add(h);
      }

      final result = {
        'metadata': data['metadata'] ?? {'title': 'كتاب'},
        'chapters': chapters,
        'hadithsMap': hadithsByChapter,
      };

      _cache[fileName] = result;
      return result;
    } catch (e) {
      debugPrint("❌ Error loading book $fileName: $e");
      return {};
    }
  }

  // LOGIC DYAL HISN MUSLIM
  static Map<String, dynamic> _parseHisnAlMuslim(
      dynamic jsonMap, String fileName) {
    List<Chapter> chapters = [];
    Map<int, List<Hadith>> hadithsMap = {};

    int chapterIdCounter = 1;
    int hadithIdCounter = 1;

    if (jsonMap is Map) {
      jsonMap.forEach((key, value) {
        String chapterTitle = key.toString();

        // 1. Create Chapter
        chapters.add(Chapter(
            id: chapterIdCounter, arabicTitle: chapterTitle, englishTitle: ""));

        // 2. Create Hadiths
        List<Hadith> chapterHadiths = [];
        if (value is Map && value['text'] is List) {
          List<dynamic> texts = value['text'];

          for (var text in texts) {
            chapterHadiths.add(Hadith(
              id: hadithIdCounter,
              idInBook: hadithIdCounter,
              chapterId: chapterIdCounter,
              arabicText: text.toString(),
              englishText: "",
              narrator: "",
            ));
            hadithIdCounter++;
          }
        }

        hadithsMap[chapterIdCounter] = chapterHadiths;
        chapterIdCounter++;
      });
    }

    final result = {
      'metadata': {'title': 'حصن المسلم'},
      'chapters': chapters,
      'hadithsMap': hadithsMap,
    };

    _cache[fileName] = result;
    return result;
  }
}
