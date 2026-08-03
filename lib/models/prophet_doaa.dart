class ProphetDoaa {
  final String text;
  final String source;

  ProphetDoaa({
    required this.text,
    required this.source,
  });

  factory ProphetDoaa.fromJson(Map<String, dynamic> json) {
    return ProphetDoaa(
      text: json['text'] as String,
      source: json['source'] as String,
    );
  }
}
