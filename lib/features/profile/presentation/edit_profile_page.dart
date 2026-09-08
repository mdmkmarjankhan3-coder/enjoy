import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/media_picker.dart';
import '../../../services/supabase_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _c = SupabaseService.client;
  late final _name = TextEditingController();
  late final _username = TextEditingController();
  late final _bio = TextEditingController();
  late final _website = TextEditingController();
  String? _avatarUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _c.from('profiles').select()
        .eq('id', _c.auth.currentUser!.id).single();
    _name.text = p['name'] ?? '';
    _username.text = p['username'] ?? '';
    _bio.text = p['bio'] ?? '';
    _website.text = p['website'] ?? '';
    _avatarUrl = p['avatar_url'];
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await _c.from('profiles').update({
        'name': _name.text.trim(),
        'username': _username.text.trim(),
        'bio': _bio.text,
        'website': _website.text,
        'avatar_url': _avatarUrl,
      }).eq('id', _c.auth.currentUser!.id);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAvatar() async {
    final img = await MediaPicker.pickImage();
    if (img == null) return;
    final res = await CloudinaryService.uploadImage(img.bytes, img.name);
    setState(() => _avatarUrl = res['url']);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('✏️ Edit Profile')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.add_a_photo) : null,
              ),
            ),
          ),
          TextField(controller: _name,
              decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _username,
              decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: _bio,
              decoration: const InputDecoration(labelText: 'Bio')),
          TextField(controller: _website,
              decoration: const InputDecoration(labelText: 'Website')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Save')),
        ]),
      );
}