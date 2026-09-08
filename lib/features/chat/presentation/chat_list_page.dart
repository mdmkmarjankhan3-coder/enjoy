import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/chat_service.dart';
import '../../../services/supabase_service.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.client.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => context.push('/group/create'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ChatService.myConversations(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) {
            return const Center(child: Text('কোনো chat নেই — FNF থেকে শুরু করুন'));
          }
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final conv = snap.data![i];
              final isGroup = conv['type'] == 'group';
              final members = conv['members'] as List;
              Map<String, dynamic>? other;
              if (!isGroup) {
                for (final m in members) {
                  if (m['user_id'] != uid) {
                    other = m['profile'] as Map<String, dynamic>;
                  }
                }
              }
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(isGroup ? Icons.groups : Icons.person),
                ),
                title: Text(isGroup
                    ? (conv['name'] ?? 'Group')
                    : (other?['name'] ?? 'User')),
                subtitle: Text(isGroup
                    ? '${members.length} members'
                    : '@${other?['username'] ?? ''}'),
                onTap: () => context.push('/chat/${conv['id']}', extra: {
                  'title': isGroup ? (conv['name'] ?? 'Group') : (other?['name'] ?? 'Chat'),
                  'isGroup': isGroup,
                  'other': isGroup ? null : other?['id'],
                }),
                trailing: isGroup
                    ? IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () =>
                            context.push('/group/info/${conv['id']}'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}