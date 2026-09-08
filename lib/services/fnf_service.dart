import 'supabase_service.dart';

class FnfService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<List<Map<String, dynamic>>> searchUsers(String query) => _c
      .from('profiles')
      .select('id, name, username, avatar_url')
      .or('name.ilike.%$query%,username.ilike.%$query%')
      .neq('id', _uid)
      .limit(20);

  static Future<void> sendRequest(String receiverId) =>
      _c.from('friend_requests').insert({'sender_id': _uid, 'receiver_id': receiverId});

  static Future<List<Map<String, dynamic>>> pendingRequests() => _c
      .from('friend_requests')
      .select('*, sender:profiles!sender_id(id, name, username, avatar_url)')
      .eq('receiver_id', _uid)
      .eq('status', 'pending')
      .order('created_at', ascending: false);

  static Future<void> acceptRequest(Map<String, dynamic> req) async {
    final senderId = req['sender_id'] as String;
    await _c.from('friend_requests').update({'status': 'accepted'}).eq('id', req['id']);
    await _c.from('friendships').insert([
      {'user_id': _uid, 'friend_id': senderId},
      {'user_id': senderId, 'friend_id': _uid},
    ]);
  }

  static Future<void> rejectRequest(int id) =>
      _c.from('friend_requests').update({'status': 'rejected'}).eq('id', id);

  static Future<List<Map<String, dynamic>>> myFriends() => _c
      .from('friendships')
      .select('friend:profiles!friend_id(id, name, username, avatar_url)')
      .eq('user_id', _uid)
      .order('created_at', ascending: false);
}