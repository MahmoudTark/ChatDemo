import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/chat_controller.dart';
import 'widgets/chat_input_widget.dart';
import 'widgets/message_bubble_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);

    // In a real app, these would come from your authentication service
    // For demo purposes, we'll use dummy values
    const String dummyToken = 'your-directus-auth-token';
    const String dummyUserId = 'current-user-id';

    // Connect WebSocket service
    final chatService = Provider.of<ChatController>(context, listen: false);
    await chatService.connect(dummyToken, dummyUserId);
    await chatService.loadMessages();

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = Provider.of<ChatController>(context, listen: false);
    chatService.sendMessage(_messageController.text.trim());

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Page'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ChatController>(
            builder: (context, chatService, _) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chatService.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatController>(
              builder: (context, chatService, _) {
                final messages = chatService.messages;
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Send your first message!',
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChatInput(
              controller: _messageController,
              onSendPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
