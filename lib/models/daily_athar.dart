class DailyAthar {
  final int id;
  final String question;
  final String category;
  final bool targetAnswer;
  final String emoji;
  final String? autoTrackKey;

  DailyAthar({
    required this.id,
    required this.question,
    required this.category,
    required this.targetAnswer,
    required this.emoji,
    this.autoTrackKey,
  });

  factory DailyAthar.fromJson(Map<String, dynamic> json) {
    return DailyAthar(
      id: json['id'] as int,
      question: json['question'] as String,
      category: json['category'] as String,
      targetAnswer: json['target_answer'] as bool,
      emoji: json['emoji'] as String,
      autoTrackKey: json['auto_track_key'] as String?,
    );
  }
}
