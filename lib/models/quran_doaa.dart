class QuranDoaa {
  final String text;
  final String surah;
  final int ayah;
  final String speaker;

  QuranDoaa({
    required this.text,
    required this.surah,
    required this.ayah,
    required this.speaker,
  });

  factory QuranDoaa.fromJson(Map<String, dynamic> json) {
    return QuranDoaa(
      text: json['text'] as String,
      surah: json['surah'] as String,
      ayah: json['ayah'] as int,
      speaker: json['speaker'] as String,
    );
  }
}
