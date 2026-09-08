import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/games_service.dart';

class GamePlayerPage extends StatefulWidget {
  const GamePlayerPage({super.key, required this.gameId});
  final String gameId;

  @override
  State<GamePlayerPage> createState() => _GamePlayerPageState();
}

class _GamePlayerPageState extends State<GamePlayerPage> {
  Map<String, dynamic>? _game;
  int _score = 0, _timeLeft = 30, _target = -1;
  bool _running = false;
  Timer? _tick, _spawner;

  static Color _hex(String? s, Color fallback) {
    if (s == null) return fallback;
    try {
      return Color(int.parse(s.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await GamesService.byId(widget.gameId);
    if (mounted) setState(() => _game = g);
  }

  void _start() {
    final speed = _game?['config']?['speed'] ?? 800;
    setState(() {
      _running = true;
      _score = 0;
      _timeLeft = 30;
      _target = Random().nextInt(9);
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _end();
    });
    _spawner = Timer.periodic(Duration(milliseconds: speed), (t) {
      if (_running) setState(() => _target = Random().nextInt(9));
    });
  }

  Future<void> _end() async {
    _tick?.cancel();
    _spawner?.cancel();
    setState(() { _running = false; _target = -1; });
    await GamesService.recordSession(widget.gameId, _score, 'played');
    if (mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Game Over'),
          content: Text('Score: $_score'),
          actions: [
            TextButton(
                onPressed: () { Navigator.pop(context); _start(); },
                child: const Text('Again')),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spawner?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = _game;
    if (g == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final config = g['config'] as Map<String, dynamic>? ?? {};
    final bg = _hex(config['bg'] as String?, const Color(0xFF1A1A2E));
    final targetColor = _hex(config['target'] as String?, const Color(0xFFFF3D5A));

    return Scaffold(
      appBar: AppBar(title: Text(g['title'] ?? 'Game')),
      body: Container(
        color: bg,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Score: $_score',
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
                Text('Time: $_timeLeft',
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: 9,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: _running && i == _target
                      ? () => setState(() {
                            _score += (config['reward'] ?? 10) as int;
                            _target = Random().nextInt(9);
                          })
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: i == _target ? targetColor : Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_running)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _start,
                child: const Text('▶ Play'),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('🏆 Leaderboard',
                style: TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: GamesService.leaderboard(widget.gameId),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox();
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final s = snap.data![i];
                    final u = s['user'] as Map<String, dynamic>?;
                    return ListTile(
                      dense: true,
                      textColor: Colors.white,
                      leading: Text('#${i + 1}'),
                      title: Text(u?['name'] ?? 'Player'),
                      trailing: Text('${s['score']}'),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}