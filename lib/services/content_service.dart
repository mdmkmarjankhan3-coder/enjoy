import 'supabase_service.dart';

class ContentService {
  final String base; // 'video' অথবা 'short'
  ContentService(this.base);

  final _c = SupabaseService.client;
  String get _uid => _c.auth.currentUser!.id;

  String get _table => '${base}s'; // videos / shorts
  String get _idCol => '${base}_id'; // video_id / short_id

  // প্ল্যান ৫: Unified Content Actions-এর জন্য
  static final videos = ContentService('video');
  static final shorts = ContentService('short');

  Future<List<Map<String, dynamic>>> feed({int limit = 50}) => _c
      .from(_table)
      .select('*, author:profiles!user_id(name, username, avatar_url), '
          'likes:${base}_likes(count), views:${base}_views(count), '
          'comment_list:${base}_comments(count)')
      .eq('privacy', 'public')
      .eq('status', 'published')
      .order('created_at', ascending: false)
      .limit(limit);

  Future<List<Map<String, dynamic>>> mine() => _c
      .from(_table)
      .select('*, likes:${base}_likes(count), views:${base}_views(count)')
      .eq('user_id', _uid)
      .order('created_at', ascending: false);

  Future<Map<String, dynamic>?> byId(String id) => _c
      .from(_table)
      .select('*, author:profiles!user_id(name, username, avatar_url), '
          'likes:${base}_likes(count), views:${base}_views(count)')
      .eq('id', id)
      .maybeSingle();

  Future<Set<String>> myActionIds(String action /* likes/saves */) async {
    final rows =
        await _c.from('${base}_$action').select(_idCol).eq('user_id', _uid);
    return {for (final r in rows) r[_idCol] as String};
  }

  Future<void> toggleAction(String id, String action, bool active) => active
      ? _c.from('${base}_$action').delete().eq(_idCol, id).eq('user_id', _uid)
      : _c.from('${base}_$action').insert({_idCol: id, 'user_id': _uid});

  Future<void> recordView(String id) =>
      _c.from('${base}_views').upsert({_idCol: id, 'user_id': _uid});

  Future<List<Map<String, dynamic>>> comments(String id) => _c
      .from('${base}_comments')
      .select('*, author:profiles!user_id(name, username, avatar_url)')
      .eq(_idCol, id)
      .order('created_at', ascending: false);

  Future<void> addComment(String id, String text) =>
      _c.from('${base}_comments').insert({_idCol: id, 'user_id': _uid, 'content': text});

  Future<String> publish({
    required String title,
    String description = '',
    String? category,
    List<String> tags = const [],
    String privacy = 'public',
    String status = 'published',
    required String videoUrl,
    String? publicId,
    String? thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final row = await _c.from(_table).insert({
      'user_id': _uid,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'public_id': publicId,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'tags': tags,
      'privacy': privacy,
      'status': status,
      'duration_seconds': durationSeconds,
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> remove(String id) =>
      _c.from(_table).delete().eq('id', id).eq('user_id', _uid);
}