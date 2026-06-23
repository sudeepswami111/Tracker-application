import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';
  String get currentUserName => _supabase.auth.currentUser?.email?.split('@')[0] ?? 'User';


  // ──────────────────────────────────────────────────────────────────
  // 8. GET MY CHATS (1-on-1 DMs after accepted friend requests)
  //    Mirrors JS getMyChats() exactly — explicit FK names,
  //    maps to friend = user1 if user2 is me, else user2.
  // ──────────────────────────────────────────────────────────────────
  Future<List<ChatRoom>> getMyChats() async {
    final userId = currentUserId;
    if (userId.isEmpty) return [];

    try {
      if (kDebugMode) print('getMyChats() for userId: $userId');

      final data = await _supabase
          .rpc('get_my_chat_rooms', params: {'p_user_id': userId});

      if (kDebugMode) print('✅ Chats loaded: ${(data as List).length}');

      return (data as List)
          .map((e) => ChatRoom.fromRpcJson(e as Map<String, dynamic>, userId))
          .toList();
    } catch (e) {
      if (kDebugMode) print('getMyChats error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 8.5 GET OR CREATE DM CHAT (Deterministic)
  // ──────────────────────────────────────────────────────────────────
  Future<String> getOrCreateDmChat(String otherUserId) async {
    final me = currentUserId;
    if (me.isEmpty || otherUserId.isEmpty) throw Exception('User ID is empty');

    final u1 = me.compareTo(otherUserId) < 0 ? me : otherUserId;
    final u2 = me.compareTo(otherUserId) < 0 ? otherUserId : me;

    try {
      // 1. Try to find existing
      final res = await _supabase
          .from('chats')
          .select('id')
          .eq('user1_id', u1)
          .eq('user2_id', u2)
          .maybeSingle();
      
      if (res != null) {
        return res['id'] as String;
      }

      // 2. Create if not exists
      final insertRes = await _supabase
          .from('chats')
          .insert({
            'user1_id': u1,
            'user2_id': u2,
          })
          .select('id')
          .single();
          
      return insertRes['id'] as String;
    } catch (e) {
      if (kDebugMode) print('getOrCreateDmChat error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 9. SEND DM MESSAGE  (mirrors JS sendMessage exactly)
  // ──────────────────────────────────────────────────────────────────
  Future<bool> canSendInChat(String chatId) async {
    final me = currentUserId;
    if (me.isEmpty) return false;
    try {
      final chat = await _supabase
          .from('chats')
          .select('id,user1_id,user2_id')
          .eq('id', chatId)
          .maybeSingle();
      if (chat == null) return false;
      return chat['user1_id'] == me || chat['user2_id'] == me;
    } catch (e) {
      if (kDebugMode) print('canSendInChat error: $e');
      return false;
    }
  }

  Future<ChatMessage> sendDM(String chatId, String message) async {
    if (message.trim().isEmpty) throw Exception('Message is empty');
    
    final me = currentUserId;
    if (me.isEmpty) throw Exception('Not authenticated');

    // Ensure sender has a profile row to satisfy foreign key constraints
    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', me)
        .maybeSingle();
    if (profile == null) {
      throw Exception('Profile missing. Please update your profile.');
    }

    // Verify chat exists and user is a member
    final canSend = await canSendInChat(chatId);
    if (!canSend) {
      throw Exception('Chat not found or current user is not a member.');
    }

    try {
      if (kDebugMode) {
        print('DM SEND: chatId=$chatId sender=$me messageLen=${message.trim().length}');
      }

      final res = await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': me,
        'message': message.trim(),
      }).select().single();

      final insertedMsg = ChatMessage.fromJson(res);

      // Create notification without failing the message send if it fails
      try {
        final chatData = await _supabase
            .from('chats')
            .select('user1_id, user2_id')
            .eq('id', chatId)
            .maybeSingle();

        if (chatData != null) {
          final otherUser = chatData['user1_id'] == me
              ? chatData['user2_id']
              : chatData['user1_id'];

          final myProfile = await _supabase
              .from('profiles')
              .select('full_name, username')
              .eq('id', me)
              .maybeSingle();

          final myName = (myProfile?['full_name'] as String?)?.isNotEmpty == true
              ? myProfile!['full_name']
              : myProfile?['username'] ?? 'Someone';

          await _supabase.from('notifications').insert({
            'user_id': otherUser,
            'actor_id': me,
            'type': 'message',
            'title': myName,
            'body': message.trim().length > 80
                ? '${message.trim().substring(0, 80)}...'
                : message.trim(),
            'reference_id': insertedMsg.id,
          });
        }
      } catch (notificationError) {
        if (kDebugMode) {
          print('Notification failed but message sent: $notificationError');
        }
      }

      if (kDebugMode) print('DM SEND SUCCESS: $res');
      return insertedMsg;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('DM SEND POSTGREST ERROR');
        print('code: ${e.code}');
        print('message: ${e.message}');
        print('details: ${e.details}');
        print('hint: ${e.hint}');
      }
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        print('DM SEND UNKNOWN ERROR: $e');
        print('$st');
      }
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 9.5 GET MESSAGES FOR A CHAT (One-time fetch)
  // ──────────────────────────────────────────────────────────────────
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

  // ──────────────────────────────────────────────────────────────────
  // 10. LIVE CHAT MESSAGES  (mirrors JS useEffect realtime)
  //    Dart uses .stream() which is equivalent to the JS:
  //    supabase.channel(`chat-${chatId}`)
  //      .on('postgres_changes', { event: 'INSERT', table: 'messages',
  //           filter: `chat_id=eq.${chatId}` }, ...)
  //      .subscribe()
  // ──────────────────────────────────────────────────────────────────
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

  // ──────────────────────────────────────────────────────────────────
  // 11. MARK MESSAGES AS READ
  // ──────────────────────────────────────────────────────────────────
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

  // ──────────────────────────────────────────────────────────────────
  // 12. PRESENCE (TYPING INDICATORS & ONLINE STATUS)
  // ──────────────────────────────────────────────────────────────────
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

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      if (kDebugMode) print('deleteMessage error: $e');
      rethrow;
    }
  }

  Future<void> clearChatHistory(String chatId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);
    } catch (e) {
      if (kDebugMode) print('clearChatHistory error: $e');
      rethrow;
    }
  }
}

