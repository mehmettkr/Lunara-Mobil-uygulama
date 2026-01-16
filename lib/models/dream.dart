class Dream {
  final String id;
  final String userId;
  final String title;
  final String text;
  final String? aiInterpretation;
  final String? imageUrl;
  final bool isShared;
  final DateTime createdAt;

  final String? mood; // Duygu Durumu (Emoji)

  Dream({
    required this.id,
    required this.userId,
    required this.title,
    required this.text,
    this.aiInterpretation,
    this.imageUrl,
    required this.createdAt,
    this.isShared = false,
    this.mood,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'text': text,
      'aiInterpretation': aiInterpretation,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
      'isShared': isShared,
      'mood': mood,
    };
  }

  factory Dream.fromMap(String id, Map<String, dynamic> map) {
    return Dream(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      aiInterpretation: map['aiInterpretation'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
        isUtc: true,
      ).toLocal(),
      isShared: map['isShared'] as bool? ?? false,
      mood: map['mood'] as String?,
    );
  }
}
