class ChatMessage {
  final bool isMe;
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.isMe,
    required this.content,
    required this.senderId,
    required this.timestamp,
    required this.receiverId,
  });

  factory ChatMessage.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      isMe: json['sender_id'] == currentUserId,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
