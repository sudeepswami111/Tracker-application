import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPosts({String? filter}) async {
    try {
      var query = _client
          .from('community_posts')
          .select('*, author:profiles!community_posts_user_id_fkey(id, full_name, avatar_url)');

      if (filter != null && filter != 'All') {
        query = query.eq('activity_type', filter);
      }

      final data = await query.order('created_at', ascending: false).limit(30);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> createPost(String content, String activityType, {String? imageUrl}) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      
      await _client.from('community_posts').insert({
        'user_id': uid,
        'content': content,
        'activity_type': activityType,
        if (imageUrl != null) 'image_url': imageUrl,
      });
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  /// Like a post and notify the post author (not for self-likes).
  /// Pass [postAuthorId] to enable the notification; falls back to
  /// the plain RPC-only path if [postAuthorId] is null.
  Future<void> likePost(String postId, {String? postAuthorId}) async {
    try {
      await _client.rpc('increment_likes', params: {'post_id': postId});

      final uid = _client.auth.currentUser?.id;
      if (uid == null || postAuthorId == null || uid == postAuthorId) return;

      // Notify the post author
      await _client.from('notifications').insert({
        'user_id': postAuthorId,
        'actor_id': uid,
        'type': 'post_like',
        'title': 'Someone liked your post ❤️',
        'body': 'Check out the reactions on your post',
        'reference_id': postId,
        'is_read': false,
      });
    } catch (e) {
      // Ignored for now
    }
  }
}
