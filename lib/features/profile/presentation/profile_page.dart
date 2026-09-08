import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/channel_service.dart';
import '../../../services/supabase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _channel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    final p = await SupabaseService.client
        .from('profiles').select().eq('id', user.id).maybeSingle();
    final c = await ChannelService.myChannel();
    if (mounted) setState(() { _profile = p; _channel = c; });
  }

  Future<void> _logout() async {
    await SupabaseService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('👤 Profile'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
      ]),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundImage: p['avatar_url'] != null
                    ? NetworkImage(p['avatar_url']) : null,
                child: p['avatar_url'] == null
                    ? const Icon(Icons.person, size: 48) : null,
              ),
              const SizedBox(height: 16),
              Center(child: Text(p['name'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge)),
              Center(child: Text('@${p['username'] ?? ''}')),
              if (p['bio'] != null) Center(child: Text(p['bio'])),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                FilledButton.tonal(onPressed: () => context.push('/profile/edit'),
                    child: const Text('✏️ Edit Profile')),
                FilledButton.tonal(
                  onPressed: () => _channel == null
                      ? context.push('/channel/create')
                      : context.push('/channel/${_channel!['id']}'),
                  child: Text(_channel == null ? '📺 Create Channel' : '📺 My Channel'),
                ),
              ]),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.dashboard_customize),
                title: const Text('🎨 Creator Studio'),
                onTap: () => context.push('/creator-studio'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('⚙️ Settings'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings — পরের Phase'))),
              ),
            ]),
    );
  }
}