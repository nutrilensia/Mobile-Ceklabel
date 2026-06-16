class ChatMessage {
  final String role; // "user" | "assistant"
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> j) =>
      ChatMessage(role: j['role'] as String, content: j['content'] as String);
}
