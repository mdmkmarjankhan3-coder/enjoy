import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateCenterPage extends StatelessWidget {
  const CreateCenterPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('➕ Create')),
        body: ListView(children: [
          _tile(context, Icons.video_library, '🎬 Upload Video',
              () => context.push('/create/video')),
          _tile(context, Icons.smartphone, '📱 Create Short',
              () => context.push('/create/short')),
          _tile(context, Icons.article, '📝 Community Post',
              () => _soon(context, 'Community Post — পরের Phase')),
          _tile(context, Icons.podcasts, '🔴 Go Live',
              () => context.push('/live/go')),
          _tile(context, Icons.sports_esports, '🎮 Create Game',
              () => context.push('/game/create')),
          _tile(context, Icons.school, '📚 Create Course',
              () => context.push('/course/create')),
          _tile(context, Icons.dashboard_customize, '🎨 Creator Studio',
              () => context.push('/creator-studio')),
        ]),
      );

  void _soon(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) =>
      ListTile(leading: Icon(icon), title: Text(title), onTap: onTap,
          trailing: const Icon(Icons.chevron_right));
}