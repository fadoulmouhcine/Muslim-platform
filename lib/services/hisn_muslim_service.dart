import 'dart:convert';
import 'package:flutter/services.dart';

class HisnItem {
  final int id;
  final String text;
  final String footnote;
  final int count;

  HisnItem({
    required this.id,
    required this.text,
    required this.footnote,
    this.count = 1,
  });
}

class HisnCategory {
  final String title;
  final List<HisnItem> items;

  HisnCategory({
    required this.title,
    required this.items,
  });
}

class HisnMuslimService {
  static List<HisnCategory>? _cachedCategories;

  /// Loads and parses Hisn Al-Muslim JSON asset
  static Future<List<HisnCategory>> loadHisnMuslim() async {
    if (_cachedCategories != null) return _cachedCategories!;

    try {
      final jsonString =
          await rootBundle.loadString('assets/json/sunnah/hisn_almuslim.json');
      final Map<String, dynamic> rawMap = json.decode(jsonString);

      final List<HisnCategory> categories = [];

      rawMap.forEach((categoryTitle, categoryData) {
        if (categoryData is Map<String, dynamic>) {
          final List<dynamic> textList = categoryData['text'] ?? [];
          final List<dynamic> footnoteList = categoryData['footnote'] ?? [];

          final List<HisnItem> items = [];
          for (int i = 0; i < textList.length; i++) {
            final String text = textList[i].toString();
            final String footnote =
                i < footnoteList.length ? footnoteList[i].toString() : '';

            final int repeatCount = _extractRepeatCount(text, footnote);

            items.add(
              HisnItem(
                id: i + 1,
                text: text,
                footnote: footnote,
                count: repeatCount,
              ),
            );
          }

          categories.add(
            HisnCategory(
              title: categoryTitle,
              items: items,
            ),
          );
        }
      });

      _cachedCategories = categories;
      return categories;
    } catch (e) {
      return [];
    }
  }

  /// Extracts target repetition count from text or footnote
  static int _extractRepeatCount(String text, String footnote) {
    final combined = "$text $footnote";
    if (combined.contains('ثلاث مرات') ||
        combined.contains('3 مرات') ||
        combined.contains('ثلاثاً')) {
      return 3;
    }
    if (combined.contains('عشر مرات') ||
        combined.contains('10 مرات') ||
        combined.contains('عشراً')) {
      return 10;
    }
    if (combined.contains('مائة مرة') ||
        combined.contains('100 مرة') ||
        combined.contains('مائة')) {
      return 100;
    }
    if (combined.contains('أربع مرات') || combined.contains('4 مرات')) {
      return 4;
    }
    if (combined.contains('سبع مرات') || combined.contains('7 مرات')) {
      return 7;
    }
    if (combined.contains('مرتين')) {
      return 2;
    }
    return 1;
  }
}
