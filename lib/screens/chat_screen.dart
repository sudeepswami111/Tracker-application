import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.getMessagesStream(widget.channelId);
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
        title: Row(
          children: [
            Text(
              widget.channelName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.isPrivate) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ]
          ],
        ),
      ),
      body: Column(
        children: [
          // Divider under app bar
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

          // Message History
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "Say hello to start the conversation! 👋",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                final messages = snapshot.data!;

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
                    return _buildChatBubble(msg, isMe, theme, isDark);
                  },
                );
              },
            ),
          ),

          // Input Area
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    Map<String, dynamic> msg,
    bool isMe,
    ThemeData theme,
    bool isDark,
  ) {
    // Sent = primary accent; received = elevated surface
    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : (isDark
            ? AppColors.surfaceElevated
            : AppColors.lightSurfaceContainer);

    final textColor = isMe
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
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
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.voltCyan,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              msg['content'] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDeep.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: theme.textTheme.bodyMedium,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: "Message...",
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _hasText ? _send : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hasText ? AppColors.irisViolet : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      color: _hasText ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
