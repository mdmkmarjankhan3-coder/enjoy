import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<String> openDirectChat(String otherId) async {
    final mine = await _c
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', _uid);

    for (final r in mine) {
      final conv = await _c
          .from('conversations')
          .select('id')
          .eq('id', r['conversation_id'])
          .eq('type', 'direct')
          .maybeSingle();

      if (conv == null) continue;

      final other = await _c
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conv['id'])
          .eq('user_id', otherId)
          .maybeSingle();

      if (other != null) return conv['id'];
    }

    final newConv = await _c
        .from('conversations')
        .insert({'type': 'direct', 'created_by': _uid})
        .select('id')
        .single();

    final id = newConv['id'] as String;

    await _c.from('conversation_members').insert([
      {
        'conversation_id': id,
        'user_id': _uid,
        'role': 'admin',
      },
      {
        'conversation_id': id,
        'user_id': otherId,
      },
    ]);

    return id;
  }

  static Future<String> createGroup({
    required String name,
    String description = '',
    bool isPublic = false,
    required List<String> memberIds,
  }) async {
    final conv = await _c
        .from('conversations')
        .insert({
          'type': 'group',
          'name': name,
          'description': description,
          'is_public': isPublic,
          'created_by': _uid,
        })
        .select('id')
        .single();

    final id = conv['id'] as String;

    await _c.from('conversation_members').insert([
      {
        'conversation_id': id,
        'user_id': _uid,
        'role': 'admin',
      },
      for (final m in memberIds)
        {
          'conversation_id': id,
          'user_id': m,
          'role': 'member',
        },
    ]);

    return id;
  }

  static Future<List<Map<String, dynamic>>> myConversations() async {
    final rows = await _c
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', _uid);

    final ids = [
      for (final r in rows) r['conversation_id'] as String,
    ];

    if (ids.isEmpty) return [];

    return _c
        .from('conversations')
        .select(
          '*, members:conversation_members(user_id, role, '
          'profile:profiles!user_id(name, username, avatar_url))',
        )
        .inFilter('id', ids)
        .order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> messages(
    String convId,
  ) =>
      _c
          .from('messages')
          .select(
            '*, sender:profiles!sender_id(name, username, avatar_url)',
          )
          .eq('conversation_id', convId)
          .order('created_at', ascending: false)
          .limit(100);

  static Future<void> sendMessage(
    String convId, {
    String type = 'text',
    String content = '',
    String? mediaUrl,
    int? replyTo,
  }) =>
      _c.from('messages').insert({
        'conversation_id': convId,
        'sender_id': _uid,
        'type': type,
        'content': content,
        'media_url': mediaUrl,
        'reply_to_id': replyTo,
      });

  static Future<void> togglePin(
    int messageId,
    bool pinned,
  ) =>
      _c
          .from('messages')
          .update({'is_pinned': pinned})
          .eq('id', messageId);

  static Future<void> deleteMessage(int messageId) =>
      _c.from('messages').delete().eq('id', messageId);

  static Future<void> markRead(String convId) =>
      _c.from('conversation_reads').upsert({
        'conversation_id': convId,
        'user_id': _uid,
        'last_read_at': DateTime.now().toIso8601String(),
      });

  static Future<DateTime?> otherLastRead(
    String convId,
    String otherId,
  ) async {
    final r = await _c
        .from('conversation_reads')
        .select('last_read_at')
        .eq('conversation_id', convId)
        .eq('user_id', otherId)
        .maybeSingle();

    return r == null ? null : DateTime.parse(r['last_read_at']);
  }

  static RealtimeChannel subscribeMessages(
    String convId,
    void Function(Map<String, dynamic>) onNew,
  ) {
    return _c
        .channel('msg_$convId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: convId,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }

  static void sendTyping(String convId) {
    _c
        .channel('typing_$convId')
        .sendBroadcastMessage(
          event: 'typing',
          payload: {'user_id': _uid},
        );
  }

  static RealtimeChannel onTyping(
    String convId,
    void Function(String) onTyping,
  ) {
    return _c
        .channel('typing_$convId')
        .onBroadcast(
          event: 'typing',
          callback: (msg) =>
              onTyping((msg as Map)['user_id'] as String),
        )
        .subscribe();
  }

  /// Presence channel
  static RealtimeChannel presenceChannel(
    void Function(Set<String>) onChange,
  ) {
    final ch = _c.channel('online_presence');

    ch.onPresenceSync((state) {
      final online = <String>{};

      for (final presenceState in ch.presenceState()) {
        for (final presence in presenceState.presences) {
          final userId = presence.payload['user_id'];

          if (userId != null) {
            online.add(userId as String);
          }
        }
      }

      onChange(online);
    }).subscribe();

    ch.track({'user_id': _uid});

    return ch;
  }

  static Future<List<Map<String, dynamic>>> groupPosts(
    String groupId,
  ) =>
      _c
          .from('group_posts')
          .select(
            '*, author:profiles!user_id(name, username, avatar_url)',
          )
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

  static Future<void> addGroupPost(
    String groupId,
    String content,
  ) =>
      _c.from('group_posts').insert({
        'group_id': groupId,
        'user_id': _uid,
        'content': content,
      });
}