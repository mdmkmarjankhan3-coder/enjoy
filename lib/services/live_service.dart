import 'package:supabase_flutter/supabase_flutter.dart';
import 'badge_service.dart';
import 'supabase_service.dart';

class LiveService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<String> createStream(String title, String? category) async {
    final s = await _c.from('live_streams').insert({
      'host_id': _uid, 'title': title, 'category': category,
    }).select('id').single();
    return s['id'] as String;
  }

  static Future<void> goLive(String id) =>
      _c.from('live_streams').update({'status': 'live'}).eq('id', id);

  static Future<void> endLive(String id, {String? videoUrl}) =>
      _c.from('live_streams').update({
        'status': 'ended',
        if (videoUrl != null) 'video_url': videoUrl,
      }).eq('id', id);

  static Future<List<Map<String, dynamic>>> streams(String status) => _c
      .from('live_streams')
      .select('*, host:profiles!host_id(name, username)')
      .eq('status', status)
      .order('created_at', ascending: false);

  static Future<Map<String, dynamic>?> byId(String id) =>
      _c.from('live_streams').select('*, host:profiles!host_id(name, username)')
          .eq('id', id).maybeSingle();

  static Future<void> like(String id) =>
      _c.rpc('increment_live_likes', params: {'p_id': id});

  static Future<void> join(String id) =>
      _c.from('live_viewers').upsert({'stream_id': id, 'user_id': _uid});

  static Future<void> leave(String id) =>
      _c.from('live_viewers').delete().eq('stream_id', id).eq('user_id', _uid);

  static Future<int> viewerCount(String id) async {
    final rows = await _c.from('live_viewers').select('user_id').eq('stream_id', id);
    return rows.length;
  }

  static Future<List<Map<String, dynamic>>> messages(String id) => _c
      .from('live_messages')
      .select('*, author:profiles!user_id(name, username)')
      .eq('stream_id', id)
      .order('created_at', ascending: false)
      .limit(100);

  static Future<void> sendMessage(String id, String content) =>
      _c.from('live_messages').insert({'stream_id': id, 'user_id': _uid, 'content': content});

  static Future<void> deleteMessage(int msgId) =>
      _c.from('live_messages').delete().eq('id', msgId);

  static RealtimeChannel subscribe(String id,
      {void Function(Map<String, dynamic>)? onMessage,
      void Function()? onAnyChange}) {
    var ch = _c.channel('live_$id');
    ch = ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'live_messages',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, column: 'stream_id', value: id),
      callback: (p) => onMessage?.call(p.newRecord),
    );
    if (onAnyChange != null) {
      ch = ch.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'live_streams',
        filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq, column: 'id', value: id),
        callback: (_) => onAnyChange(),
      );
    }
    return ch.subscribe();
  }

  static RealtimeChannel subscribeViewers(String id, void Function() onChange) {
    return _c
        .channel('live_viewers_$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_viewers',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'stream_id', value: id),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static Future<void> awardHostBadge() => BadgeService.award('live_star');
}