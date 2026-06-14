class Tip {
  final String id;
  final String category;
  final String title;
  final String content;
  final int readTime;

  Tip({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.readTime,
  });

  factory Tip.fromJson(Map<String, dynamic> json) => Tip(
    id: json['id']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
    readTime: (json['readTime'] ?? 30).toInt(),
  );
}
