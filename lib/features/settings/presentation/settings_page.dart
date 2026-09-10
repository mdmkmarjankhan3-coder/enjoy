import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = <String, bool>{
    'chat_read': true, 'chat_typing': true, 'notif_fnf': true,
    'notif_like': true, 'notif_comment': true, 'notif_live': true,
    'privacy_profile': false, 'privacy_activity': false,
    'ai_memory': true, 'auto_download_wifi': false,
  };
  String _language = 'বাংলা';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      for (final k in _prefs.keys) {
        _prefs[k] = p.getBool(k) ?? _prefs[k]!;
      }
      _language = p.getString('language') ?? 'বাংলা';
    });
  }

  Future<void> _set(String key, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
    setState(() => _prefs[key] = v);
    if (key == 'ai_memory' && !v) {
      // AI Memory off — session-এ মেমরি পরিষ্কার
    }
  }

  Future<void> _setLanguage(String l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('language', l);
    setState(() => _language = l);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('⚙️ Settings')),
        body: ListView(children: [
          const _Header('👤 Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => context.push('/profile/edit'),
          ),
          const _Header('💬 Chat'),
          SwitchListTile(
            secondary: const Icon(Icons.done_all),
            title: const Text('Read receipts'),
            value: _prefs['chat_read']!,
            onChanged: (v) => _set('chat_read', v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.edit),
            title: const Text('Typing status'),
            value: _prefs['chat_typing']!,
            onChanged: (v) => _set('chat_typing', v),
          ),
          const _Header('🔔 Notifications'),
          for (final e in const {
            'notif_fnf': 'FNF requests', 'notif_like': 'Likes',
            'notif_comment': 'Comments', 'notif_live': 'Live',
          }.entries)
            SwitchListTile(
              title: Text(e.value),
              value: _prefs[e.key]!,
              onChanged: (v) => _set(e.key, v),
            ),
          const _Header('🔐 Privacy & Security'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Private profile'),
            value: _prefs['privacy_profile']!,
            onChanged: (v) => _set('privacy_profile', v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('Hide my activity'),
            value: _prefs['privacy_activity']!,
            onChanged: (v) => _set('privacy_activity', v),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked users'),
            onTap: () => context.push('/blocked'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Security alerts'),
            subtitle: const Text('Google Auth + Supabase RLS সক্রিয়'),
          ),
          const _Header('🤖 AI'),
          SwitchListTile(
            secondary: const Icon(Icons.smart_toy),
            title: const Text('AI Memory'),
            subtitle: const Text('আপনার অনুমতিতে context মনে রাখবে'),
            value: _prefs['ai_memory']!,
            onChanged: (v) => _set('ai_memory', v),
          ),
          const _Header('📥 Downloads'),
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('Auto-download (Wi-Fi)'),
            value: _prefs['auto_download_wifi']!,
            onChanged: (v) => _set('auto_download_wifi', v),
          ),
          const _Header('🌐 Language'),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(_language),
            onTap: () async {
              final l = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(title: const Text('Language'), children: [
                  for (final lang in ['বাংলা', 'English'])
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, lang),
                      child: Text(lang),
                    ),
                ]),
              );
              if (l != null) _setLanguage(l);
            },
          ),
          const _Header('🎨 Appearance'),
          for (final e in const [
            ('System', ThemeMode.system, Icons.brightness_auto),
            ('Light', ThemeMode.light, Icons.light_mode),
            ('Dark', ThemeMode.dark, Icons.dark_mode),
          ])
            RadioListTile<ThemeMode>(
              secondary: Icon(e.$3),
              title: Text(e.$1),
              value: e.$2,
              groupValue: ThemeController.mode.value,
              onChanged: (v) {
                if (v != null) {
                  ThemeController.mode.value = v;
                  setState(() {});
                }
              },
            ),
          const _Header('❓ Help'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Recovery'),
            onTap: () => context.push('/help'),
          ),
          const SizedBox(height: 24),
        ]),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )),
      );
}