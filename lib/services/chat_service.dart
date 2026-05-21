import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';
  String get currentUserName => _supabase.auth.currentUser?.email?.split('@')[0] ?? 'User';


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 8. GET MY CHATS (1-on-1 DMs after accepted friend requests)
  //    Mirrors JS getMyChats() exactly â€” explicit FK names,
  //    maps to friend = user1 if user2 is me, else user2.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<List<ChatRoom>> getMyChats() async {
    final userId = currentUserId;
    if (userId.isEmpty) return [];

    try {
      if (kDebugMode) print('getMyChats() for userId: $userId');

      final data = await _supabase
          .from('chats')
          .select('''
            id,
            user1_id,
            user2_id,
            created_at,
            user1:profiles!chats_user1_id_fkey (
              id,
              full_name,
              username,
              avatar_url
            ),
            user2:profiles!chats_user2_id_fkey (
              id,
              full_name,
              username,
              avatar_url
            )
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', ascending: false);

      if (kDebugMode) print('âœ… Chats loaded: ${(data as List).length}');

      return (data as List)
          .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>, userId))
          .toList();
    } catch (e) {
      if (kDebugMode) print('getMyChats error: $e');
      return [];
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 9. SEND DM MESSAGE  (mirrors JS sendMessage exactly)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> sendDM(String chatId, String message) async {
    if (message.trim().isEmpty) return;
    try {
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'message': message.trim(),
      });
    } catch (e) {
      if (kDebugMode) print('sendDM error: $e');
      rethrow;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 9.5 GET MESSAGES FOR A CHAT (One-time fetch)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<List<ChatMessage>> getMessages(String chatId) async {
    final data = await _supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 10. LIVE CHAT MESSAGES  (mirrors JS useEffect realtime)
  //    Dart uses .stream() which is equivalent to the JS:
  //    supabase.channel(`chat-${chatId}`)
  //      .on('postgres_changes', { event: 'INSERT', table: 'messages',
  //           filter: `chat_id=eq.${chatId}` }, ...)
  //      .subscribe()
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Stream<List<ChatMessage>> getDMMessagesStream(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .map(ChatMessage.fromJson)
            .toList());
  }

  // Manual realtime channel (for granular control, matches JS useEffect pattern)
  RealtimeChannel subscribeToChat(
    String chatId, {
    required void Function(ChatMessage msg) onNewMessage,
  }) {
    return _supabase
        .channel('chat-$chatId')                   // channel(`chat-${chatId}`)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,        // event: 'INSERT'
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',                      // filter: chat_id=eq.${chatId}
            value: chatId,
          ),
          callback: (payload) {
            if (kDebugMode) print('New DM: ${payload.newRecord}');
            final msg = ChatMessage.fromJson(payload.newRecord);
            onNewMessage(msg);                      // setMessages(prev => [...prev, payload.new])
          },
        )
        .subscribe((status, [error]) {
          if (kDebugMode) print('Chat realtime status: $status ${error ?? ""}');
        });
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 11. MARK MESSAGES AS READ
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> markAsRead(String chatId) async {
    final userId = currentUserId;
    if (userId.isEmpty) return;
    try {
      await _supabase
          .from('messages')
          .update({
            'is_read': true, 
            'read_at': DateTime.now().toIso8601String()
          })
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      if (kDebugMode) print('markAsRead error: $e');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 12. PRESENCE (TYPING INDICATORS & ONLINE STATUS)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  RealtimeChannel subscribeToPresence(
    String chatId, {
    required void Function(List<String> typingUsers) onTypingChanged,
    required void Function(List<String> onlineUsers) onOnlineChanged,
  }) {
    final userId = currentUserId;
    final channel = _supabase.channel('presence_$chatId');

    channel
        .onPresenceSync((payload) {
          final state = channel.presenceState();
          final typingUsers = <String>[];
          final onlineUsers = <String>[];
          
          for (final stateObj in state) {
            for (final p in stateObj.presences) {
              final payload = p.payload;
              if (payload['userId'] != null) {
                onlineUsers.add(payload['userId'] as String);
                if (payload['isTyping'] == true && payload['userId'] != userId) {
                  typingUsers.add(payload['userId'] as String);
                }
              }
            }
          }
          onTypingChanged(typingUsers);
          onOnlineChanged(onlineUsers);
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await channel.track({
              'userId': userId, 
              'isTyping': false, 
              'online': true
            });
          }
        });

    return channel;
  }

  Future<void> setTyping(RealtimeChannel channel, bool isTyping) async {
    final userId = currentUserId;
    if (userId.isEmpty) return;
    try {
      await channel.track({
        'userId': userId, 
        'isTyping': isTyping, 
        'online': true
      });
    } catch (e) {
      // Ignore presence track errors if channel is disconnected
    }
  }
}
