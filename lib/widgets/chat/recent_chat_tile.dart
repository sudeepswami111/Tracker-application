import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/profile_avatar.dart';
import '../../screens/dm_chat_screen.dart';
import '../../screens/profile_screen.dart';

class RecentChatTile extends StatelessWidget {
  final ChatRoom chat;
  final VoidCallback onRefresh;

  const RecentChatTile({
    super.key,
    required this.chat,
    required this.onRefresh,
  });

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && now.day == dateTime.day) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $amPm';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dateTime.day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DMChatScreen(
              chatId: chat.chatId,
              otherUserId: chat.friend.id,
              otherUserName: chat.friend.displayName,
            ),
          ),
        ).then((_) => onRefresh());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin, vertical: AppSpacing.md),
        child: Row(
          children: [
            // Avatar (taps to open profile)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(targetUserId: chat.friend.id),
                  ),
                );
              },
              child: ProfileAvatar(
                imageUrl: chat.friend.avatarUrl,
                name: chat.friend.displayName,
                radius: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.friend.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: chat.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatMessageTime(chat.lastMessageAt ?? chat.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: chat.unreadCount > 0 
                              ? AppColors.voltCyan 
                              : (isDark ? Colors.white38 : Colors.black38),
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Tap to view conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: chat.unreadCount > 0 
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white60 : Colors.black54),
                            fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.voltCyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
