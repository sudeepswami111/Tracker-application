import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_models.dart';

class FriendService {
  final SupabaseClient _client = Supabase.instance.client;

  // ──────────────────────────────────────────────────────────────────
  // 2. SEND FRIEND REQUEST
  // ──────────────────────────────────────────────────────────────────
  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    if (senderId == receiverId) return false;
    try {
      await _client.from('friend_requests').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('sendFriendRequest error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 3. ACCEPT FRIEND REQUEST
  //    Mirrors JS: sort user IDs, update status, insert friendship,
  //    insert chat room — 23505 (unique violation) ignored on both.
  // ──────────────────────────────────────────────────────────────────
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final req = await _client
          .from('friend_requests')
          .select()
          .eq('id', requestId)
          .single();

      final user1 = req['sender_id'] as String;
      final user2 = req['receiver_id'] as String;

      // Sort exactly like JS: [user1, user2].sort()
      final sorted = [user1, user2]..sort();
      final sortedUser1 = sorted[0];
      final sortedUser2 = sorted[1];

      // 1. Update request status → accepted
      await _client
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // 2. Create friendship (ignore 23505 duplicate)
      try {
        await _client.from('friendships').insert({
          'user1_id': sortedUser1,
          'user2_id': sortedUser2,
        });
      } catch (e) {
        if (!e.toString().contains('23505')) rethrow;
      }

      // 3. Create chat room (ignore 23505 duplicate)
      try {
        await _client.from('chats').insert({
          'user1_id': sortedUser1,
          'user2_id': sortedUser2,
        });
      } catch (e) {
        if (!e.toString().contains('23505')) rethrow;
      }

      if (kDebugMode) print('✅ Friend request accepted, friendship + chat created');
      return true;
    } catch (e) {
      if (kDebugMode) print('acceptFriendRequest error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 4. REJECT FRIEND REQUEST  (mirrors JS exactly)
  // ──────────────────────────────────────────────────────────────────
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _client
          .from('friend_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
      if (kDebugMode) print('✅ Friend request rejected: $requestId');
      return true;
    } catch (e) {
      if (kDebugMode) print('rejectFriendRequest error: $e');
      return false;
    }
  }


  // ──────────────────────────────────────────────────────────────────
  // 6. GET INCOMING FRIEND REQUESTS
  //    Uses explicit FK name !friend_requests_sender_id_fkey to match
  //    the JS reference query and avoid Supabase join ambiguity.
  // ──────────────────────────────────────────────────────────────────
  Future<List<FriendRequest>> getIncomingRequests(String userId) async {
    try {
      // ── Verify the correct receiver_id is being used ─────────────
      if (kDebugMode) {
        print('┌─────────────────────────────────────────────');
        print('│ getIncomingRequests()');
        print('│ Logged-in user (receiver_id): $userId');
        print('│ Querying: friend_requests WHERE receiver_id = $userId AND status = pending');
        print('└─────────────────────────────────────────────');
      }

      final res = await _client
          .from('friend_requests')
          .select('''
            *,
            sender:profiles!friend_requests_sender_id_fkey(
              id,
              full_name,
              avatar_url,
              fitness_goal
            )
          ''')
          .eq('receiver_id', userId)   // ← must match the logged-in user's ID
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print('✅ Incoming requests count: ${(res as List).length}');
        for (final r in res) {
          print('  → id=${r['id']} sender=${r['sender']?['full_name']} status=${r['status']}');
        }
      }

      return (res as List)
          .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ getIncomingRequests error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 7. REALTIME: SUBSCRIBE TO INCOMING FRIEND REQUESTS
  //
  //    Dart equivalent of:
  //    supabase
  //      .channel(`incoming-requests-${userId}`)
  //      .on('postgres_changes', { event: '*', table: 'friend_requests',
  //           filter: `receiver_id=eq.${userId}` }, payload => {
  //        loadIncomingRequests();
  //      })
  //      .subscribe();
  //
  //    onAnyChange → called on INSERT, UPDATE, DELETE
  //    (equivalent to JS payload => loadIncomingRequests())
  // ──────────────────────────────────────────────────────────────────
  RealtimeChannel subscribeToIncomingRequests(
    String userId, {
    required void Function() onAnyChange,
  }) {
    if (kDebugMode) {
      print('Realtime: subscribing to incoming-requests-$userId');
    }

    return _client
        .channel('incoming-requests-$userId')   // matches JS channel name exactly
        .onPostgresChanges(
          event: PostgresChangeEvent.all,         // event: '*'
          schema: 'public',
          table: 'friend_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',               // filter: receiver_id=eq.${userId}
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) print('Realtime: incoming request change: ${payload.eventType} → ${payload.newRecord}');
            onAnyChange();                        // → loadIncomingRequests()
          },
        )
        .subscribe((status, [error]) {
          if (kDebugMode) print('Realtime status: $status ${error ?? ""}');
        });
  }
}
