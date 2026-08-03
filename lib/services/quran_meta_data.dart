class QuranMetaData {
  // ==========================================================
  // 1. DATA
  // ==========================================================

  // Liste des Sajdas (Prosternations) [Surah, Ayah]
  static const List<List<int>> _sajdaLocations = [
    [7, 206],
    [13, 15],
    [16, 50],
    [17, 109],
    [19, 58],
    [22, 18],
    [22, 77],
    [25, 60],
    [27, 26],
    [32, 15],
    [38, 24],
    [41, 38],
    [53, 62],
    [84, 21],
    [96, 19]
  ];

  // Liste des Quarts de Hizb (Hizb Quarters)
  static const List<List<int>> _hizbQuarters = [
    [1, 1],
    [2, 26],
    [2, 44],
    [2, 60],
    [2, 75],
    [2, 92],
    [2, 106],
    [2, 124],
    [2, 142],
    [2, 158],
    [2, 177],
    [2, 189],
    [2, 203],
    [2, 219],
    [2, 233],
    [2, 243],
    [2, 253],
    [2, 263],
    [2, 272],
    [2, 283],
    [3, 15],
    [3, 33],
    [3, 52],
    [3, 75],
    [3, 93],
    [3, 113],
    [3, 133],
    [3, 153],
    [3, 171],
    [3, 186],
    [4, 1],
    [4, 12],
    [4, 24],
    [4, 36],
    [4, 58],
    [4, 74],
    [4, 88],
    [4, 100],
    [4, 114],
    [4, 135],
    [4, 148],
    [4, 163],
    [5, 1],
    [5, 12],
    [5, 27],
    [5, 41],
    [5, 51],
    [5, 67],
    [5, 82],
    [5, 97],
    [5, 109],
    [6, 13],
    [6, 36],
    [6, 59],
    [6, 74],
    [6, 95],
    [6, 111],
    [6, 127],
    [6, 141],
    [6, 151],
    [7, 1],
    [7, 31],
    [7, 47],
    [7, 65],
    [7, 88],
    [7, 117],
    [7, 142],
    [7, 156],
    [7, 171],
    [7, 189],
    [8, 1],
    [8, 22],
    [8, 41],
    [8, 61],
    [9, 1],
    [9, 19],
    [9, 34],
    [9, 46],
    [9, 60],
    [9, 75],
    [9, 93],
    [9, 111],
    [9, 122],
    [10, 11],
    [10, 26],
    [10, 53],
    [10, 71],
    [10, 90],
    [11, 6],
    [11, 24],
    [11, 41],
    [11, 61],
    [11, 84],
    [11, 108],
    [12, 7],
    [12, 30],
    [12, 53],
    [12, 77],
    [12, 101],
    [13, 5],
    [13, 19],
    [13, 35],
    [14, 10],
    [14, 28],
    [15, 1],
    [15, 50],
    [16, 1],
    [16, 30],
    [16, 51],
    [16, 75],
    [16, 90],
    [16, 111],
    [17, 1],
    [17, 23],
    [17, 50],
    [17, 70],
    [17, 99],
    [18, 17],
    [18, 32],
    [18, 51],
    [18, 75],
    [18, 99],
    [19, 22],
    [19, 59],
    [20, 1],
    [20, 55],
    [20, 83],
    [20, 111],
    [21, 1],
    [21, 29],
    [21, 51],
    [21, 83],
    [22, 1],
    [22, 19],
    [22, 38],
    [22, 60],
    [23, 1],
    [23, 36],
    [23, 75],
    [24, 1],
    [24, 21],
    [24, 35],
    [24, 53],
    [25, 1],
    [25, 21],
    [25, 53],
    [26, 1],
    [26, 52],
    [26, 111],
    [26, 181],
    [27, 1],
    [27, 27],
    [27, 56],
    [27, 82],
    [28, 12],
    [28, 29],
    [28, 51],
    [28, 76],
    [29, 1],
    [29, 26],
    [29, 46],
    [30, 1],
    [30, 31],
    [30, 54],
    [31, 22],
    [32, 11],
    [33, 1],
    [33, 18],
    [33, 31],
    [33, 51],
    [33, 60],
    [34, 10],
    [34, 24],
    [34, 46],
    [35, 15],
    [35, 41],
    [36, 28],
    [36, 60],
    [37, 22],
    [37, 83],
    [37, 145],
    [38, 21],
    [38, 52],
    [39, 8],
    [39, 32],
    [39, 53],
    [40, 1],
    [40, 21],
    [40, 41],
    [40, 66],
    [41, 9],
    [41, 25],
    [41, 47],
    [42, 13],
    [42, 27],
    [42, 51],
    [43, 24],
    [43, 57],
    [44, 17],
    [45, 12],
    [46, 1],
    [46, 21],
    [47, 10],
    [47, 33],
    [48, 18],
    [49, 1],
    [49, 14],
    [50, 27],
    [51, 31],
    [52, 24],
    [53, 26],
    [54, 9],
    [55, 1],
    [56, 1],
    [56, 75],
    [57, 16],
    [58, 1],
    [58, 14],
    [59, 11],
    [60, 7],
    [62, 1],
    [63, 4],
    [65, 1],
    [66, 1],
    [67, 1],
    [68, 1],
    [69, 1],
    [70, 19],
    [72, 1],
    [73, 20],
    [75, 1],
    [76, 19],
    [78, 1],
    [80, 1],
    [82, 1],
    [84, 1],
    [87, 1],
    [90, 1],
    [94, 1],
    [100, 9],
    [115, 1]
  ];

  // Liste des Juz (Parties)
  static const List<List<int>> _juzStarts = [
    [1, 1],
    [2, 142],
    [2, 253],
    [3, 93],
    [4, 24],
    [4, 148],
    [5, 82],
    [6, 111],
    [7, 88],
    [8, 41],
    [9, 93],
    [11, 6],
    [12, 53],
    [15, 1],
    [17, 1],
    [18, 75],
    [21, 1],
    [23, 1],
    [25, 21],
    [27, 56],
    [29, 46],
    [33, 31],
    [36, 28],
    [39, 32],
    [41, 47],
    [46, 1],
    [51, 31],
    [58, 1],
    [67, 1],
    [78, 1],
  ];

  // ==========================================================
  // 2. LOGIC (Cerveau de l'app)
  // ==========================================================

  // Fonction pour vérifier si l'Ayah actuelle est un début de Hizb, Rob3 ou Sajda
  // Retourne un String (ex: "۞ ربع الحزب 1") ou null
  static String? getPartitionLabel(int surah, int ayah) {
    // 1. D'ABORD, ON VÉRIFIE LA SAJDA (Priorité)
    // On utilise .any pour voir si [surah, ayah] existe dans la liste _sajdaLocations
    bool isSajda = _sajdaLocations.any((s) => s[0] == surah && s[1] == ayah);
    if (isSajda) {
      return "۩ سجدة تلاوة"; // Texte qui s'affichera dans le Popup
    }

    // 2. ENSUITE, ON VÉRIFIE LES HIZB / ROB3
    int index = _hizbQuarters.indexWhere((q) => q[0] == surah && q[1] == ayah);

    if (index != -1) {
      // index 0 -> Hizb 1, Début
      // index 1 -> Hizb 1, 1/4
      // ...

      // Calcul du numéro de Hizb
      int hizbNumber = (index ~/ 4) + 1;

      // Calcul de la position (Rob3, Nisf...)
      int position = index % 4;

      if (position == 0) return "۞ الحزب $hizbNumber";
      if (position == 1) return "۞ ربع الحزب $hizbNumber";
      if (position == 2) return "۞ نصف الحزب $hizbNumber";
      if (position == 3) return "۞ ثلاثة أرباع الحزب $hizbNumber";
    }
    return null; // Rien à signaler
  }

  // Fonction pour récupérer le numéro de Juz pour le Header (AppBar)
  static int getJuzNumber(int surah, int ayah) {
    // On boucle à l'envers pour trouver le dernier Juz passé
    for (int i = _juzStarts.length - 1; i >= 0; i--) {
      List<int> start = _juzStarts[i];
      if (surah > start[0] || (surah == start[0] && ayah >= start[1])) {
        return i + 1; // +1 car l'index commence à 0
      }
    }
    return 1; // Par défaut
  }

  // Fonction pour récupérer le numéro de Hizb pour le Header
  static int getHizbNumber(int surah, int ayah) {
    // On boucle à l'envers
    for (int i = _hizbQuarters.length - 1; i >= 0; i--) {
      List<int> start = _hizbQuarters[i];

      // On ne vérifie que les débuts de Hizb (index 0, 4, 8...)
      if (i % 4 == 0) {
        if (surah > start[0] || (surah == start[0] && ayah >= start[1])) {
          return (i ~/ 4) + 1;
        }
      }
    }
    return 1; // Par défaut
  }

  // Texte complet pour le Header (ex: "الجزء 1 • الحزب 2")
  static String getCurrentJuzAndHizbLabel(int surah, int ayah) {
    int juz = getJuzNumber(surah, ayah);
    int hizb = getHizbNumber(surah, ayah);
    return "الجزء $juz • الحزب $hizb";
  }
}
