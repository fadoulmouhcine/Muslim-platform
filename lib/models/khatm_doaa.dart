class KhatmDoaa {
  final String title;
  final String bismillah;
  final List<String> parts;

  KhatmDoaa({
    required this.title,
    required this.bismillah,
    required this.parts,
  });

  factory KhatmDoaa.fromJson(Map<String, dynamic> json) {
    return KhatmDoaa(
      title: json['title'] as String,
      bismillah: json['bismillah'] as String,
      parts: List<String>.from(json['parts'] as List),
    );
  }
}
