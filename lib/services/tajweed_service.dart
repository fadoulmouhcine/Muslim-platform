import 'package:flutter/material.dart';

class TajweedService {
  // Alwan t-Tajweed
  static const Color colorAllah = Color(0xFFE53935); // A7mar (Lafd Jalala)
  static const Color colorGhunna = Color(0xFF43A047); // Akhdar (Ghunna)
  static const Color colorQalqala = Color(0xFF1E88E5); // Azraq (Qalqala)

  static List<TextSpan> parseTajweed(
      String text, double fontSize, String fontFamily,
      {Color textColor = Colors.black}) {
    List<TextSpan> spans = [];

    // Regles Simples (Demo)
    // 1. Lafd Jalala
    RegExp regex = RegExp(r'(ٱللَّهِ|ٱللَّهَ|ٱللَّهُ|لِلَّهِ|ٱللَّهُمَّ)');

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
