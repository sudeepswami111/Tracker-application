import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../providers/app_provider.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final bool isPrivate;

  const ChatScreen({
    Key? key,
    required this.channelId,
    required this.channelName,
    required this.isPrivate,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _messageStream;

  @override
  void initState() {
    super.initState();
    // Cache stream reference locally in initState to avoid performance lag and rebuilds
    _messageStream = _chatService.getMessagesStream(widget.channelId);
  }

  void _send() {
    if (_messageController.text.trim().isNotEmpty) {
      final app = context.read<AppProvider>();
      _chatService.sendMessage(
        widget.channelId, 
        _messageController.text,
        senderNameOverride: app.userName.isNotEmpty ? app.userName : 'Sudeep',
      );
      _messageController.clear();
      // Smooth scroll to bottom on send
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.channelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            if (widget.isPrivate) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: Colors.blue, size: 16), // Certified coach badge
            ]
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Message History Panel
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Say hello to start the conversation! 👋", style: TextStyle(color: Colors.grey)),
                  );
                }

                final messages = snapshot.data!;

                // Auto scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == _chatService.currentUserId;

                    return _buildChatBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          
          // Bottom Message Input Container
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3B82F6) : const Color(0xFF334155),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg['sender_name'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyanAccent),
              ),
            const SizedBox(height: 3),
            Text(
              msg['content'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E293B),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF3B82F6),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
