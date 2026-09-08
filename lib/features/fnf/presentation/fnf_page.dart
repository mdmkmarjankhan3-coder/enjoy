import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/chat_service.dart';
import '../../../services/fnf_service.dart';

class FnfPage extends StatelessWidget {
  const FnfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🤝 FNF'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.push('/chat'),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'FNF List'), Tab(text: 'Requests'), Tab(text: 'Add FNF'),
          ]),
        ),
        body: const TabBarView(children: [_FnfList(), _Requests(), _AddFnf()]),
      ),
    );
  }
}

class _FnfList extends StatelessWidget {
  const _FnfList();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: FnfService.myFriends(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('কোনো FNF নেই'));
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final f = snap.data![i]['friend'] as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: f['avatar_url'] != null
                      ? NetworkImage(f['avatar_url']) : null,
                  child: f['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(f['name'] ?? ''),
                subtitle: Text('@${f['username'] ?? ''}'),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () async {
                  final convId = await ChatService.openDirectChat(f['id']);
                  if (context.mounted) {
                    context.push('/chat/$convId', extra: {
                      'title': f['name'] ?? 'Chat',
                      'isGroup': false,
                      'other': f['id'],
                    });
                  }
                },
              );
            },
          );
        },
      );
}

class _Requests extends StatefulWidget {
  const _Requests();
  @override
  State<_Requests> createState() => _RequestsState();
}

class _RequestsState extends State<_Requests> {
  late Future<List<Map<String, dynamic>>> _future = FnfService.pendingRequests();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('কোনো request নেই'));
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final req = snap.data![i];
              final sender = req['sender'] as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(sender['name'] ?? ''),
                subtitle: Text('@${sender['username'] ?? ''}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await FnfService.acceptRequest(req);
                      setState(() => _future = FnfService.pendingRequests());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await FnfService.rejectRequest(req['id']);
                      setState(() => _future = FnfService.pendingRequests());
                    },
                  ),
                ]),
              );
            },
          );
        },
      );
}

class _AddFnf extends StatefulWidget {
  const _AddFnf();
  @override
  State<_AddFnf> createState() => _AddFnfState();
}

class _AddFnfState extends State<_AddFnf> {
  final _ctrl = TextEditingController();
  Future<List<Map<String, dynamic>>>? _results;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SearchBar(
            controller: _ctrl,
            hintText: 'নাম বা username দিয়ে খুঁজুন',
            onSubmitted: (q) => setState(() => _results = FnfService.searchUsers(q)),
          ),
        ),
        Expanded(
          child: _results == null
              ? const Center(child: Text('খুঁজে FNF request পাঠান'))
              : FutureBuilder(
                  future: _results,
                  builder: (_, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    return ListView.builder(
                      itemCount: snap.data!.length,
                      itemBuilder: (_, i) {
                        final p = snap.data![i];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(p['name'] ?? ''),
                          subtitle: Text('@${p['username'] ?? ''}'),
                          trailing: FilledButton.tonal(
                            onPressed: () async {
                              await FnfService.sendRequest(p['id']);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('FNF request পাঠানো হয়েছে')));
                              }
                            },
                            child: const Text('Add'),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ]);
}