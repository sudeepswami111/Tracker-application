import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';
  String get currentUserName => _supabase.auth.currentUser?.email?.split('@')[0] ?? 'User';

  // Fetch all channels the user has access to
  Stream<List<Map<String, dynamic>>> getChannelsStream() {
    return _supabase
        .from('channels')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Stream messages for a specific channel in real-time
  Stream<List<Map<String, dynamic>>> getMessagesStream(String channelId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: true);
  }

  // Send a new message
  Future<void> sendMessage(String channelId, String content, {String? senderNameOverride}) async {
    if (content.trim().isEmpty) return;
    await _supabase.from('messages').insert({
      'channel_id': channelId,
      'sender_id': currentUserId,
      'sender_name': senderNameOverride ?? currentUserName,
      'content': content.trim(),
    });
  }

  // Helper: Create a private 1-on-1 coaching chat
  Future<String> createPrivateChannel(String coachName, String coachId) async {
    // Check if channel already exists
    final response = await _supabase
        .from('channels')
        .select()
        .eq('is_private', true)
        .contains('member_ids', [currentUserId, coachId]);

    if (response.isNotEmpty) {
      return response.first['id'] as String;
    }

    // Create a new channel if it doesn't exist
    final newChannel = await _supabase.from('channels').insert({
      'name': coachName,
      'is_private': true,
      'member_ids': [currentUserId, coachId],
    }).select().single();

    return newChannel['id'] as String;
  }
}
