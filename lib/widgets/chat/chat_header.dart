import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profile_avatar.dart';
import '../../screens/profile_screen.dart';
import '../../services/chat_service.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String otherUserName;
  final String otherUserId;
  final String chatId;
  final VoidCallback onBack;
  final bool isOnline;

  const ChatHeader({
    super.key,
    required this.otherUserName,
    required this.otherUserId,
    required this.chatId,
    required this.onBack,
    required this.isOnline,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(targetUserId: otherUserId),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: onBack,
      ),
      title: GestureDetector(
        onTap: openProfile,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            ProfileAvatar(
              imageUrl: null,
              name: otherUserName,
              radius: 18,
              backgroundColor: AppColors.irisViolet.withValues(alpha: 0.2),
              foregroundColor: AppColors.irisViolet,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOnline ? 'Online' : 'Active recently',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOnline ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.info, size: 20),
          onPressed: openProfile,
        ),
        IconButton(
          icon: const Icon(LucideIcons.moreVertical, size: 20),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _ChatMoreOptionsSheet(
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                chatId: chatId,
                isDark: isDark,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ChatMoreOptionsSheet extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String chatId;
  final bool isDark;

  const _ChatMoreOptionsSheet({
    required this.otherUserId,
    required this.otherUserName,
    required this.chatId,
    required this.isDark,
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
            ListTile(
              leading: const Icon(LucideIcons.user, size: 20),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(targetUserId: otherUserId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, size: 20, color: AppColors.pulseRed),
              title: const Text('Clear Chat History', style: TextStyle(color: AppColors.pulseRed)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Chat History'),
                    content: Text('Are you sure you want to delete all messages in this chat with $otherUserName? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All', style: TextStyle(color: AppColors.pulseRed)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await chatService.clearChatHistory(chatId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat history cleared')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to clear: $e')),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.ban, size: 20, color: Colors.grey),
              title: const Text('Block User', style: TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Blocked $otherUserName (Mock)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
