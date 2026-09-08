import 'package:flutter/material.dart';
import '../../../services/content_service.dart';
import '../../../services/fnf_service.dart';

class CreatorStudioPage extends StatelessWidget {
  const CreatorStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🎨 Creator Studio'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Content'), Tab(text: 'Drafts'), Tab(text: 'Analytics'),
            Tab(text: 'Audience'), Tab(text: 'Monetization'),
          ]),
        ),
        body: const TabBarView(children: [
          _ContentList(status: 'published'),
          _ContentList(status: 'draft'),
          _Analytics(),
          _Audience(),
          _Locked(),
        ]),
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  const _ContentList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: ContentService.videos.mine(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.where((v) => v['status'] == status).toList();
          if (items.isEmpty) {
            return Center(child: Text('কোনো $status content নেই'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final v = items[i];
              int c(String k) =>
                  ((v[k] as List?)?.first as Map?)?['count'] ?? 0;
              return ListTile(
                leading: const Icon(Icons.video_library),
                title: Text(v['title'] ?? ''),
                subtitle: Text('👁 ${c('views')}  ❤️ ${c('likes')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ContentService.videos.remove(v['id']),
                ),
              );
            },
          );
        },
      );
}

class _Analytics extends StatelessWidget {
  const _Analytics();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: ContentService.videos.mine(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          int total(String k) => snap.data!.fold<int>(
                0,
                (a, v) =>
                    a +
                    ((((v[k] as List?)?.first as Map?)?['count']) as int? ??
                        0),
              );
          return ListView(children: [
            _stat('Total Videos', '${snap.data!.length}'),
            _stat('Total Views', '${total('views')}'),
            _stat('Total Likes', '${total('likes')}'),
          ]);
        },
      );

  Widget _stat(String t, String v) => ListTile(
      leading: const Icon(Icons.insights),
      title: Text(t),
      trailing: Text(v));
}

class _Audience extends StatelessWidget {
  const _Audience();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: FnfService.myFriends(),
        builder: (_, snap) => ListView(children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('FNF (Audience)'),
            trailing: Text('${snap.data?.length ?? 0}'),
          ),
        ]),
      );
}

class _Locked extends StatelessWidget {
  const _Locked();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('💰 Monetization & Earnings — Phase 10-এ আসবে\n'
            '(Eligibility → Review → Approval ফ্লো সহ)'));
}