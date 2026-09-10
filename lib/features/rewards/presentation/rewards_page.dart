import 'package:flutter/material.dart';
import '../../../services/badge_service.dart';
import '../../../services/rewards_service.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('🏆 Rewards'),
            bottom: const TabBar(tabs: [
              Tab(text: 'My Rewards'), Tab(text: 'Activity'), Tab(text: 'Leaderboard'),
            ]),
          ),
          body: const TabBarView(children: [_MyRewards(), _Activity(), _Leaderboard()]),
        ),
      );
}

class _MyRewards extends StatelessWidget {
  const _MyRewards();

  @override
  Widget build(BuildContext context) => ListView(children: [
        FutureBuilder<Map<String, dynamic>>(
          future: RewardsService.stats(),
          builder: (_, s) {
            final points = s.data?['points'] ?? 0;
            final level = s.data?['level'] ?? 1;
            return Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      Text('$points',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const Text('Points'),
                    ]),
                    Column(children: [
                      Text('Lv $level',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const Text('Level'),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('⭐ Badges'),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: BadgeService.myBadges(),
          builder: (_, snap) {
            final badges = snap.data ?? [];
            if (badges.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('এখনো কোনো badge নেই')),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final b in badges)
                  Chip(
                    avatar: Text((b['badge']?['icon'] ?? '🏅') as String),
                    label: Text(b['badge']?['name'] ?? 'Badge'),
                  ),
              ],
            );
          },
        ),
      ]);
}

class _Activity extends StatelessWidget {
  const _Activity();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: RewardsService.activityLog(),
        builder: (_, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('কোনো activity নেই'));
          }
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final a = snap.data![i];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.stars),
                title: Text(a['action'] ?? ''),
                trailing: Text('+${a['points']}'),
                subtitle: Text('${a['created_at']}'.substring(0, 16)),
              );
            },
          );
        },
      );
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: RewardsService.leaderboard(),
        builder: (_, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('Leaderboard খালি'));
          }
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final r = snap.data![i];
              final u = r['user'] as Map<String, dynamic>?;
              return ListTile(
                leading: Text('#${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text(u?['name'] ?? 'User'),
                subtitle: Text('Level ${r['level']}'),
                trailing: Text('${r['points']} pts'),
              );
            },
          );
        },
      );
}