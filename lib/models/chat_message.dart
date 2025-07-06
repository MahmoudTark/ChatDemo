class ChatMessage {
  final bool isMe;
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.isMe,
    required this.content,
    required this.senderId,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      timestamp: DateTime.parse(json['timestamp']),
      isMe: json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
