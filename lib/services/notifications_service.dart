import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class NotificationsService {
  static final _c = SupabaseService.client;
  static String? get _uid => _c.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> fetch() => _c
      .from('notifications')
      .select('*, actor:profiles!actor_id(name, username, avatar_url)')
      .eq('user_id', _uid!)
      .order('created_at', ascending: false)
      .limit(50);

  static Future<int> unreadCount() async {
    final rows = await _c
        .from('notifications')
        .select('id')
        .eq('user_id', _uid!)
        .eq('is_read', false);
    return rows.length;
  }

  static Future<void> markAllRead() => _c
      .from('notifications')
      .update({'is_read': true})
      .eq('user_id', _uid!)
      .eq('is_read', false);

  static RealtimeChannel subscribe(void Function() onNew) {
    return _c
        .channel('notif_$_uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _uid!,
          ),
          callback: (_) => onNew(),
        )
        .subscribe();
  }
}