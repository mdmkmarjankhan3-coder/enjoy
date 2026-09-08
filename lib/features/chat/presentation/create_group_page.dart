import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/chat_service.dart';
import '../../../services/fnf_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});
  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _isPublic = false;
  final Set<String> _selected = {};
  bool _busy = false;

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final id = await ChatService.createGroup(
        name: _name.text.trim(),
        description: _desc.text,
        isPublic: _isPublic,
        memberIds: _selected.toList(),
      );
      if (mounted) {
        context.go('/chat/$id', extra: {
          'title': _name.text.trim(), 'isGroup': true, 'other': null,
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('👥 Create Group')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Group Name *')),
              TextField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Description')),
              SwitchListTile(
                title: const Text('Public Group'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
            ]),
          ),
          const ListTile(title: Text('FNF থেকে members বাছুন')),
          Expanded(
            child: FutureBuilder(
              future: FnfService.myFriends(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final f = snap.data![i]['friend'] as Map<String, dynamic>;
                    final id = f['id'] as String;
                    return CheckboxListTile(
                      value: _selected.contains(id),
                      onChanged: (v) => setState(() =>
                          v == true ? _selected.add(id) : _selected.remove(id)),
                      title: Text(f['name'] ?? ''),
                      subtitle: Text('@${f['username'] ?? ''}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: _busy ? null : _create,
              child: Text(_busy ? 'তৈরি হচ্ছে…' : 'Create Group'),
            ),
          ),
        ]),
      );
}