import 'supabase_service.dart';

class RewardsService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static const actions = {
    'login': 5, 'watch': 2, 'like': 1, 'comment': 2, 'share': 3,
    'upload': 20, 'game_win': 15, 'lesson_complete': 10, 'live_host': 25,
  };

  static Future<void> log(String action) =>
      _c.rpc('add_points', params: {'p_user': _uid, 'p_action': action});

  static Future<Map<String, dynamic>> stats() async {
    final s = await _c.from('user_stats').select()
        .eq('user_id', _uid).maybeSingle();
    return s ?? {'points': 0, 'level': 1};
  }

  static Future<List<Map<String, dynamic>>> activityLog() => _c
      .from('activities').select()
      .eq('user_id', _uid)
      .order('created_at', ascending: false).limit(50);

  static Future<List<Map<String, dynamic>>> leaderboard() => _c
      .from('user_stats')
      .select('points, level, user:profiles!user_id(name, username, avatar_url)')
      .order('points', ascending: false).limit(20);
}