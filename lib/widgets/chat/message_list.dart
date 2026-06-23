import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/chat_models.dart';
import '../../theme/app_colors.dart';
import 'message_bubble.dart';

abstract class ChatListItem {}

class MessageItem extends ChatListItem {
  final ChatMessage message;
  MessageItem(this.message);
}

class DateSeparatorItem extends ChatListItem {
  final DateTime date;
  DateSeparatorItem(this.date);
}

class MessageList extends StatelessWidget {
  final Stream<List<ChatMessage>> stream;
  final ScrollController scrollCtrl;
  final String myId;
  final ThemeData theme;
  final bool isDark;
  final List<ChatMessage> optimisticMessages;
  final VoidCallback? onNewMessageArrived;

  const MessageList({
    super.key,
    required this.stream,
    required this.scrollCtrl,
    required this.myId,
    required this.theme,
    required this.isDark,
    required this.optimisticMessages,
    this.onNewMessageArrived,
  });

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

  List<ChatListItem> _buildDisplayItems(List<ChatMessage> messages) {
    final List<ChatListItem> items = [];
    if (messages.isEmpty) return items;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final date = msg.createdAt;

      if (i == 0) {
        items.add(DateSeparatorItem(date));
      } else {
        final prevMsg = messages[i - 1];
        if (!_isSameDay(prevMsg.createdAt, msg.createdAt)) {
          items.add(DateSeparatorItem(date));
        }
      }
      items.add(MessageItem(msg));
    }
    return items.reversed.toList();
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.irisViolet),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        final streamMsgs = snapshot.data ?? [];

        // Trigger read receipts in background
        final hasUnread = streamMsgs.any((m) => m.senderId != myId && !m.isRead);
        if (hasUnread && onNewMessageArrived != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onNewMessageArrived!();
          });
        }

        // Merge realtime messages with still-pending optimistic ones
        final pendingOptimistic = optimisticMessages.where((opt) {
          return !streamMsgs.any((m) =>
              m.senderId == opt.senderId &&
              m.message == opt.message &&
              m.createdAt.isAfter(opt.createdAt.subtract(const Duration(seconds: 10))));
        }).toList();

        final allMsgs = [...streamMsgs, ...pendingOptimistic];
        allMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final listItems = _buildDisplayItems(allMsgs);

        if (listItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.messageCircle,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                Text(
                  'Say hi to start the conversation',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          itemCount: listItems.length,
          itemBuilder: (_, i) {
            final item = listItems[i];
            if (item is DateSeparatorItem) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDateSeparator(item.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            } else if (item is MessageItem) {
              final msg = item.message;
              final isMe = msg.senderId == myId;
              final isPending = msg.id.startsWith('temp-');
              return MessageBubble(
                key: ValueKey(msg.id),
                msg: msg,
                isMe: isMe,
                theme: theme,
                isDark: isDark,
                isPending: isPending,
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
