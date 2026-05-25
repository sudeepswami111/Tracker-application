import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeService {
  final _client = Supabase.instance.client;

  // Load user's active challenges (joined + not completed)
  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return [];
      final data = await _client
          .from('challenge_participants')
          .select('current_value, rank, joined_at, challenge:challenges(*)')
          .eq('user_id', uid)
          .isFilter('completed_at', null)
          .order('joined_at', ascending: false);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Load completed challenges for the current user
  Future<List<Map<String, dynamic>>> getCompletedChallenges() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return [];
      final data = await _client
          .from('challenge_participants')
          .select('rank, completed_at, challenge:challenges(*)')
          .eq('user_id', uid)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Load discover challenges (public, user hasn't joined)
  Future<Map<String, List<Map<String, dynamic>>>> getDiscoverChallenges() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return {};

      final joined = await _client
          .from('challenge_participants')
          .select('challenge_id')
          .eq('user_id', uid);
      final joinedIds = (joined as List).map((e) => e['challenge_id'] as String).toList();

      List<Map<String, dynamic>> data;
      if (joinedIds.isNotEmpty) {
        data = List<Map<String, dynamic>>.from(
          await _client
              .from('challenges')
              .select()
              .eq('is_public', true)
              .not('id', 'in', '(${joinedIds.map((id) => '"$id"').join(',')})')
              .order('participants_count', ascending: false),
        );
      } else {
        data = List<Map<String, dynamic>>.from(
          await _client
              .from('challenges')
              .select()
              .eq('is_public', true)
              .order('participants_count', ascending: false),
        );
      }

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final c in data) {
        final cat = (c['category'] as String?) ?? 'Other';
        grouped.putIfAbsent(cat, () => []).add(c);
      }
      return grouped;
    } catch (e) {
      return {};
    }
  }

  // Join a challenge
  Future<void> joinChallenge(String challengeId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      await _client.from('challenge_participants').insert({
        'challenge_id': challengeId,
        'user_id': uid,
        'current_value': 0,
      });
      await _client.rpc('increment_participants', params: {'cid': challengeId});
    } catch (_) {}
  }

  // Create a new challenge and auto-join as creator
  Future<String?> createChallenge(Map<String, dynamic> data) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;
      final result = await _client.from('challenges').insert({
        ...data,
        'created_by': uid,
        'is_public': false,
      }).select('id').single();
      final id = result['id'] as String;
      await joinChallenge(id);
      return id;
    } catch (e) {
      return null;
    }
  }

  // Update progress for a challenge
  Future<void> updateProgress(String challengeId, double newValue) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      // Check if challenge is complete
      final challenge = await _client
          .from('challenges')
          .select('target_value, title')
          .eq('id', challengeId)
          .single();
      final target = (challenge['target_value'] as num).toDouble();
      final Map<String, dynamic> updateData = {'current_value': newValue};
      final bool justCompleted = newValue >= target;
      if (justCompleted) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _client
          .from('challenge_participants')
          .update(updateData)
          .eq('challenge_id', challengeId)
          .eq('user_id', uid);

      // Insert challenge_complete notification when target reached
      if (justCompleted) {
        try {
          await _client.from('notifications').insert({
            'user_id': uid,
            'type': 'challenge_complete',
            'title': 'Challenge Completed! 🏆',
            'body': 'You completed "${challenge['title']}" — check your rank!',
            'reference_id': challengeId,
            'is_read': false,
          });
        } catch (_) {}
      }
    } catch (_) {}
  }


  // Fetch leaderboard for a challenge
  Future<List<Map<String, dynamic>>> getLeaderboard(String challengeId) async {
    try {
      final data = await _client
          .from('challenge_participants')
          .select('current_value, rank, user:profiles!challenge_participants_user_id_fkey(id, full_name, avatar_url)')
          .eq('challenge_id', challengeId)
          .order('current_value', ascending: false)
          .limit(20);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Helper: Update all Distance challenges after a run
  Future<void> updateDistanceChallengesAfterRun(double distanceKm) async {
    try {
      final active = await getActiveChallenges();
      for (final cp in active) {
        final challenge = cp['challenge'] as Map<String, dynamic>? ?? {};
        if (challenge['goal_type'] == 'Distance') {
          final currentVal = (cp['current_value'] as num).toDouble();
          await updateProgress(challenge['id'] as String, currentVal + distanceKm);
        }
      }
    } catch (_) {}
  }

  // Helper: Update all Steps challenges
  Future<void> updateStepsChallenges(int steps) async {
    try {
      final active = await getActiveChallenges();
      for (final cp in active) {
        final challenge = cp['challenge'] as Map<String, dynamic>? ?? {};
        if (challenge['goal_type'] == 'Steps') {
          await updateProgress(challenge['id'] as String, steps.toDouble());
        }
      }
    } catch (_) {}
  }

  // Helper: Update all Study challenges
  Future<void> updateStudyChallenges(double studyHrs) async {
    try {
      final active = await getActiveChallenges();
      for (final cp in active) {
        final challenge = cp['challenge'] as Map<String, dynamic>? ?? {};
        if (challenge['goal_type'] == 'Study') {
          await updateProgress(challenge['id'] as String, studyHrs);
        }
      }
    } catch (_) {}
  }
}
