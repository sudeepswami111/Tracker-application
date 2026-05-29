import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_reply.dart';
import '../models/community_reaction.dart';

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
      debugPrint('Error getting posts: $e');
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

  // ====================================================
  // REPLIES
  // ====================================================

  Future<List<CommunityReply>> fetchRepliesForPost(String postId) async {
    try {
      final response = await _client
          .from('community_replies')
          .select('*, author:profiles!community_replies_user_id_fkey(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((r) => CommunityReply.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error fetching replies: $e');
      return [];
    }
  }

  Future<CommunityReply?> addReply(String postId, String replyText, {String? postAuthorId}) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;

      final response = await _client.from('community_replies').insert({
        'post_id': postId,
        'user_id': uid,
        'reply_text': replyText,
      }).select('*, author:profiles!community_replies_user_id_fkey(full_name, avatar_url)').single();

      // Notify post author
      if (postAuthorId != null && uid != postAuthorId) {
        await _client.from('notifications').insert({
          'user_id': postAuthorId,
          'actor_id': uid,
          'type': 'post_reply',
          'title': 'Someone replied to your post 💬',
          'body': 'Check out what they said',
          'reference_id': postId,
          'is_read': false,
        });
      }

      return CommunityReply.fromJson(response);
    } catch (e) {
      debugPrint('Error adding reply: $e');
      return null;
    }
  }

  Future<void> deleteReply(String replyId) async {
    try {
      await _client.from('community_replies').delete().eq('id', replyId);
    } catch (e) {
      debugPrint('Error deleting reply: $e');
      rethrow;
    }
  }

  // ====================================================
  // REACTIONS (Cheer & Fire)
  // ====================================================

  Future<ReactionSummary> fetchReactionSummary(String postId) async {
    try {
      final response = await _client
          .from('community_reactions')
          .select('reaction_type, user_id')
          .eq('post_id', postId);

      return ReactionSummary.fromReactions(
        response as List<dynamic>,
        _client.auth.currentUser?.id,
      );
    } catch (e) {
      debugPrint('Error fetching reaction summary: $e');
      return const ReactionSummary();
    }
  }

  Future<void> toggleReaction(String postId, String reactionType, {String? postAuthorId}) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      // Check if reaction already exists
      final existing = await _client
          .from('community_reactions')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', uid)
          .eq('reaction_type', reactionType)
          .maybeSingle();

      if (existing != null) {
        // Delete reaction
        await _client.from('community_reactions').delete().eq('id', existing['id']);
      } else {
        // Add reaction
        await _client.from('community_reactions').insert({
          'post_id': postId,
          'user_id': uid,
          'reaction_type': reactionType,
        });

        // Notify post author
        if (postAuthorId != null && uid != postAuthorId) {
          final emoji = reactionType == 'cheer' ? '👏' : '🔥';
          final action = reactionType == 'cheer' ? 'cheered for' : 'reacted with fire to';
          
          await _client.from('notifications').insert({
            'user_id': postAuthorId,
            'actor_id': uid,
            'type': 'post_reaction',
            'title': 'Someone $action your post $emoji',
            'body': 'Check out the reactions on your post',
            'reference_id': postId,
            'is_read': false,
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      rethrow;
    }
  }

  // Keep legacy likePost just in case other parts of the app rely on it temporarily
  Future<void> likePost(String postId, {String? postAuthorId}) async {
    try {
      await _client.rpc('increment_likes', params: {'post_id': postId});

      final uid = _client.auth.currentUser?.id;
      if (uid == null || postAuthorId == null || uid == postAuthorId) return;

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
