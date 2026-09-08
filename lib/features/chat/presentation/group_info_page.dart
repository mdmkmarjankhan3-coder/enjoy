import 'package:flutter/material.dart';
import '../../../services/chat_service.dart';

class GroupInfoPage extends StatelessWidget {
  const GroupInfoPage({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('👥 Group Info'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Members'), Tab(text: 'Posts'),
          ]),
        ),
        body: TabBarView(children: [_Members(groupId: groupId), _Posts(groupId: groupId)]),
      ),
    );
  }
}

class _Members extends StatelessWidget {
  const _Members({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: ChatService.myConversations(),
        builder: (_, snap) {
          final convs = snap.data ?? [];
          Map<String, dynamic>? conv;
          for (final c in convs) {
            if (c['id'] == groupId) conv = c;
          }
          if (conv == null) return const Center(child: CircularProgressIndicator());
          final members = conv['members'] as List;
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) {
              final p = members[i]['profile'] as Map<String, dynamic>?;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(p?['name'] ?? 'User'),
                subtitle: Text('@${p?['username'] ?? ''}'),
                trailing: Text(members[i]['role'] ?? 'member'),
              );
            },
          );
        },
      );
}

class _Posts extends StatefulWidget {
  const _Posts({required this.groupId});
  final String groupId;

  @override
  State<_Posts> createState() => _PostsState();
}

class _PostsState extends State<_Posts> {
  final _ctrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future = ChatService.groupPosts(widget.groupId);

  Future<void> _post() async {
    if (_ctrl.text.trim().isEmpty) return;
    await ChatService.addGroupPost(widget.groupId, _ctrl.text.trim());
    _ctrl.clear();
    setState(() => _future = ChatService.groupPosts(widget.groupId));
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(hintText: 'Group Post লিখুন…'),
            )),
            IconButton(icon: const Icon(Icons.send), onPressed: _post),
          ]),
        ),
        Expanded(
          child: FutureBuilder(
            future: _future,
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.isEmpty) return const Center(child: Text('কোনো post নেই'));
              return ListView.builder(
                itemCount: snap.data!.length,
                itemBuilder: (_, i) {
                  final p = snap.data![i];
                  final a = p['author'] as Map<String, dynamic>?;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(a?['name'] ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(p['content'] ?? ''),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]);
}