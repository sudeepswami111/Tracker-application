import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../services/follow_service.dart';
import '../widgets/profile_avatar.dart';

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

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.getDMMessagesStream(widget.chatId);
    _chatService.markAsRead(widget.chatId);
    _inputCtrl.addListener(() {
      setState(() {
        _currentText = _inputCtrl.text;
      });
    });

    // Fallback: force a rebuild every 5 s so the StreamBuilder picks up any
    // new snapshot that arrived while realtime was silently disconnected.
    _fallbackPoll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fallbackPoll?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
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
      await _chatService.sendDM(widget.chatId, text);
      // The real message arrives via realtime stream, which will match the
      // optimistic one by sender+text and the temp bubble disappears naturally.
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
        });
      }
    } catch (e) {
      // Send failed — remove the optimistic bubble and show error
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message failed to send. Tap to retry.'),
            behavior: SnackBarBehavior.floating,
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
      builder: (context) => _FitnessSuggestionSheet(
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
        onBack: () => Navigator.pop(context),
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
  final VoidCallback onBack;

  const _ChatHeader({required this.otherUserName, required this.onBack});

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
      title: Row(children: [
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
            Text('Online',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.green, fontSize: 11)),
          ],
        ),
      ]),
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

  const _MessageList({
    required this.stream,
    required this.scrollCtrl,
    required this.myId,
    required this.theme,
    required this.isDark,
    this.optimisticMessages = const [],
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
        // An optimistic message is considered confirmed (drop it) when the stream
        // contains a real message with the same sender + text from ≤ 10 s ago.
        final streamMsgs = snapshot.data ?? [];
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

  void _showReactions() {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.surfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(12),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '🔥', '💪', '😂']
              .map((r) => GestureDetector(
                    onTap: () {
                      setState(() => _reaction = r);
                      Navigator.pop(context);
                    },
                    child: Text(r, style: const TextStyle(fontSize: 28)),
                  ))
              .toList(),
        ),
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
        onLongPress: widget.isPending ? null : _showReactions,
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

class _FitnessSuggestionSheet extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _FitnessSuggestionSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = [
      'Want to run together?',
      'Great workout today!',
      'Keep your streak alive 🔥',
      "Let's complete today's goal.",
      'Hydrate and keep going 💧',
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
            const SizedBox(height: 20),
            Text('Quick Suggestions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...suggestions.map((s) => ListTile(
                  leading: const Icon(LucideIcons.messageSquare,
                      color: AppColors.primary),
                  title: Text(s),
                  onTap: () => onSelect(s),
                )),
          ],
        ),
      ),
    );
  }
}
