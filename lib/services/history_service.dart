import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getHistory() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      // Fetch runs
      final runsResponse = await _client
          .from('running_activities')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
          
      final runs = (runsResponse as List).map((r) => {
            ...r as Map<String, dynamic>,
            '_source': 'run',
          }).toList();

      // We could add fetch from study_sessions here later, 
      // but the schema may not exist on Supabase right now.
      // For now, we'll just return runs as the primary activity.
      
      final List<Map<String, dynamic>> allActivities = [...runs];
      
      // Sort combined by created_at descending
      allActivities.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      return allActivities;
    } catch (e) {
      return [];
    }
  }
}
