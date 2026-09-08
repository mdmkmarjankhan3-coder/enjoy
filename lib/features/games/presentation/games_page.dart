import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/games_service.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('🎮 Games'),
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(text: 'Featured'), Tab(text: 'Trending'),
              Tab(text: 'New'), Tab(text: '1v1'),
            ]),
          ),
          body: const TabBarView(children: [
            _GameList(order: 'play_count'),
            _GameList(order: 'play_count'),
            _GameList(order: 'created_at'),
            _MatchLobby(),
          ]),
        ),
      );
}

class _GameList extends StatelessWidget {
  const _GameList({required this.order});
  final String order;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: GamesService.list(order: order),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('কোনো game নেই'));
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final g = snap.data![i];
              return ListTile(
                leading: g['cover_url'] != null
                    ? Image.network(g['cover_url'], width: 48, height: 48, fit: BoxFit.cover)
                    : const CircleAvatar(child: Icon(Icons.sports_esports)),
                title: Text(g['title'] ?? ''),
                subtitle: Text(
                    '${g['category'] ?? ''} • ${g['play_count'] ?? 0} plays'),
                onTap: () => context.push('/game/play/${g['id']}'),
              );
            },
          );
        },
      );
}

class _MatchLobby extends StatelessWidget {
  const _MatchLobby();

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
        future: GamesService.builtin('Tic Tac Toe 1v1'),
        builder: (_, gameSnap) {
          final game = gameSnap.data;
          if (game == null) return const Center(child: CircularProgressIndicator());
          final gameId = game['id'] as String;
          return Column(children: [
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final matchId = await GamesService.createMatch(gameId);
                if (context.mounted) {
                  context.push('/game/tictactoe/$matchId');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create 1v1 Challenge'),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: GamesService.waitingMatches(gameId),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.data!.isEmpty) {
                    return const Center(child: Text('কোনো waiting match নেই'));
                  }
                  return ListView.builder(
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) {
                      final m = snap.data![i];
                      final p1 = m['p1'] as Map<String, dynamic>?;
                      return ListTile(
                        leading: const Icon(Icons.sports_esports),
                        title: Text(p1?['name'] ?? 'Player'),
                        subtitle: const Text('চ্যালেঞ্জ অপেক্ষমাণ…'),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            await GamesService.joinMatch(m['id']);
                            if (context.mounted) {
                              context.push('/game/tictactoe/${m['id']}');
                            }
                          },
                          child: const Text('Join'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]);
        },
      );
}