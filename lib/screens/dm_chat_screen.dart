import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';

// ====================================================
// PREMIUM DM LIST SCREEN
// ====================================================
class DMListScreen extends StatefulWidget {
  const DMListScreen({super.key});

  @override
  State<DMListScreen> createState() => _DMListScreenState();
}

class _DMListScreenState extends State<DMListScreen> {
  final ChatService _service = ChatService();
  List<ChatRoom> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _chats = await _service.getMyChats();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Messages', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.irisViolet))
          : _chats.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  color: AppColors.irisViolet,
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _chats.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _buildChatTile(_chats[i], theme, isDark, i % 3 == 0),
                  ),
                ),
    );
  }

  Widget _buildChatTile(ChatRoom chat, ThemeData theme, bool isDark, bool isOnline) {
    final friend = chat.friend;
    final bool hasUnread = chat.chatId.hashCode % 2 != 0; // Mocking unread for premium UI demo

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => DMChatScreen(chatRoom: chat)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with Online Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
                  backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                      ? NetworkImage(friend.avatarUrl!)
                      : null,
                  child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty
                      ? Text(friend.initials, style: const TextStyle(color: AppColors.irisViolet, fontWeight: FontWeight.bold, fontSize: 16))
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.voltCyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.surfaceElevated : Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Name & Message Preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        friend.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      Text(
                        '12m', // mock timestamp
                        style: TextStyle(
                          color: hasUnread ? AppColors.irisViolet : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Tap to start chatting...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasUnread ? theme.colorScheme.onSurface : AppColors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.irisViolet, shape: BoxShape.circle),
                          child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.irisViolet.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.messageSquare, size: 48, color: AppColors.irisViolet),
          ),
          const SizedBox(height: 24),
          Text('No messages yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Connect with friends to start chatting', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ====================================================
// PREMIUM DM CONVERSATION SCREEN
// ====================================================
class DMChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  const DMChatScreen({super.key, required this.chatRoom});

  @override
  State<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends State<DMChatScreen> {
  final ChatService _service = ChatService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final Stream<List<ChatMessage>> _stream;
  bool _hasText = false;

  // Realtime Presence State
  Timer? _typingTimer;
  bool _isFriendTyping = false;
  bool _isFriendOnline = false;
  dynamic _presenceChannel; // RealtimeChannel

  @override
  void initState() {
    super.initState();
    _stream = _service.getDMMessagesStream(widget.chatRoom.chatId);
    
    // Mark messages as read when opening
    _service.markAsRead(widget.chatRoom.chatId);

    // Subscribe to typing and online status
    _presenceChannel = _service.subscribeToPresence(
      widget.chatRoom.chatId,
      onTypingChanged: (typingUsers) {
        if (mounted) {
          setState(() {
            _isFriendTyping = typingUsers.contains(widget.chatRoom.friend.id);
            if (_isFriendTyping) _scrollToBottom();
          });
        }
      },
      onOnlineChanged: (onlineUsers) {
        if (mounted) {
          setState(() {
            _isFriendOnline = onlineUsers.contains(widget.chatRoom.friend.id);
          });
        }
      },
    );

    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);

      // Typing debouncer
      if (_presenceChannel != null) {
        _service.setTyping(_presenceChannel!, true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          _service.setTyping(_presenceChannel!, false);
        });
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_presenceChannel != null) {
      _service.setTyping(_presenceChannel!, false);
      Supabase.instance.client.removeChannel(_presenceChannel!);
    }
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    HapticFeedback.lightImpact();
    await _service.sendDM(widget.chatRoom.chatId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final friend = widget.chatRoom.friend;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: _buildAppBar(theme, friend),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return _buildEmptyChatState(theme, friend);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _service.currentUserId;
                    return _buildBubble(msg, isMe, theme, isDark);
                  },
                );
              },
            ),
          ),
          if (_isFriendTyping) _buildTypingIndicator(theme, isDark, friend),
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ChatFriend friend) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      leading: IconButton(icon: const Icon(LucideIcons.chevronLeft, size: 28), onPressed: () => Navigator.pop(context)),
      title: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
                backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty ? NetworkImage(friend.avatarUrl!) : null,
                child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty ? Text(friend.initials, style: const TextStyle(color: AppColors.irisViolet, fontWeight: FontWeight.bold, fontSize: 12)) : null,
              ),
              if (_isFriendOnline)
                Positioned(
                  right: -2, bottom: -2,
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.voltCyan, shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2))),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(friend.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_isFriendOnline ? 'Active now' : 'Offline', style: TextStyle(color: _isFriendOnline ? AppColors.voltCyan : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(LucideIcons.phone, size: 20), onPressed: () {}),
        IconButton(icon: const Icon(LucideIcons.video, size: 20), onPressed: () {}),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmptyChatState(ThemeData theme, ChatFriend friend) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.1),
            backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
            child: friend.avatarUrl == null ? Text(friend.initials, style: const TextStyle(fontSize: 24, color: AppColors.irisViolet)) : null,
          ),
          const SizedBox(height: 16),
          Text(friend.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You are now connected on LifePulse.\nSay hi!', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe, ThemeData theme, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.irisViolet : (isDark ? AppColors.surfaceElevated : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: isMe ? [BoxShadow(color: AppColors.irisViolet.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          border: isMe ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.checkCheck, size: 12, color: msg.isRead ? AppColors.voltCyan : Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(color: isDark ? AppColors.surfaceElevated : Colors.white, shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(LucideIcons.plus, size: 22), color: AppColors.textSecondary, onPressed: () {}),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.smile, size: 20),
                            color: AppColors.textSecondary,
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _hasText ? _send : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _hasText ? AppColors.irisViolet : (isDark ? AppColors.surfaceElevated : Colors.white),
                        shape: BoxShape.circle,
                        boxShadow: _hasText ? [BoxShadow(color: AppColors.irisViolet.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))] : null,
                      ),
                      child: Icon(LucideIcons.send, color: _hasText ? Colors.white : AppColors.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, bool isDark, ChatFriend friend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Text('typing...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }
}
