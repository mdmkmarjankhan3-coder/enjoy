import 'supabase_service.dart';

class ModerationService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<void> block(String userId) =>
      _c.from('blocked_users').upsert({'user_id': _uid, 'blocked_id': userId});

  static Future<void> unblock(String userId) => _c
      .from('blocked_users').delete().eq('user_id', _uid).eq('blocked_id', userId);

  static Future<List<Map<String, dynamic>>> blockedList() => _c
      .from('blocked_users')
      .select('blocked_id, profile:profiles!blocked_id(name, username, avatar_url)')
      .eq('user_id', _uid);

  static Future<bool> isBlocked(String userId) async {
    final r = await _c.from('blocked_users').select('blocked_id')
        .eq('user_id', _uid).eq('blocked_id', userId).maybeSingle();
    return r != null;
  }

  static Future<void> report(
      String targetType, String targetId, String reason) =>
      _c.from('reports').insert({
        'reporter_id': _uid,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
      });
}