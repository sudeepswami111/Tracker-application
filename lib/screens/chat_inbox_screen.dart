import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "LifePulse Inbox",
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Quick-Start Private Coach Banner
          _buildCoachBanner(theme),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "CHANNELS",
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 2. Streamed Channels List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChannelsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No channels available",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                final channels = snapshot.data!.where((ch) {
                  if (ch['is_private'] == false) return true;
                  final members = List<String>.from(ch['member_ids'] ?? []);
                  return members.contains(_chatService.currentUserId);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final ch = channels[index];
                    final isPrivate = ch['is_private'] ?? false;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceElevated
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: CircleAvatar(
                          backgroundColor: isPrivate
                              ? AppColors.irisViolet.withValues(alpha: 0.2)
                              : AppColors.voltCyan.withValues(alpha: 0.2),
                          child: Icon(
                            isPrivate ? Icons.support_agent : Icons.public,
                            color: isPrivate ? AppColors.irisViolet : AppColors.voltCyan,
                          ),
                        ),
                        title: Text(
                          ch['name'] ?? 'Unnamed Channel',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isPrivate ? "Private 1-on-1 Help" : "Public Community Chat",
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              channelId: ch['id'],
                              channelName: ch['name'],
                              isPrivate: isPrivate,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.irisViolet, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.irisViolet.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Need Personalized Advice?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Talk 1-on-1 with a health coach.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.irisViolet,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                final channelId = await _chatService.createPrivateChannel(
                  "Coach Sarah (Nutrition)",
                  "00000000-0000-0000-0000-111111111111",
                );
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        channelId: channelId,
                        channelName: "Coach Sarah (Nutrition)",
                        isPrivate: true,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create channel: \$e')),
                  );
                }
              }
            },
            child: const Text("Chat Now"),
          ),
        ],
      ),
    );
  }
}
