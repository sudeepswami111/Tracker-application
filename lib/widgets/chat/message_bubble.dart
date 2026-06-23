import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage msg;
  final bool isMe;
  final bool isDark;
  final ThemeData theme;
  final bool isPending;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.isDark,
    required this.theme,
    this.isPending = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _reaction;

  void _showMessageOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageOptionsSheet(
        message: widget.msg,
        isMe: widget.isMe,
        isDark: widget.isDark,
        theme: widget.theme,
        currentReaction: _reaction,
        onReactionSelected: (emoji) {
          setState(() => _reaction = emoji);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        "${widget.msg.createdAt.hour.toString().padLeft(2, '0')}:${widget.msg.createdAt.minute.toString().padLeft(2, '0')}";

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: widget.isPending ? null : _showMessageOptionsSheet,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: widget.isPending ? 0.65 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? AppColors.primary
                            : (widget.isDark ? AppColors.surfaceElevated : Colors.grey.shade200),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                          bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                        ),
                      ),
                      child: Text(
                        widget.msg.message,
                        style: TextStyle(
                          color: widget.isMe
                              ? Colors.white
                              : (widget.isDark ? Colors.white : Colors.black87),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  if (_reaction != null)
                    Positioned(
                      bottom: -10,
                      right: widget.isMe ? 10 : null,
                      left: widget.isMe ? null : 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.black : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Text(_reaction!, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isPending)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(
                        LucideIcons.clock,
                        size: 9,
                        color: widget.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  Text(
                    timeStr,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: widget.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;
  final ThemeData theme;
  final String? currentReaction;
  final ValueChanged<String?> onReactionSelected;

  const _MessageOptionsSheet({
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.theme,
    this.currentReaction,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Reaction row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '🔥', '💪', '😂', '❤️', '😮'].map((emoji) {
                final isSelected = currentReaction == emoji;
                return GestureDetector(
                  onTap: () {
                    onReactionSelected(isSelected ? null : emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.voltCyan.withValues(alpha: 0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // Options list
            ListTile(
              leading: const Icon(LucideIcons.copy, size: 20),
              title: const Text('Copy Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.message));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(LucideIcons.trash2, size: 20, color: AppColors.pulseRed),
                title: const Text('Delete Message', style: TextStyle(color: AppColors.pulseRed)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Message'),
                      content: const Text('Are you sure you want to delete this message?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.pulseRed)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await chatService.deleteMessage(message.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete: $e')),
                        );
                      }
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
