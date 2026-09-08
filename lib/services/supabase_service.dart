import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Session আছে কি না — Splash-এ check হয়
  static bool get hasSession => client.auth.currentSession != null;

  /// Google Login (প্ল্যান সেকশন ৩)
  static Future<bool> signInWithGoogle() async {
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.redirectUrl,
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Profile তৈরি এখন DB trigger দিয়ে হয় (on_auth_user_created)
  /// এখানে শুধু নিশ্চিত হচ্ছি profile আছে কি না
  static Future<void> ensureProfileExists() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing == null) {
      await client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'] ?? 'ENJOY User',
        'username': 'user_${user.id.substring(0, 8)}',
        'avatar_url': user.userMetadata?['avatar_url'],
      });
    }
  }
}