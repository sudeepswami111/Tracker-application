import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/profile_avatar.dart';
import '../../services/chat_service.dart';
import '../../services/follow_service.dart';
import 'dm_chat_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final ChatService _chatService = ChatService();
  final FollowService _followService = FollowService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<FollowUser> _following = [];
  List<FollowUser> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    final myId = _chatService.currentUserId;
    if (myId.isEmpty) return;
    try {
      final following = await _followService.getFollowing(myId);
      if (mounted) {
        setState(() {
          _following = following;
          _filtered = following;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _following.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('New Message'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search followed friends...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceElevated : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.irisViolet))
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              _searchCtrl.text.isEmpty
                                  ? 'Follow friends to start chatting'
                                  : 'No friends found matching query',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final user = _filtered[index];
                              final name = user.fullName.isNotEmpty ? user.fullName : user.username;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: ProfileAvatar(
                                  imageUrl: user.avatarUrl,
                                  name: name,
                                  radius: 20,
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('@${user.username}'),
                                trailing: const Icon(LucideIcons.messageCircle, color: AppColors.voltCyan, size: 20),
                                onTap: () async {
                                  try {
                                    final chatId = await _chatService.getOrCreateDmChat(user.id);
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DMChatScreen(
                                            chatId: chatId,
                                            otherUserId: user.id,
                                            otherUserName: name,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Failed to start chat: $e'),
                                        backgroundColor: AppColors.pulseRed,
                                      ));
                                    }
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
