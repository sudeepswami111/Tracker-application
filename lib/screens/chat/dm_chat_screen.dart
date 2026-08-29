import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/chat_header.dart';
import '../../widgets/chat/message_list.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/quick_reply_chips.dart';
import '../../widgets/chat/fitness_suggestion_sheet.dart';
import '../../widgets/chat/chats_tab.dart';
import 'new_message_screen.dart';

// ─────────────────────────────────────────────────────────────────
// DM LIST SCREEN — backward compatibility wrapper
// ─────────────────────────────────────────────────────────────────
class DMListScreen extends StatefulWidget {
  const DMListScreen({super.key});

  @override
  State<DMListScreen> createState() => _DMListScreenState();
}

class _DMListScreenState extends State<DMListScreen> {
  final ChatService _chatService = ChatService();
  List<ChatRoom> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final chats = await _chatService.getMyChats();
    if (mounted) {
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ChatsTab(
          chats: _chats,
          isLoading: _isLoading,
          searchQuery: '',
          onRefresh: _loadChats,
          onStartNewChat: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewMessageScreen()),
            ).then((_) => _loadChats());
          },
          onOpenCommunity: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DM CHAT SCREEN — Keyboard safe, realtime 1-on-1 DM Screen
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
  final ChatService _chatService = ChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final _supabase = Supabase.instance.client;

  bool _sending = false;
  late final Stream<List<ChatMessage>> _messagesStream;
  String _currentText = '';

  // Optimistic message send tracking
  final List<ChatMessage> _optimisticMessages = [];

  // Fallback poll: forces a rebuild every 5s in case realtime drops
  Timer? _fallbackPoll;

  // Presence channel states
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

    // Rebuild every 5 seconds to ensure stream stays fresh
    _fallbackPoll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });

    // Subscribe to typing presence and online channel
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

    final myId = _supabase.auth.currentUser?.id ?? '';
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Optimistic UI update
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
      if (mounted) {
        setState(() {
          final idx = _optimisticMessages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _optimisticMessages[idx] = insertedMsg;
          }
        });
      }
    } catch (e) {
      // Handle send failure
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
          _sending = false;
        });

        String errorMsg = e.toString();
        if (e is PostgrestException) {
          errorMsg = e.message;
        } else if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Send failed: $errorMsg'),
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
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showFitnessSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FitnessSuggestionSheet(
        onSelect: (msg) {
          Navigator.pop(context);
          _send(msg);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: ChatHeader(
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
              child: MessageList(
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
              QuickReplyChips(onSelect: (msg) => _inputCtrl.text = msg),
            ChatInputBar(
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
