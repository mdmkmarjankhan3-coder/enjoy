import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/content_service.dart';
import '../../../services/learning_service.dart';
import '../../../services/live_service.dart';

class TvPage extends StatelessWidget {
  const TvPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('📺 ENJOY TV')),
        body: ListView(children: [
          _section(context, '🔴 Live TV', LiveService.streams('live'),
              (s) => ListTile(
                    leading: const Icon(Icons.podcasts, color: Colors.red),
                    title: Text(s['title'] ?? ''),
                    onTap: () => context.push('/live/${s['id']}',
                        extra: {'isHost': false}),
                  )),
          _section(context, '📚 Educational Shows', LearningService.courses(),
              (c) => ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(c['title'] ?? ''),
                    onTap: () => context.push('/learning/course/${c['id']}'),
                  )),
          _section(context, '🎬 Entertainment', _videosBy('Entertainment'),
              (v) => ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(v['title'] ?? ''),
                    onTap: () => context.push('/video/${v['id']}'),
                  )),
          _section(context, '🏅 Sports', _videosBy('Sports'),
              (v) => ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(v['title'] ?? ''),
                    onTap: () => context.push('/video/${v['id']}'),
                  )),
          _section(context, '📰 News', _videosBy('News'),
              (v) => ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(v['title'] ?? ''),
                    onTap: () => context.push('/video/${v['id']}'),
                  )),
        ]),
      );

  Future<List<Map<String, dynamic>>> _videosBy(String cat) async {
    final all = await ContentService.videos.feed();
    return all.where((v) => v['category'] == cat).toList();
  }

  Widget _section(BuildContext context, String title,
      Future<List<Map<String, dynamic>>> future,
      Widget Function(Map<String, dynamic>) item) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      SizedBox(
        height: 140,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return const Center(child: Text('কোনো content নেই'));
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snap.data!.length,
              itemBuilder: (_, i) => SizedBox(
                  width: 260, child: item(snap.data![i])),
            );
          },
        ),
      ),
    ]);
  }
}