import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/live_service.dart';

class LiveListPage extends StatelessWidget {
  const LiveListPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('🔴 Live'),
          actions: [
            IconButton(
              icon: const Icon(Icons.podcasts),
              onPressed: () => context.push('/live/go'),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: LiveService.streams('live'),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.data!.isEmpty) {
              return const Center(child: Text('এখন কেউ live নেই — আপনি শুরু করুন!'));
            }
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final s = snap.data![i];
                final host = s['host'] as Map<String, dynamic>?;
                return ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Colors.red, child: Icon(Icons.podcasts)),
                  title: Text(s['title'] ?? ''),
                  subtitle: Text(host?['name'] ?? ''),
                  trailing: Text('❤️ ${s['likes_count'] ?? 0}'),
                  onTap: () => context.push('/live/${s['id']}',
                      extra: {'isHost': false}),
                );
              },
            );
          },
        ),
      );
}