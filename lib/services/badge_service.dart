import 'supabase_service.dart';

class BadgeService {
  static final _c = SupabaseService.client;

  static Future<void> award(String code) async {
    final b = await _c
        .from('badges')
        .select('id')
        .eq('code', code)
        .maybeSingle();
    if (b == null) return;
    await _c.from('user_badges').upsert({
      'badge_id': b['id'],
      'user_id': _c.auth.currentUser!.id,
    });
  }

  static Future<List<Map<String, dynamic>>> myBadges() => _c
      .from('user_badges')
      .select('*, badge:badges(*)')
      .eq('user_id', _c.auth.currentUser!.id);
}