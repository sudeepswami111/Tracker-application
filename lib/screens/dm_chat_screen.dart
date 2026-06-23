import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../services/follow_service.dart';
import '../widgets/profile_avatar.dart';
import '../providers/app_provider.dart';
import '../providers/step_tracker_provider.dart';
import 'profile_screen.dart';


// ─────────────────────────────────────────────────────────────────
// DM LIST SCREEN — shows all conversations + search bar
// ─────────────────────────────────────────────────────────────────
class DMListScreen extends StatefulWidget {
  const DMListScreen({super.key});

  @override
  State<DMListScreen> createState() => _DMListScreenState();
}

class _DMListScreenState extends State<DMListScreen> {
  final _chatService   = ChatService();
  final _followService = FollowService();
  final _searchCtrl    = TextEditingController();

  List<ChatRoom>   _chats         = [];
  List<FollowUser> _searchResults = [];
  bool _loadingChats  = true;
  bool _loadingSearch = false;
  bool _showSearch    = false;

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

  bool _isFriendOnline(ChatRoom chat) {
    return chat.friend.id.hashCode % 3 == 0 || (chat.unreadCount > 0);
  }

  bool _isStreakFriend(ChatRoom chat) {
    return chat.friend.id.hashCode % 2 == 0;
  }

  void _openChatWithUser(FollowUser user) async {
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
        ).then((_) => _loadChats());
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
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search by username…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
            icon: Icon(_showSearch ? LucideIcons.x : LucideIcons.search, size: 20),
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

  Widget _buildSearchResults(ThemeData theme, bool isDark) {
    if (_searchCtrl.text.trim().isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.atSign,
              size: 60,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Search by username to start a chat',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
    }

    if (_loadingSearch) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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

  Widget _buildChatList(ThemeData theme, bool isDark) {
    if (_loadingChats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.irisViolet));
    }
    if (_chats.isEmpty) {
      return _buildEmpty(theme);
    }
    return RefreshIndicator(
      color: AppColors.irisViolet,
      onRefresh: _loadChats,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildChatTile(_chats[i], theme, isDark),
      ),
    );
  }

  Widget _buildChatTile(ChatRoom chat, ThemeData theme, bool isDark) {
    final name = chat.friend.displayName;
    final isOnline = _isFriendOnline(chat);
    final isStreak = _isStreakFriend(chat);

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
          Stack(
            children: [
              ProfileAvatar(
                imageUrl: chat.friend.avatarUrl,
                name: name,
                radius: 26,
                backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
                foregroundColor: AppColors.irisViolet,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceElevated : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (isStreak) ...[
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.flame, size: 14, color: AppColors.solarAmber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(chat.lastMessage ?? 'Tap to open conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.messageCircle,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final name = user.fullName.isNotEmpty ? user.fullName : user.username;

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

// ─────────────────────────────────────────────────────────────────
// DM CHAT SCREEN — the actual 1-on-1 conversation view
// ─────────────────────────────────────────────────────────────────
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
  String _currentText = '';

  // Optimistic send — messages shown immediately before Supabase confirms
  final List<ChatMessage> _optimisticMessages = [];

  // Fallback poll — triggers a setState every 5 s in case realtime drops
  Timer? _fallbackPoll;

  // Realtime Presence / Typing States
  RealtimeChannel? _presenceChannel;
  List<String> _typingUsers = [];
  List<String> _onlineUsers = [];
  bool _wasTyping = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.getDMMessagesStream(widget.chatId);
    _chatService.markAsRead(widget.chatId);
    
    _inputCtrl.addListener(_onInputChanged);

    // Fallback: force a rebuild every 5 s so the StreamBuilder picks up any
    // new snapshot that arrived while realtime was silently disconnected.
    _fallbackPoll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });

    // Subscribe to presence tracking
    try {
      _presenceChannel = _chatService.subscribeToPresence(
        widget.chatId,
        onTypingChanged: (users) {
          if (mounted) {
            setState(() {
              _typingUsers = users;
            });
          }
        },
        onOnlineChanged: (users) {
          if (mounted) {
            setState(() {
              _onlineUsers = users;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('[DMChatScreen] Presence subscription error: $e');
    }
  }

  void _onInputChanged() {
    final text = _inputCtrl.text.trim();
    final isTypingNow = text.isNotEmpty;
    if (isTypingNow != _wasTyping) {
      _wasTyping = isTypingNow;
      if (_presenceChannel != null) {
        _chatService.setTyping(_presenceChannel!, isTypingNow);
      }
    }
    setState(() {
      _currentText = _inputCtrl.text;
    });
  }

  @override
  void dispose() {
    _fallbackPoll?.cancel();
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    if (_presenceChannel != null) {
      try {
        _supabase.removeChannel(_presenceChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _send([String? predefinedText]) async {
    final text = predefinedText ?? _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();

    final myId   = _supabase.auth.currentUser?.id ?? '';
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Optimistically add the message right away — no Supabase wait
    final optimisticMsg = ChatMessage(
      id: tempId,
      chatId: widget.chatId,
      senderId: myId,
      message: text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _optimisticMessages.add(optimisticMsg);
      _sending = true;
    });
    if (predefinedText == null) _inputCtrl.clear();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    try {
      final insertedMsg = await _chatService.sendDM(widget.chatId, text);
      // The real message has successfully inserted. Replace our temp one immediately
      // to avoid UI flicker while waiting for the realtime stream to deliver it.
      if (mounted) {
        setState(() {
          final idx = _optimisticMessages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _optimisticMessages[idx] = insertedMsg;
          }
        });
      }
    } catch (e) {
      // Send failed — remove the optimistic bubble and show error
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
          _sending = false;
        });

        String shortError = e.toString();
        if (e is PostgrestException) {
          shortError = e.message;
        } else if (shortError.startsWith('Exception: ')) {
          shortError = shortError.substring(11); // remove "Exception: "
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Send failed: $shortError'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _send(text),
            ),
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showFitnessSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FitnessSharingHubSheet(
        onSelect: (msg) {
          Navigator.pop(context);
          _send(msg);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myId   = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: _ChatHeader(
        otherUserName: widget.otherUserName,
        otherUserId: widget.otherUserId,
        chatId: widget.chatId,
        onBack: () => Navigator.pop(context),
        isOnline: _onlineUsers.contains(widget.otherUserId),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _MessageList(
                stream: _messagesStream,
                scrollCtrl: _scrollCtrl,
                myId: myId,
                theme: theme,
                isDark: isDark,
                optimisticMessages: _optimisticMessages,
                onNewMessageArrived: () => _chatService.markAsRead(widget.chatId),
              ),
            ),
            if (_typingUsers.contains(widget.otherUserId))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.voltCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.otherUserName} is typing...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.voltCyan,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (_currentText.isEmpty)
              _QuickReplyChips(onSelect: (msg) => _inputCtrl.text = msg),
            _ChatInputBar(
              controller: _inputCtrl,
              sending: _sending,
              isDark: isDark,
              theme: theme,
              onSend: () => _send(),
              onPlusTap: _showFitnessSuggestions,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// COMPONENTS
// ─────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String otherUserName;
  final String otherUserId;
  final String chatId;
  final VoidCallback onBack;
  final bool isOnline;

  const _ChatHeader({
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
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: onBack,
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(targetUserId: otherUserId),
            ),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          ProfileAvatar(
            imageUrl: null,
            name: otherUserName,
            radius: 18,
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.2),
            foregroundColor: AppColors.irisViolet,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(otherUserName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOnline ? Colors.green : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ]),
      ),
      actions: [
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

  const _ChatMoreOptionsSheet({
    required this.otherUserId,
    required this.otherUserName,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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


class _MessageList extends StatelessWidget {
  final Stream<List<ChatMessage>> stream;
  final ScrollController scrollCtrl;
  final String myId;
  final ThemeData theme;
  final bool isDark;
  final List<ChatMessage> optimisticMessages;
  final VoidCallback? onNewMessageArrived;

  const _MessageList({
    required this.stream,
    required this.scrollCtrl,
    required this.myId,
    required this.theme,
    required this.isDark,
    required this.optimisticMessages,
    this.onNewMessageArrived,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.irisViolet),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading messages',
                style: TextStyle(color: theme.colorScheme.error)),
          );
        }

        // Merge realtime messages with still-pending optimistic ones.
        final streamMsgs = snapshot.data ?? [];
        
        // Trigger read receipts in background
        final hasUnread = streamMsgs.any((m) => m.senderId != myId && !m.isRead);
        if (hasUnread && onNewMessageArrived != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onNewMessageArrived!();
          });
        }

        final pendingOptimistic = optimisticMessages.where((opt) {
          return !streamMsgs.any((m) =>
              m.senderId == opt.senderId &&
              m.message == opt.message &&
              m.createdAt.isAfter(
                  opt.createdAt.subtract(const Duration(seconds: 10))));
        }).toList();

        final allMsgs = [...streamMsgs, ...pendingOptimistic];
        allMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final msgs = allMsgs.reversed.toList();

        if (msgs.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.messageCircle,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.25)),
              const SizedBox(height: 16),
              Text('Say hi to start the conversation',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          );
        }

        return ListView.builder(
          reverse: true,
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final msg       = msgs[i];
            final isMe      = msg.senderId == myId;
            final isPending = msg.id.startsWith('temp-');
            return _Bubble(
              key: ValueKey(msg.id),
              msg: msg,
              isMe: isMe,
              theme: theme,
              isDark: isDark,
              isPending: isPending,
            );

          },
        );
      },
    );
  }
}

class _Bubble extends StatefulWidget {
  final ChatMessage msg;
  final bool isMe;
  final ThemeData theme;
  final bool isDark;
  final bool isPending;

  const _Bubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.theme,
    required this.isDark,
    this.isPending = false,
  });


  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
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
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: widget.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: widget.isPending ? 0.65 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? AppColors.primary
                            : (widget.isDark
                                ? AppColors.surfaceElevated
                                : Colors.grey.shade200),
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
                                blurRadius: 4)
                          ],
                        ),
                        child: Text(_reaction!,
                            style: const TextStyle(fontSize: 12)),
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
                        color: widget.theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  Text(
                    timeStr,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: widget.theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
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
                      color: isSelected
                          ? AppColors.voltCyan.withValues(alpha: 0.2)
                          : Colors.transparent,
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


class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onSend;
  final VoidCallback onPlusTap;

  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.isDark,
    required this.theme,
    required this.onSend,
    required this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : Colors.white,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(LucideIcons.plus, color: AppColors.irisViolet),
          onPressed: onPlusTap,
        ),
        Expanded(
          child: TextField(
            controller: controller,
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final hasText = value.text.trim().isNotEmpty;
            return GestureDetector(
              onTap: (hasText && !sending) ? onSend : null,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasText
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surfaceElevated
                          : Colors.grey.shade300),
                  shape: BoxShape.circle,
                ),
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        hasText ? LucideIcons.send : LucideIcons.mic,
                        color: hasText ? Colors.white : Colors.grey,
                        size: 18,
                      ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _QuickReplyChips extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _QuickReplyChips({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final replies = [
      'Hey 👋',
      'Great job 🔥',
      'How was your run?',
      'Keep going 💪',
    ];
    return Container(
      height: 50,
      padding: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final reply = replies[i];
          return ActionChip(
            label: Text(reply),
            onPressed: () => onSelect(reply),
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.1),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FITNESS SUGGESTIONS & PROGRESS SHARING HUB
// ─────────────────────────────────────────────────────────────────
class _FitnessSharingHubSheet extends StatefulWidget {
  final ValueChanged<String> onSelect;

  const _FitnessSharingHubSheet({required this.onSelect});

  @override
  State<_FitnessSharingHubSheet> createState() => _FitnessSharingHubSheetState();
}

class _FitnessSharingHubSheetState extends State<_FitnessSharingHubSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final app = context.watch<AppProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
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
            Text(
              'Share Progress & Workouts',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.voltCyan,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.voltCyan,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Phrases'),
                Tab(text: 'My Stats'),
                Tab(text: 'Today\'s Plan'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildPhrasesTab(theme),
                  _buildStatsTab(theme, app, stepTracker),
                  _buildPlansTab(theme, app),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhrasesTab(ThemeData theme) {
    final phrases = [
      'Want to run together?',
      'Great workout today!',
      'Keep your streak alive 🔥',
      "Let's complete today's goal.",
      'Hydrate and keep going 💧',
    ];
    return ListView(
      children: phrases.map((p) => ListTile(
        leading: const Icon(LucideIcons.messageSquare, color: AppColors.primary, size: 20),
        title: Text(p),
        onTap: () => widget.onSelect(p),
      )).toList(),
    );
  }

  Widget _buildStatsTab(ThemeData theme, AppProvider app, StepTrackerProvider stepTracker) {
    final stepsMsg = "I have walked ${stepTracker.steps} steps today! 🚶‍♂️";
    final streakMsg = "My workout streak is currently ${app.currentStreak} days! 🔥";
    final caloriesMsg = "I burned ${stepTracker.calories} kcal so far today! ⚡";

    return ListView(
      children: [
        ListTile(
          leading: const Icon(LucideIcons.footprints, color: AppColors.voltCyan),
          title: const Text('Share Today\'s Steps'),
          subtitle: Text('${stepTracker.steps} steps'),
          onTap: () => widget.onSelect(stepsMsg),
        ),
        ListTile(
          leading: const Icon(LucideIcons.flame, color: AppColors.solarAmber),
          title: const Text('Share My Active Streak'),
          subtitle: Text('${app.currentStreak} days'),
          onTap: () => widget.onSelect(streakMsg),
        ),
        ListTile(
          leading: const Icon(LucideIcons.zap, color: AppColors.primary),
          title: const Text('Share Calories Burned'),
          subtitle: Text('${stepTracker.calories} kcal'),
          onTap: () => widget.onSelect(caloriesMsg),
        ),
      ],
    );
  }

  Widget _buildPlansTab(ThemeData theme, AppProvider app) {
    final plans = app.dailyPlans;
    if (plans.isEmpty) {
      return const Center(
        child: Text('No active plans for today', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      children: plans.map((plan) {
        final inviteMsg = "I am doing a ${plan.title} (${plan.duration}m) workout today! Join me? 🏋️‍♂️";
        return ListTile(
          leading: Icon(
            plan.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: plan.isCompleted ? AppColors.teal : Colors.grey,
          ),
          title: Text(plan.title, style: TextStyle(decoration: plan.isCompleted ? TextDecoration.lineThrough : null)),
          subtitle: Text('${plan.duration}m  •  ${plan.kcal} kcal'),
          trailing: const Icon(LucideIcons.share2, color: AppColors.voltCyan, size: 18),
          onTap: () => widget.onSelect(inviteMsg),
        );
      }).toList(),
    );
  }
}
