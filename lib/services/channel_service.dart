import 'supabase_service.dart';

class ChannelService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<Map<String, dynamic>?> myChannel() => _c
      .from('channels')
      .select()
      .eq('owner_id', _uid)
      .maybeSingle();

  static Future<String> create({
    required String name, required String username,
    String description = '', String? category, String privacy = 'public',
  }) async {
    final row = await _c.from('channels').insert({
      'owner_id': _uid, 'name': name, 'username': username,
      'description': description, 'category': category, 'privacy': privacy,
    }).select('id').single();
    return row['id'] as String;
  }

  static Future<Map<String, dynamic>?> byId(String id) =>
      _c.from('channels').select().eq('id', id).maybeSingle();

  static Future<List<Map<String, dynamic>>> channelVideos(String channelId) => _c
      .from('videos')
      .select('*, likes:video_likes(count), views:video_views(count)')
      .eq('channel_id', channelId)
      .eq('status', 'published')
      .order('created_at', ascending: false);
}