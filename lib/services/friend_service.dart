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
      // ── Run all 4 queries in parallel for speed ───────────────────
      final results = await Future.wait([
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
  // ──────────────────────────────────────────────────────────────────
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      // Get the request
      final req = await _client
          .from('friend_requests')
          .select()
          .eq('id', requestId)
          .single();

      final senderId = req['sender_id'] as String;
      final receiverId = req['receiver_id'] as String;

      // Ensure user1_id < user2_id to prevent duplicate pairs
      final user1 = senderId.compareTo(receiverId) < 0 ? senderId : receiverId;
      final user2 = senderId.compareTo(receiverId) < 0 ? receiverId : senderId;

      // Update request status
      await _client
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Create friendship (upsert to avoid duplicates)
      await _client.from('friendships').upsert({
        'user1_id': user1,
        'user2_id': user2,
      }, onConflict: 'user1_id,user2_id');

      return true;
    } catch (e) {
      if (kDebugMode) print('acceptFriendRequest error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 4. REJECT FRIEND REQUEST
  // ──────────────────────────────────────────────────────────────────
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _client
          .from('friend_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
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
  // ──────────────────────────────────────────────────────────────────
  Future<List<FriendRequest>> getIncomingRequests(String userId) async {
    try {
      final res = await _client
          .from('friend_requests')
          .select('*, sender:sender_id(id, username, full_name, avatar_url, fitness_goal)')
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('getIncomingRequests error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 7. REALTIME: SUBSCRIBE TO FRIEND REQUESTS
  // ──────────────────────────────────────────────────────────────────
  RealtimeChannel subscribeToFriendRequests(
    String userId, {
    required void Function(FriendRequest request) onNew,
    required void Function(FriendRequest request) onUpdate,
  }) {
    return _client
        .channel('friend_requests_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'friend_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            final req = FriendRequest.fromJson(payload.newRecord);
            onNew(req);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'friend_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: userId,
          ),
          callback: (payload) {
            final req = FriendRequest.fromJson(payload.newRecord);
            onUpdate(req);
          },
        )
        .subscribe();
  }
}
