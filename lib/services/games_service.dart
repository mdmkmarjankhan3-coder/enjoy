import 'badge_service.dart';
import 'supabase_service.dart';

class GamesService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<List<Map<String, dynamic>>> list(
          {String order = 'play_count'}) =>
      _c.from('games').select('*, creator:profiles!creator_id(name)').eq(
          'status', 'published').order(order, ascending: false);

  static Future<Map<String, dynamic>?> byId(String id) =>
      _c.from('games').select().eq('id', id).maybeSingle();

  static Future<Map<String, dynamic>?> builtin(String title) => _c
      .from('games')
      .select()
      .eq('is_builtin', true)
      .eq('title', title)
      .maybeSingle();

  static Future<void> recordSession(String gameId, int score, String result) async {
    await _c.from('game_sessions').insert({
      'game_id': gameId, 'user_id': _uid, 'score': score, 'result': result,
    });
    await _c.rpc('increment_play_count', params: {'p_id': gameId});
    if (result == 'win') await BadgeService.award('game_champion');
  }

  static Future<List<Map<String, dynamic>>> leaderboard(String gameId) => _c
      .from('game_sessions')
      .select('score, user:profiles!user_id(name, username)')
      .eq('game_id', gameId)
      .order('score', ascending: false)
      .limit(10);

  // ---- Game Creator ----
  static Future<List<Map<String, dynamic>>> myGames() => _c
      .from('games')
      .select()
      .eq('creator_id', _uid)
      .order('created_at', ascending: false);

  static Future<String> createGame({
    required String title,
    String description = '',
    String? coverUrl,
    String category = 'Casual',
    required Map<String, dynamic> config,
  }) async {
    final g = await _c.from('games').insert({
      'creator_id': _uid, 'title': title, 'description': description,
      'cover_url': coverUrl, 'category': category, 'config': config,
      'status': 'published',
    }).select('id').single();
    return g['id'] as String;
  }

  static Future<void> updateGame(String id,
      {String? title, String? description, Map<String, dynamic>? config}) async {
    final updates = <String, dynamic>{'version': await _nextVersion(id)};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (config != null) updates['config'] = config;
    await _c.from('games').update(updates).eq('id', id);
  }

  static Future<int> _nextVersion(String id) async {
    final g = await byId(id);
    return (g?['version'] ?? 1) + 1;
  }

  static Future<void> deleteGame(String id) =>
      _c.from('games').delete().eq('id', id).eq('creator_id', _uid);

  // ---- 1v1 Matches ----
  static Future<String> createMatch(String gameId) async {
    final m = await _c.from('game_matches').insert({
      'game_id': gameId, 'player1': _uid,
    }).select('id').single();
    return m['id'] as String;
  }

  static Future<List<Map<String, dynamic>>> waitingMatches(String gameId) => _c
      .from('game_matches')
      .select('*, p1:profiles!player1(name, username)')
      .eq('game_id', gameId)
      .eq('status', 'waiting')
      .neq('player1', _uid);

  static Future<void> joinMatch(String matchId) => _c
      .from('game_matches')
      .update({'player2': _uid, 'status': 'playing'})
      .eq('id', matchId);

  static Future<void> finishMatch(String matchId, String? winnerId) => _c
      .from('game_matches')
      .update({'status': 'finished', 'winner': winnerId})
      .eq('id', matchId);
}