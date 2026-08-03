import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyBookmarkSurahId = "bookmark_surah_id";
  static const String _keyBookmarkSurahName = "bookmark_surah_name";
  static const String _keyBookmarkPage = "bookmark_page_index";

  static const String _keyLastReadSurahId = "last_read_surah_id";
  static const String _keyLastReadSurahName =
      "last_read_surah_name"; // Zidna hada
  static const String _keyLastReadPage = "last_read_page_index";

  // --- SAVE LAST READ (Kansjlo kolchi: ID, Name, Index) ---
  static Future<void> saveLastRead(
      int surahId, String surahName, int globalPageIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReadSurahId, surahId);
    await prefs.setString(_keyLastReadSurahName, surahName);
    await prefs.setInt(_keyLastReadPage, globalPageIndex);
  }

  // --- GET LAST READ (Kanjibo kolchi) ---
  static Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyLastReadPage)) return null;

    return {
      'surah_id': prefs.getInt(_keyLastReadSurahId) ?? 1,
      'surah_name': prefs.getString(_keyLastReadSurahName) ?? "الفاتحة",
      'page_index': prefs.getInt(_keyLastReadPage) ?? 0,
    };
  }

  // --- BOOKMARK METHODS (Kima kanou) ---
  static Future<void> saveBookmark(
      int surahId, String surahName, double pageIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBookmarkSurahId, surahId);
    await prefs.setString(_keyBookmarkSurahName, surahName);
    await prefs.setDouble(_keyBookmarkPage, pageIndex);
  }

  static Future<Map<String, dynamic>?> getBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyBookmarkPage)) return null;
    return {
      'surah_id': prefs.getInt(_keyBookmarkSurahId),
      'surah_name': prefs.getString(_keyBookmarkSurahName),
      'page_index': prefs.getDouble(_keyBookmarkPage),
    };
  }
}
