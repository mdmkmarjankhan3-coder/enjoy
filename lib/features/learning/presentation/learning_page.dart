import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/learning_service.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('📚 Learning'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/course/create'),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: LearningService.courses(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.data!.isEmpty) {
              return const Center(child: Text('কোনো course নেই — প্রথম course তৈরি করুন'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final c = snap.data![i];
                final creator = c['creator'] as Map<String, dynamic>?;
                return Card(
                  child: ListTile(
                    leading: c['thumbnail_url'] != null
                        ? Image.network(c['thumbnail_url'], width: 56, height: 56, fit: BoxFit.cover)
                        : const CircleAvatar(child: Icon(Icons.school)),
                    title: Text(c['title'] ?? ''),
                    subtitle: Text(
                        '${creator?['name'] ?? ''} • ${c['category'] ?? ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/learning/course/${c['id']}'),
                  ),
                );
              },
            );
          },
        ),
      );
}