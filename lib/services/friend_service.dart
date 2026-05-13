import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_models.dart';

class FriendService {
  final SupabaseClient _client = Supabase.instance.client;

  // ──────────────────────────────────────────────────────────────────
  // 1. GET FRIEND SUGGESTIONS (Scoring Engine)
  //    Logic mirrors the reference JS implementation exactly:
  //    +30 same fitness goal | +20 same city | +15 same activity level
  //    +10 per shared interest | +10 similar step goal (±2000)
  //    Score capped at 100. Only users with score > 0 returned (top 10).
  // ──────────────────────────────────────────────────────────────────
  Future<List<FriendSuggestion>> getFriendSuggestions(String userId) async {
    try {
      // ── Run all 5 queries in parallel for speed ───────────────────
      final results = await Future.wait<dynamic>([
        _client.from('profiles').select().eq('id', userId).maybeSingle(),
        _client.from('profiles').select().neq('id', userId),
        _client
            .from('friend_requests')
            .select('sender_id, receiver_id')
            .or('sender_id.eq.$userId,receiver_id.eq.$userId'),
        _client
            .from('friendships')
            .select('user1_id, user2_id')
            .or('user1_id.eq.$userId,user2_id.eq.$userId'),
        _client
            .from('dismissed_suggestions')
            .select('dismissed_user_id')
            .eq('user_id', userId),
      ]);

      final myProfileRaw = results[0] as Map<String, dynamic>?;
      if (myProfileRaw == null) return [];
      final myProfile = FitnessProfile.fromJson(myProfileRaw);

      final allUsers = (results[1] as List)
          .map((e) => FitnessProfile.fromJson(e as Map<String, dynamic>))
          .toList();

      // ── Build blocked ID set (requests + friendships + dismissed) ─
      final Set<String> blockedIds = {};

      for (final r in results[2] as List) {
        blockedIds.add(r['sender_id'] as String);
        blockedIds.add(r['receiver_id'] as String);
      }
      for (final f in results[3] as List) {
        blockedIds.add(f['user1_id'] as String);
        blockedIds.add(f['user2_id'] as String);
      }
      for (final d in results[4] as List) {
        blockedIds.add(d['dismissed_user_id'] as String);
      }

      // ── Score each candidate ──────────────────────────────────────
      final suggestions = allUsers
          .where((u) => !blockedIds.contains(u.id))
          .map((candidate) {
            int score = 0;
            final reasons = <String>[];

            // +30 same fitness goal
            if (myProfile.fitnessGoal != null &&
                candidate.fitnessGoal == myProfile.fitnessGoal) {
              score += 30;
              reasons.add('Same goal: ${candidate.fitnessGoal}');
            }

            // +20 same city
            if (myProfile.city != null &&
                candidate.city != null &&
                candidate.city == myProfile.city) {
              score += 20;
              reasons.add('Near you in ${candidate.city}');
            }

            // +15 same activity level
            if (myProfile.activityLevel != null &&
                candidate.activityLevel == myProfile.activityLevel) {
              score += 15;
              reasons.add('${candidate.activityLevel} activity level');
            }

            // +10 per shared interest
            final sharedInterests = candidate.interests
                .where((i) => myProfile.interests.contains(i))
                .toList();
            if (sharedInterests.isNotEmpty) {
              score += sharedInterests.length * 10;
              reasons.add('Shared: ${sharedInterests.take(2).join(", ")}');
            }

            // +10 similar step goal (within 2000 steps)
            final stepDiff =
                (candidate.dailyStepGoal - myProfile.dailyStepGoal).abs();
            if (stepDiff <= 2000) {
              score += 10;
              reasons.add('Similar step goal');
            }

            // Cap at 100
            final cappedScore = score.clamp(0, 100);

            return FriendSuggestion(
              profile: candidate,
              matchScore: cappedScore,
              matchReasons: reasons,
            );
          })
          .where((s) => s.matchScore > 0)       // only show relevant matches
          .toList()
        ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

      if (kDebugMode) {
        print('Friend suggestions fetched: ${suggestions.length} results');
        for (final s in suggestions.take(3)) {
          print('  → ${s.profile.username}: score=${s.matchScore} reasons=${s.matchReasons}');
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      if (kDebugMode) print('getFriendSuggestions error: $e');
      return [];
    }
  }


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
  // 5. DISMISS SUGGESTION  (mirrors JS: .insert, throws on error)
  // ──────────────────────────────────────────────────────────────────
  Future<bool> dismissSuggestion(String userId, String dismissedUserId) async {
    try {
      await _client.from('dismissed_suggestions').insert({
        'user_id': userId,
        'dismissed_user_id': dismissedUserId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('dismissSuggestion error: $e');
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
