import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/ads_service.dart';
import '../../../../services/content_service.dart';

int countOf(Map<String, dynamic> item, String key) =>
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${author?['name'] ?? ''} • '
                    '${countOf(item, 'views')} views • '
                    '${countOf(item, 'likes')} likes'),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// 📢 Feed Ad Card (প্ল্যান ২৬)
class AdCard extends StatelessWidget {
  const AdCard({super.key, required this.ad});
  final Map<String, dynamic> ad;

  @override
  Widget build(BuildContext context) {
    final id = ad['id'] as int;
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: InkWell(
        onTap: () async {
          await AdsService.record(id, 'click');
          final url = ad['target_url'];
          if (url != null && url.toString().isNotEmpty) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          }
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text('📢 Ad • ${ad['advertiser'] ?? ''}',
                style: const TextStyle(fontSize: 10)),
          ),
          if (ad['image_url'] != null)
            Image.network(ad['image_url'], fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(ad['body'] ?? '', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ]),
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
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.isEmpty) {
          return Center(child: Text(emptyText ?? 'কোনো content নেই'));
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: AdsService.nextAd(),
          builder: (_, adSnap) {
            final ad = adSnap.data;
            if (ad != null) AdsService.record(ad['id'] as int, 'impression');
            final items = snap.data!;
            final count = items.length + (ad != null ? 1 : 0);
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: count,
              itemBuilder: (_, i) {
                if (ad != null && i == 3) return AdCard(ad: ad);
                final itemIndex = i > 3 ? i - 1 : i;
                if (itemIndex >= items.length) return const SizedBox();
                return VideoCard(item: items[itemIndex], service: service);
              },
            );
          },
        );
      },
    );
  }
}