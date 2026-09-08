import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/notifications_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _items = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = NotificationsService.subscribe(_load);
  }

  Future<void> _load() async {
    final data = await NotificationsService.fetch();
    NotificationsService.markAllRead();
    if (mounted) setState(() => _items = data);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🔔 Notifications')),
        body: _items.isEmpty
            ? const Center(child: Text('কোনো notification নেই'))
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final n = _items[i];
                  final actor = n['actor'] as Map<String, dynamic>?;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: actor?['avatar_url'] != null
                          ? NetworkImage(actor!['avatar_url']) : null,
                      child: actor?['avatar_url'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(actor?['name'] ?? 'কেউ'),
                    subtitle: Text(n['content'] ?? n['type'] ?? ''),
                    trailing: n['is_read'] == true
                        ? null : const Icon(Icons.circle, size: 10, color: Colors.red),
                  );
                },
              ),
      );
}