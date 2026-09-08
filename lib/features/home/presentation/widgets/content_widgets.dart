import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/content_service.dart';

int _count(Map<String, dynamic> item, String key) =>
    ((item[key] as List?)?.first as Map?)?['count'] ?? 0;

class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.item, required this.service});
  final Map<String, dynamic> item;
  final ContentService service;

  @override
  Widget build(BuildContext context) {
    final author = item['author'] as Map<String, dynamic>?;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          service.recordView(item['id']);
          context.push('/${service.base}/${item['id']}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: item['thumbnail_url'] != null
                  ? Image.network(item['thumbnail_url'], fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.play_circle, size: 48)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${author?['name'] ?? ''} • '
                      '${_count(item, 'views')} views • '
                      '${_count(item, 'likes')} likes'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContentListView extends StatelessWidget {
  const ContentListView({super.key, required this.service, this.emptyText});
  final ContentService service;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.feed(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.isEmpty) return Center(child: Text(emptyText ?? 'কোনো content নেই'));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snap.data!.length,
          itemBuilder: (_, i) => VideoCard(item: snap.data![i], service: service),
        );
      },
    );
  }
}