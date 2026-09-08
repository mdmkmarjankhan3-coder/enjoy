import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/content_service.dart';
import '../../../services/fnf_service.dart';
import '../../games/presentation/games_page.dart';
import '../../learning/presentation/learning_page.dart';
import '../../live/presentation/live_list_page.dart';
import 'widgets/content_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: AppConstants.homeSections.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🌟 ENJOY'),
          actions: [
            IconButton(icon: const Icon(Icons.search),
                onPressed: () => context.push('/search')),
            IconButton(icon: const Icon(Icons.tv),
                onPressed: () => context.push('/tv')),
            IconButton(icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications')),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: AppConstants.homeSections.map((s) => Tab(text: s)).toList(),
          ),
        ),
        body: TabBarView(
          children: AppConstants.homeSections
              .map((s) => HomeSectionContent(section: s)).toList(),
        ),
      ),
    );
  }
}

class HomeSectionContent extends StatelessWidget {
  const HomeSectionContent({super.key, required this.section});
  final String section;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 'For You':
        return ContentListView(service: ContentService.videos,
            emptyText: 'For You feed খালি — নতুন video দেখুন');
      case 'Videos':
        return ContentListView(service: ContentService.videos);
      case 'Shorts':
        return ContentListView(service: ContentService.shorts);
      case 'FNF Activity':
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: FnfService.myFriends(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            if (snap.data!.isEmpty) return const Center(child: Text('এখনো কোনো FNF নেই'));
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final f = snap.data![i]['friend'] as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: f['avatar_url'] != null
                        ? NetworkImage(f['avatar_url']) : null,
                    child: f['avatar_url'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(f['name'] ?? ''),
                  subtitle: Text('@${f['username'] ?? ''}'),
                );
              },
            );
          },
        );
      case 'New Creators':
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: FnfService.searchUsers(''),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final p = snap.data![i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p['avatar_url'] != null
                        ? NetworkImage(p['avatar_url']) : null,
                    child: p['avatar_url'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(p['name'] ?? ''),
                  subtitle: Text('@${p['username'] ?? ''}'),
                );
              },
            );
          },
        );
      case 'Learning':
        return const LearningPage();
      case 'Games':
        return const GamesPage();
      case 'Live':
        return const LiveListPage();
      default:
        return Center(child: Text('$section — পরের Phase-এ আসছে'));
    }
  }
}