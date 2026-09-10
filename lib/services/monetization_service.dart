import 'supabase_service.dart';

class MonetizationService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  // ⚙️ Admin/Business rules — পরে এখান থেকেই পরিবর্তনযোগ্য (প্ল্যান ২৫)
  static const minAccountAgeDays = 7;
  static const minFnf = 3;
  static const minViews = 50;
  static const minPublishedContent = 2;
  static const maxReports = 0;

  static Future<Map<String, dynamic>> eligibility() async {
    final user = _c.auth.currentUser!;
    final accountAgeDays =
        DateTime.now().difference(DateTime.parse(user.createdAt)).inDays;

    final fnf = await _c.from('friendships').select('friend_id').eq('user_id', _uid);
    final videos = await _c.from('videos').select('id, views:video_views(count)')
        .eq('user_id', _uid).eq('status', 'published');
    final shorts = await _c.from('shorts').select('id, views:short_views(count)')
        .eq('user_id', _uid).eq('status', 'published');
    final reports = await _c.from('reports').select('id')
        .eq('target_id', _uid);

    int views(Map<String, dynamic> v) =>
        ((v['views'] as List?)?.first as Map?)?['count'] ?? 0;
    final totalViews =
        videos.fold<int>(0, (a, v) => a + views(v)) +
        shorts.fold<int>(0, (a, v) => a + views(v));
    final published = videos.length + shorts.length;

    final checks = {
      'Complete & Active Account': true,
      'Account Age ≥ $minAccountAgeDays days': accountAgeDays >= minAccountAgeDays,
      'FNF ≥ $minFnf': fnf.length >= minFnf,
      'Valid Views ≥ $minViews': totalViews >= minViews,
      'Published Content ≥ $minPublishedContent': published >= minPublishedContent,
      'No Serious Violations': reports.length <= maxReports,
    };
    return {
      'checks': checks,
      'meets': checks.values.every((v) => v),
      'accountAgeDays': accountAgeDays,
      'fnf': fnf.length,
      'views': totalViews,
      'published': published,
    };
  }

  static Future<Map<String, dynamic>?> status() async {
    final rows = await _c.from('monetization_applications').select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false).limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> apply(String? channelId) =>
      _c.from('monetization_applications').insert({
        'user_id': _uid, 'channel_id': channelId,
      });

  static Future<List<Map<String, dynamic>>> earnings() => _c
      .from('earnings').select()
      .eq('user_id', _uid)
      .order('created_at', ascending: false).limit(100);

  static Future<double> availableBalance() async {
    final rows = await _c.from('earnings').select('amount')
        .eq('user_id', _uid).eq('status', 'available');
    return rows.fold<double>(
        0, (a, r) => a + (double.tryParse('${r['amount']}') ?? 0));
  }
}