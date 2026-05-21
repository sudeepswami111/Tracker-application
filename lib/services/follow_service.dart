import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────
// FOLLOW SERVICE — Instagram-style social graph
// Tables used: follows, profiles (followers_count, following_count)
// ─────────────────────────────────────────────────────────────────

enum FollowStatus { none, pending, accepted }

class FollowUser {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final FollowStatus followStatus;

  const FollowUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.followStatus = FollowStatus.none,
  });

  factory FollowUser.fromJson(Map<String, dynamic> j) => FollowUser(
        id: j['id'] as String,
        username: j['username'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
        followersCount: (j['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (j['following_count'] as num?)?.toInt() ?? 0,
        followStatus: _parseStatus(j['follow_status'] as String?),
      );

  static FollowStatus _parseStatus(String? s) {
    switch (s) {
      case 'pending':  return FollowStatus.pending;
      case 'accepted': return FollowStatus.accepted;
      default:         return FollowStatus.none;
    }
  }
}

class FollowService {
  final _supabase = Supabase.instance.client;
  String get _me => _supabase.auth.currentUser?.id ?? '';

  // ──────────────────────────────────────────────────────────────
  // 1. SEND FOLLOW REQUEST  (status = 'pending')
  //    Returns the new follow row id, or null on failure.
  // ──────────────────────────────────────────────────────────────
  Future<String?> sendFollowRequest(String targetUserId) async {
    if (_me.isEmpty || _me == targetUserId) return null;
    try {
      final res = await _supabase.from('follows').insert({
        'follower_id':  _me,
        'following_id': targetUserId,
        'status':       'pending',
      }).select('id').single();
      if (kDebugMode) print('✅ Follow request sent → ${res['id']}');
      return res['id'] as String;
    } catch (e) {
      if (kDebugMode) print('sendFollowRequest error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 2. ACCEPT FOLLOW REQUEST  (target user calls this)
  //    Updates status → 'accepted'.
  //    The DB trigger will:
  //      • increment followers/following counts
  //      • create a chat row
  //      • insert a 'follow_accepted' notification
  // ──────────────────────────────────────────────────────────────
  Future<bool> acceptFollowRequest(String followId) async {
    try {
      if (kDebugMode) print('🔄 Accepting follow: id=$followId, me=$_me');
      final res = await _supabase
          .from('follows')
          .update({'status': 'accepted'})
          .eq('id', followId)
          .eq('following_id', _me) // RLS: only target can accept
          .select();
      if (kDebugMode) print('✅ Follow accepted: $followId, rows: ${(res as List).length}');
      return (res as List).isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('❌ acceptFollowRequest error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 3. REJECT / CANCEL FOLLOW REQUEST — deletes the row
  //    Call from requester (cancel) or target (reject).
  // ──────────────────────────────────────────────────────────────
  Future<bool> deleteFollow(String followId) async {
    try {
      await _supabase.from('follows').delete().eq('id', followId);
      if (kDebugMode) print('✅ Follow row deleted: $followId');
      return true;
    } catch (e) {
      if (kDebugMode) print('deleteFollow error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 4. UNFOLLOW (accepted follow) — same as delete
  // ──────────────────────────────────────────────────────────────
  Future<bool> unfollow(String targetUserId) async {
    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', _me)
          .eq('following_id', targetUserId);
      return true;
    } catch (e) {
      if (kDebugMode) print('unfollow error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 5. GET INCOMING FOLLOW REQUESTS  (pending requests to current user)
  // ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    if (_me.isEmpty) return [];
    try {
      final res = await _supabase
          .from('follows')
          .select('''
            id,
            follower_id,
            created_at,
            follower:profiles!follows_follower_id_fkey(
              id, username, full_name, avatar_url
            )
          ''')
          .eq('following_id', _me)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) print('getIncomingRequests error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 6. GET FOLLOWERS LIST  (people who follow the given userId)
  // ──────────────────────────────────────────────────────────────
  Future<List<FollowUser>> getFollowers(String userId) async {
    try {
      final res = await _supabase.rpc('get_followers', params: {'p_user_id': userId});
      return (res as List).map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('getFollowers error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 7. GET FOLLOWING LIST  (people the given userId follows)
  // ──────────────────────────────────────────────────────────────
  Future<List<FollowUser>> getFollowing(String userId) async {
    try {
      final res = await _supabase.rpc('get_following', params: {'p_user_id': userId});
      return (res as List).map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('getFollowing error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 8. PEOPLE SUGGESTIONS  (users not yet followed by current user)
  // ──────────────────────────────────────────────────────────────
  Future<List<FollowUser>> getSuggestions({int limit = 20}) async {
    if (_me.isEmpty) return [];
    try {
      final res = await _supabase.rpc('get_suggestions', params: {
        'p_current_user': _me,
        'p_limit': limit,
      });
      return (res as List).map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('getSuggestions error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 9. SEARCH USERS BY USERNAME  (for chat search bar)
  // ──────────────────────────────────────────────────────────────
  Future<List<FollowUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await _supabase.rpc('search_users_by_username', params: {
        'p_query':        query.trim(),
        'p_current_user': _me.isEmpty ? null : _me,
      });
      return (res as List).map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('searchUsers error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 10. CHECK CURRENT FOLLOW STATUS toward a user
  // ──────────────────────────────────────────────────────────────
  Future<FollowStatus> getFollowStatus(String targetUserId) async {
    if (_me.isEmpty) return FollowStatus.none;
    try {
      final res = await _supabase
          .from('follows')
          .select('status')
          .eq('follower_id', _me)
          .eq('following_id', targetUserId)
          .maybeSingle();
      if (res == null) return FollowStatus.none;
      return FollowUser._parseStatus(res['status'] as String?);
    } catch (e) {
      return FollowStatus.none;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 11. REALTIME: subscribe to incoming follow requests
  // ──────────────────────────────────────────────────────────────
  RealtimeChannel subscribeToIncomingRequests({
    required void Function() onAnyChange,
  }) {
    return _supabase
        .channel('incoming-follows-$_me')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'following_id',
            value: _me,
          ),
          callback: (_) => onAnyChange(),
        )
        .subscribe();
  }

  // ──────────────────────────────────────────────────────────────
  // 12. REALTIME: subscribe to profile changes (follower count updates)
  // ──────────────────────────────────────────────────────────────
  RealtimeChannel subscribeToProfile(
    String userId, {
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    return _supabase
        .channel('profile-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }
}
