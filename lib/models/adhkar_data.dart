class DhikrItem {
  final String text; // Nass Do3a
  final int count; // L-3adad (Ex: 33)
  final String reference; // Rawah Muslim/Bukhari
  final String category; // Sabah, Masaa...

  DhikrItem({
    required this.text,
    required this.count,
    required this.reference,
    required this.category,
  });
}

// Hna ghan-7etto Data (Mock Data l-db)
// Mn ba3d n-qdro n-rdouha JSON
class AdhkarData {
  static List<DhikrItem> getAdhkarByCategory(String category) {
    // 1. ADHKAR SABAH (Mital)
    if (category == "أذكار الصباح") {
      return [
        DhikrItem(
          text:
              "أَصْـبَحْنا وَأَصْـبَحَ المُـلْكُ لله وَالحَمدُ لله ، لا إلهَ إلاّ اللّهُ وَحدَهُ لا شَريكَ لهُ، لهُ المُـلْكُ ولهُ الحَمْـد، وهُوَ على كلّ شَيءٍ قدير.",
          count: 1,
          reference: "رواه مسلم",
          category: "أذكار الصباح",
        ),
        DhikrItem(
          text: "سُبْحـانَ اللهِ وَبِحَمْـدِهِ.",
          count: 100, // Hada fih bzzaf
          reference: "رواه البخاري ومسلم",
          category: "أذكار الصباح",
        ),
        DhikrItem(
          text:
              "اللَّهُمَّ أَنْتَ رَبِّي لا إِلَهَ إِلا أَنْتَ ، خَلَقْتَنِي وَأَنَا عَبْدُكَ ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ.",
          count: 1,
          reference: "سيد الاستغفار",
          category: "أذكار الصباح",
        ),
      ];
    }
    // 2. ADHKAR MASAA (Mital)
    else if (category == "أذكار المساء") {
      return [
        DhikrItem(
          text:
              "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ.",
          count: 1,
          reference: "رواه مسلم",
          category: "أذكار المساء",
        ),
        DhikrItem(
          text:
              "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.",
          count: 3,
          reference: "رواه الترمذي",
          category: "أذكار المساء",
        ),
      ];
    }
    return [];
  }
}
