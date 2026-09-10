import 'supabase_service.dart';

class AdsService {
  static final _c = SupabaseService.client;
  static String? get _uid => _c.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> activeCampaigns() => _c
      .from('ads_campaigns').select()
      .eq('active', true)
      .order('created_at', ascending: false).limit(10);

  static Future<Map<String, dynamic>?> nextAd() async {
    final ads = await activeCampaigns();
    if (ads.isEmpty) return null;
    return ads.first;
  }

  static Future<void> record(int campaignId, String event) =>
      _c.from('ad_events').insert({
        'campaign_id': campaignId,
        'user_id': _uid,
        'event': event,
      });
}