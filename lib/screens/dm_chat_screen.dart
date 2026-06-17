import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../services/follow_service.dart';
import '../widgets/profile_avatar.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DM LIST SCREEN — shows all conversations + search bar
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class DMListScreen extends StatefulWidget {
  const DMListScreen({super.key});

  @override
  State<DMListScreen> createState() => _DMListScreenState();
}

class _DMListScreenState extends State<DMListScreen> {
  final _chatService   = ChatService();
  final _followService = FollowService();
  final _searchCtrl    = TextEditingController();

  List<ChatRoom>   _chats       = [];
  List<FollowUser> _searchResults = [];
  bool _loadingChats    = true;
  bool _loadingSearch   = false;
  bool _showSearch      = false;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _loadingChats = true);
    _chats = await _chatService.getMyChats();
    if (mounted) setState(() => _loadingChats = false);
  }

  // ── Username search (debounced 500ms) ──────────────────────────
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _searchResults = []; _loadingSearch = false; });
      return;
    }
    setState(() => _loadingSearch = true);
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _followService.searchUsers(value.trim());
      if (mounted) setState(() { _searchResults = results; _loadingSearch = false; });
    });
  }

  // ── Open chat with a user found via search ─────────────────────
  /// Opens existing chat room if present, otherwise shows "not connected" hint.
  void _openChatWithUser(FollowUser user) async {
    // Check if a chat exists (both must have accepted follow)
    final supabase = Supabase.instance.client;
    final me = supabase.auth.currentUser?.id ?? '';

    final u1 = me.compareTo(user.id) < 0 ? me : user.id;
    final u2 = me.compareTo(user.id) < 0 ? user.id : me;

    try {
      final res = await supabase
          .from('chats')
          .select('id')
          .eq('user1_id', u1)
          .eq('user2_id', u2)
          .maybeSingle();

      if (res == null) {
        if (mounted) {
          // They are not connected yet
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              user.followStatus == FollowStatus.accepted
                  ? 'Waiting for ${user.username} to follow you back to unlock chat.'
                  : 'Follow @${user.username} and wait for them to accept to start chatting.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.irisViolet,
          ));
        }
        return;
      }

      // Chat exists → navigate
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DMChatScreen(
              chatId: res['id'] as String,
              otherUserName: user.fullName.isNotEmpty
                  ? user.fullName
                  : '@${user.username}',
              otherUserId: user.id,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search by username…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            : Text('Messages',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: !_showSearch,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? LucideIcons.x : LucideIcons.search,
                size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _searchResults = [];
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _showSearch
          ? _buildSearchResults(theme, isDark)
          : _buildChatList(theme, isDark),
    );
  }

  // ── Search Results View ─────────────────────────────────────────
  Widget _buildSearchResults(ThemeData theme, bool isDark) {
    if (_searchCtrl.text.trim().isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.atSign,
              size: 60,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Search by username to start a chat',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
    }

    if (_loadingSearch) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text('No users found for "${_searchCtrl.text}"',
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final user = _searchResults[i];
        return _SearchUserTile(
          user: user,
          theme: theme,
          isDark: isDark,
          onTap: () => _openChatWithUser(user),
        );
      },
    );
  }

  // ── Chat List View ──────────────────────────────────────────────
  Widget _buildChatList(ThemeData theme, bool isDark) {
    if (_loadingChats) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.irisViolet));
    }
    if (_chats.isEmpty) {
      return _buildEmpty(theme);
    }
    return RefreshIndicator(
      color: AppColors.irisViolet,
      onRefresh: _loadChats,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildChatTile(_chats[i], theme, isDark),
      ),
    );
  }

  Widget _buildChatTile(ChatRoom chat, ThemeData theme, bool isDark) {
    final name    = chat.friend.displayName;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DMChatScreen(
            chatId:        chat.chatId,
            otherUserName: chat.friend.displayName,
            otherUserId:   chat.friend.id,
          ),
        ),
      ).then((_) => _loadChats()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          // Avatar
          ProfileAvatar(
            imageUrl: chat.friend.avatarUrl,
            name: name,
            radius: 26,
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
            foregroundColor: AppColors.irisViolet,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('Tap to open conversation',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.messageCircle,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant
                .withValues(alpha: 0.25)),
        const SizedBox(height: 24),
        Text('No conversations yet',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Follow someone and when they accept,\nyou can start chatting.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => _showSearch = true);
          },
          icon: const Icon(LucideIcons.search, size: 18),
          label: const Text('Search Users'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Search result tile
// ─────────────────────────────────────────────────────────────────
class _SearchUserTile extends StatelessWidget {
  final FollowUser user;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchUserTile({
    required this.user,
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  String get _followLabel {
    switch (user.followStatus) {
      case FollowStatus.accepted: return 'Following';
      case FollowStatus.pending:  return 'Requested';
      case FollowStatus.none:     return 'Not following';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name     = user.fullName.isNotEmpty ? user.fullName : user.username;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          ProfileAvatar(
            imageUrl: user.avatarUrl,
            name: name,
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('@${user.username}  •  $_followLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
          ),
          Icon(
            user.followStatus == FollowStatus.accepted
                ? LucideIcons.messageCircle
                : LucideIcons.userPlus,
            size: 20,
            color: user.followStatus == FollowStatus.accepted
                ? AppColors.primary
                : Colors.grey,
          ),
        ]),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DM CHAT SCREEN — the actual 1-on-1 conversation view
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class DMChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const DMChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends State<DMChatScreen> {
  final _chatService = ChatService();
  final _inputCtrl   = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _supabase    = Supabase.instance.client;

  bool _sending = false;
  late final Stream<List<ChatMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.getDMMessagesStream(widget.chatId);
    // Mark messages as read when opening chat
    _chatService.markAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    _inputCtrl.clear();
    
    try {
      await _chatService.sendDM(widget.chatId, text);
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final myId    = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          ProfileAvatar(
            imageUrl: null, 
            name: widget.otherUserName,
            radius: 18,
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.2),
            foregroundColor: AppColors.irisViolet,
          ),
          const SizedBox(width: 10),
          Text(widget.otherUserName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SafeArea(
        child: Column(children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.irisViolet)
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages', 
                      style: TextStyle(color: theme.colorScheme.error))
                  );
                }

                final msgs = snapshot.data?.reversed.toList() ?? [];

                if (msgs.isEmpty) {
                  return _buildEmptyChat(theme);
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg   = msgs[i];
                    final isMe  = msg.senderId == myId;
                    return _Bubble(
                        msg: msg, isMe: isMe, theme: theme, isDark: isDark);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDeep : Colors.white,
              border: Border(
                top: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.3)),
              ),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Message…',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceElevated
                        : AppColors.lightSurfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _inputCtrl,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: (hasText && !_sending) ? _send : null,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: hasText
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceElevated : Colors.grey.shade300),
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Icon(LucideIcons.send,
                              color: hasText ? Colors.white : Colors.grey, size: 20),
                    ),
                  );
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyChat(ThemeData theme) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.messageCircle,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Say hello!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Start the conversation.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final ThemeData theme;
  final bool isDark;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : (isDark ? AppColors.surfaceElevated : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(
          msg.message,
          style: TextStyle(
              color: isMe
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
              fontSize: 15),
        ),
      ),
    );
  }
}
