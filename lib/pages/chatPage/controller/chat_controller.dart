import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../constants.dart';
import '../../../models/chat_message.dart';

class ChatController with ChangeNotifier {
  WebSocketChannel? _channel;
  String? _currentChatUserId;
  String? _accessToken;
  String? _userId;

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Connect to WebSocket with authentication
  Future<void> connect({
    required String userId,
    required String accessToken,
    required String chatWithUserId,
  }) async {
    _userId = userId;
    _accessToken = accessToken;
    _currentChatUserId = chatWithUserId;

    // Connect to your Directus websocket endpoint
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://$KDirectusApiUrl/websocket'),
    );

    // Set up listeners
    _setupListeners();

    // Send authentication message
    _authenticate();
  }

  void _setupListeners() {
    _channel?.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['type'] == 'auth' && data['status'] == 'ok') {
        _isConnected = true;
        notifyListeners();

        // Subscribe to the messages collection
        _subscribeToMessages();
      } else if (data['type'] == 'subscription') {
        switch (data['event']) {
          case 'create':
            _handleNewMessage(data['data']);
            break;
        }
      } else if (data['type'] == 'ping') {
        // Reply with pong to keep connection alive
        _channel?.sink.add(json.encode({'type': 'pong'}));
      }
    }, onDone: () {
      _isConnected = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) {
        print('WebSocket error: $error');
      }
      _isConnected = false;
      notifyListeners();
    });
  }

  void _authenticate() {
    final authJson = json.encode({
      "type": "auth",
      "access_token": _accessToken,
    });

    _channel?.sink.add(authJson);
  }

  void _subscribeToMessages() {
    // Subscribe to message creation events
    final subscribeJson = json.encode(
      {
        "type": "subscribe",
        "event": "create",
        "collection": "chat_messages",
        "filter": {
          "_or": [
            {
              "_and": [
                {
                  "sender_id": {"_eq": _userId}
                },
                {
                  "receiver_id": {"_eq": _currentChatUserId}
                }
              ]
            },
            {
              "_and": [
                {
                  "sender_id": {"_eq": _currentChatUserId}
                },
                {
                  "receiver_id": {"_eq": _userId}
                }
              ]
            }
          ]
        }
      },
    );

    _channel?.sink.add(subscribeJson);
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final newMessage = ChatMessage.fromJson(data, _userId!);

    // Only add messages related to the current chat
    if ((newMessage.senderId == _userId &&
        newMessage.receiverId == _currentChatUserId) ||
        (newMessage.senderId == _currentChatUserId &&
            newMessage.receiverId == _userId)) {
      _messages.add(newMessage);
      notifyListeners();
    }
  }

  // Send a new message
  Future<void> sendMessage(String content) async {
    if (!_isConnected || _userId == null) return;

    // Create a unique ID for the message
    final messageId = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();

    // Create the message object
    final message = ChatMessage(
      isMe: true,
      id: messageId,
      content: content,
      senderId: _userId!,
      timestamp: DateTime.now(),
      receiverId: _currentChatUserId!,
    );

    // Add to local messages immediately for UI responsiveness
    _messages.add(message);
    notifyListeners();

    // Send via POST Request to Directus API
    // This would typically be in a separate service, but keeping it simple
    // Implement your Directus API call here
  }

  // Load historical messages
  Future<void> loadMessages() async {
    // Implement API call to fetch historical messages
    // For example via GET Request to your Directus API
  }

  // Cleanup
  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
