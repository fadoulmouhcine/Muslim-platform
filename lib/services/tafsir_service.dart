import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class TafsirService {
  // Hna ghan-khzzno Data b tariqa S7i7a (Key: "1_1", Value: "Tafsir...")
  static final Map<String, String> _tafsirMap = {};

  static Future<void> loadTafsir() async {
    if (_tafsirMap.isNotEmpty) return;

    try {
      debugPrint("⏳ Loading Tafsir File (List Format)...");
      String jsonString =
          await rootBundle.loadString('assets/json/tafsir/tafsir.json');

      // 1. Decode JSON as List
      List<dynamic> jsonList = json.decode(jsonString);

      // 2. Convert List to Map (Bach n-lgaw l-ayat dghya)
      for (var item in jsonList) {
        // JSON dyalek fih: "number", "aya", "text"
        String key = "${item['number']}_${item['aya']}"; // Ex: "1_1"
        _tafsirMap[key] = item['text'];
      }

      debugPrint("✅ Tafsir Loaded! Total Verses: ${_tafsirMap.length}");
    } catch (e) {
      debugPrint("❌ Error loading Tafsir: $e");
    }
  }

  static String getTafsir(int surahId, int ayahId) {
    String key = "${surahId}_$ayahId";
    return _tafsirMap[key] ?? "لا يوجد تفسير متاح لهذه الآية حالياً.";
  }
}
