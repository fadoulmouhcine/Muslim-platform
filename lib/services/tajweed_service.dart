import 'package:flutter/material.dart';

class TajweedService {
  // Alwan t-Tajweed
  static const Color colorAllah = Color(0xFFE53935); // A7mar (Lafd Jalala)
  static const Color colorGhunna = Color(0xFF43A047); // Akhdar (Ghunna)
  static const Color colorQalqala = Color(0xFF1E88E5); // Azraq (Qalqala)

  // ---------------------------------------------------------------------------
  // simplifyForPlainMode
  // Strips Uthmanic annotation marks, small Quranic symbols, pause/stop signs,
  // and non-standard spacing characters from raw Hafs/Uthmanic JSON text.
  // Keeps: fatha (َ), kasra (ِ), damma (ُ), shadda (ّ), sukun (ْ),
  //        tanwin variants (ً ٍ ٌ), alef wasla (ٱ), hamza forms, all base letters.
  // Strips: Uthmanic small waw/ya (ۥ ۦ), small alef (ٰ beyond standard),
  //         pause marks (ۗ ۖ ۘ ۙ ۚ ۛ ۜ ۝ ۞ ۟ ۠ ۡ ۢ ۣ ۤ),
  //         Arabic PUA ornaments (U+FD3E..U+FDFF range markers),
  //         zero-width non-joiners used for Uthmanic justification.
  //         ✅ Also strips U+FC00-U+FD3F — the per-ayah "end of ayah"
  //         ligature codepoints used by the KFGQPC-style Uthmanic (Hafs)
  //         font to render a distinct ornament for every single ayah
  //         number. These codepoints are NOT the real "ornate parenthesis"
  //         Unicode characters — they are a font-specific ligature hack
  //         (a different codepoint per ayah number), so switching to a
  //         normal typeface (Amiri/Cairo/Aref Ruqaa) for "القرآن البسيط"
  //         would otherwise render a random/incorrect Arabic ligature
  //         glyph at the end of every verse. The reading screen instead
  //         renders its own explicit ayah-number badge for Simple mode.
  // ---------------------------------------------------------------------------
  static final RegExp _plainStripRegex = RegExp(
    r'['
    r'\u06D6-\u06DC' // ۖ ۗ ۘ ۙ ۚ ۛ ۜ  — Quranic annotation signs
    r'\u06DF-\u06E4' // ۟ ۠ ۡ ۢ ۣ ۤ     — More annotation marks
    r'\u06E7-\u06E8' // ۧ ۨ              — Small ya / high stop
    r'\u06EA-\u06ED' // ۪ ۫ ۬ ۭ          — Tone marks & ornaments
    r'\u0615'        // ؕ                — Small high tah (pause sign)
    r'\u0670'        // ٰ                — Arabic letter superscript alef
    r'\u06E5-\u06E6' // ۥ ۦ              — Small waw, small ya ligature
    r'\u200C-\u200F' // ZWNJ, ZWJ, LRM, RLM — invisible formatting chars
    r'\u0600-\u0605' // ؀ ؁ ؂ ؃ ؄ ؅    — Arabic number sign / footnote
    r'\uFC00-\uFD3F' // per-ayah "end of ayah" font-specific ligatures
    r']',
  );

  /// Removes annotation clutter while preserving all standard reading marks.
  static String simplifyForPlainMode(String text) {
    return text.replaceAll(_plainStripRegex, '').replaceAll(RegExp(r' +'), ' ').trim();
  }

  static List<TextSpan> parseTajweed(
      String text, double fontSize, String fontFamily,
      {Color textColor = Colors.black}) {
    List<TextSpan> spans = [];

    // Regles Simples (Demo)
    // 1. Lafd Jalala
    RegExp regex = RegExp(r'(ٱللَّهِ|ٱللَّهَ|ٱللَّهُ|لِلَّهِ|ٱللَّهُمَّ)');

    text.splitMapJoin(
      regex,
      onMatch: (Match match) {
        spans.add(TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: colorAllah,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            fontSize: fontSize,
          ),
        ));
        return '';
      },
      onNonMatch: (String segment) {
        // Zid logic d Ghunna hna
        _parseGhunna(segment, spans, fontSize, fontFamily,
            textColor: textColor);
        return '';
      },
    );

    return spans;
  }

  static void _parseGhunna(
      String text, List<TextSpan> spans, double fontSize, String fontFamily,
      {Color textColor = Colors.black}) {
    // 2. Ghunna (Nun/Meem Shadda)
    RegExp regex = RegExp(r'(نّ|مّ)');

    text.splitMapJoin(
      regex,
      onMatch: (Match match) {
        spans.add(TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: colorGhunna,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
            fontSize: fontSize,
          ),
        ));
        return '';
      },
      onNonMatch: (String segment) {
        // Text 3adi
        spans.add(TextSpan(
          text: segment,
          style: TextStyle(
            color: textColor,
            fontFamily: fontFamily,
            fontSize: fontSize,
          ),
        ));
        return '';
      },
    );
  }
}
