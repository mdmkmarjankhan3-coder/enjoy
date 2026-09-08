import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/channel_service.dart';

class CreateChannelPage extends StatefulWidget {
  const CreateChannelPage({super.key});

  @override
  State<CreateChannelPage> createState() => _CreateChannelPageState();
}

class _CreateChannelPageState extends State<CreateChannelPage> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _desc = TextEditingController();
  String _privacy = 'public';
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final id = await ChannelService.create(
        name: _name.text.trim(),
        username: _username.text.trim(),
        description: _desc.text,
        privacy: _privacy,
      );
      if (mounted) {
        context.go('/channel/$id');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📺 Create Channel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Channel Name *'),
          ),
          TextField(
            controller: _username,
            decoration: const InputDecoration(labelText: '@Username *'),
          ),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _privacy,
            decoration: const InputDecoration(labelText: 'Privacy'),
            items: const ['public', 'private']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _privacy = v!),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: Text(_busy ? 'তৈরি হচ্ছে…' : 'Create Channel'),
          ),
        ],
      ),
    );
  }
}