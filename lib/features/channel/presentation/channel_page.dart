import 'package:flutter/material.dart';
import '../../../services/channel_service.dart';
import '../../../services/content_service.dart';
import '../../home/presentation/widgets/content_widgets.dart';

class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key, required this.channelId});
  final String channelId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('📺 Channel')),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: ChannelService.byId(channelId),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final ch = snap.data!;
            return Column(children: [
              Container(
                height: 100,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              ListTile(
                isThreeLine: true,
                leading: CircleAvatar(
                  backgroundImage: ch['logo_url'] != null
                      ? NetworkImage(ch['logo_url']) : null,
                  child: ch['logo_url'] == null ? const Icon(Icons.tv) : null,
                ),
                title: Text(ch['name'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${ch['username'] ?? ''}'),
                    Text(ch['description'] ?? ''),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: ChannelService.channelVideos(channelId),
                  builder: (_, vs) {
                    if (!vs.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vs.data!.isEmpty) {
                      return const Center(child: Text('কোনো video নেই'));
                    }
                    return ListView.builder(
                      itemCount: vs.data!.length,
                      itemBuilder: (_, i) => VideoCard(
                          item: vs.data![i], service: ContentService.videos),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      );
}