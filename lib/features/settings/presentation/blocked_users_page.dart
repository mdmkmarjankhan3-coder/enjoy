import 'package:flutter/material.dart';
import '../../../services/moderation_service.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late Future<List<Map<String, dynamic>>> _future =
      ModerationService.blockedList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🚫 Blocked Users')),
        body: FutureBuilder(
          future: _future,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.data!.isEmpty) {
              return const Center(child: Text('কাউকে block করেননি'));
            }
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final p = snap.data![i]['profile'] as Map<String, dynamic>?;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p?['avatar_url'] != null
                        ? NetworkImage(p!['avatar_url']) : null,
                    child: p?['avatar_url'] == null
                        ? const Icon(Icons.person) : null,
                  ),
                  title: Text(p?['name'] ?? 'User'),
                  subtitle: Text('@${p?['username'] ?? ''}'),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      await ModerationService
                          .unblock(snap.data![i]['blocked_id']);
                      setState(() =>
                          _future = ModerationService.blockedList());
                    },
                    child: const Text('Unblock'),
                  ),
                );
              },
            );
          },
        ),
      );
}