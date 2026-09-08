import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/games_service.dart';
import '../../../services/media_picker.dart';

class GameCreatorPage extends StatefulWidget {
  const GameCreatorPage({super.key, this.gameId});
  final String? gameId; // edit mode

  @override
  State<GameCreatorPage> createState() => _GameCreatorPageState();
}

class _GameCreatorPageState extends State<GameCreatorPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _missions = TextEditingController();
  String _bg = '#1A1A2E', _target = '#FF3D5A';
  double _speed = 800, _reward = 10;
  bool _sound = true;
  String _controls = 'Tap';
  String? _coverUrl;
  bool _busy = false;

  static const _colors = {
    'Dark': '#1A1A2E', 'Blue': '#0F3460', 'Green': '#2D6A4F',
    'Red': '#9B2226', 'Purple': '#5A189A',
  };

  @override
  void initState() {
    super.initState();
    if (widget.gameId != null) _load();
  }

  Future<void> _load() async {
    final g = await GamesService.byId(widget.gameId!);
    if (g == null || !mounted) return;
    final cfg = g['config'] as Map<String, dynamic>? ?? {};
    _title.text = g['title'] ?? '';
    _desc.text = g['description'] ?? '';
    _coverUrl = g['cover_url'];
    _bg = cfg['bg'] ?? _bg;
    _target = cfg['target'] ?? _target;
    _speed = (cfg['speed'] ?? _speed).toDouble();
    _reward = (cfg['reward'] ?? _reward).toDouble();
    final missions = cfg['missions'];
    if (missions is List) _missions.text = missions.join(', ');
    setState(() {});
  }

  Map<String, dynamic> get _config => {
        'map': _bg,
        'character': _target,
        'bg': _bg,
        'target': _target,
        'speed': _speed.round(),
        'reward': _reward.round(),
        'sound': _sound,
        'controls': _controls,
        'missions': _missions.text.split(',').map((e) => e.trim())
            .where((e) => e.isNotEmpty).toList(),
        'rules': 'Target tap করলে ${(_reward).round()} point',
        'environment': 'default',
        'health': 3,
      };

  Future<void> _publish({bool test = false}) async {
    setState(() => _busy = true);
    try {
      String id;
      if (widget.gameId == null) {
        id = await GamesService.createGame(
          title: _title.text.trim().isEmpty ? 'My Game' : _title.text.trim(),
          description: _desc.text,
          coverUrl: _coverUrl,
          config: _config,
        );
      } else {
        id = widget.gameId!;
        await GamesService.updateGame(id,
            title: _title.text.trim(), description: _desc.text, config: _config);
      }
      if (!mounted) return;
      if (test) {
        context.push('/game/play/$id');
      } else {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.gameId == null
            ? '🛠️ Create Game' : '🛠️ Game Editor')),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          if (widget.gameId == null) ...[
            Text('🎮 My Games',
                style: Theme.of(context).textTheme.titleMedium),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: GamesService.myGames(),
              builder: (_, snap) => Column(children: [
                for (final g in snap.data ?? [])
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.sports_esports),
                    title: Text(g['title'] ?? ''),
                    subtitle: Text('v${g['version']} • ${g['play_count']} plays'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => context.push('/game/create/${g['id']}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () =>
                            GamesService.deleteGame(g['id']),
                      ),
                    ]),
                  ),
              ]),
            ),
            const Divider(),
          ],
          GestureDetector(
            onTap: () async {
              final img = await MediaPicker.pickImage();
              if (img != null) {
                final r = await CloudinaryService.uploadImage(img.bytes, img.name);
                setState(() => _coverUrl = r['url']);
              }
            },
            child: Container(
              height: 100,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: _coverUrl == null
                  ? const Center(child: Icon(Icons.add_photo_alternate, size: 40))
                  : Image.network(_coverUrl!, fit: BoxFit.cover),
            ),
          ),
          TextField(controller: _title,
              decoration: const InputDecoration(labelText: 'Game Title *')),
          TextField(controller: _desc,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 8),
          Text('🗺️ Map / Environment', style: Theme.of(context).textTheme.titleSmall),
          DropdownButtonFormField<String>(
            initialValue: _bg,
            items: [
              for (final e in _colors.entries)
                DropdownMenuItem(value: e.value, child: Text(e.key)),
            ],
            onChanged: (v) => setState(() => _bg = v!),
          ),
          Text('🎯 Character / Target color', style: Theme.of(context).textTheme.titleSmall),
          DropdownButtonFormField<String>(
            initialValue: _target,
            items: [
              for (final e in _colors.entries)
                DropdownMenuItem(value: e.value, child: Text(e.key)),
            ],
            onChanged: (v) => setState(() => _target = v!),
          ),
          Text('⚡ Speed: ${_speed.round()} ms'),
          Slider(value: _speed, min: 300, max: 1500,
              onChanged: (v) => setState(() => _speed = v)),
          Text('🎁 Reward: ${_reward.round()} points'),
          Slider(value: _reward, min: 5, max: 100,
              onChanged: (v) => setState(() => _reward = v)),
          TextField(controller: _missions,
              decoration: const InputDecoration(labelText: 'Missions (comma দিয়ে)')),
          SwitchListTile(title: const Text('🔊 Sound'), value: _sound,
              onChanged: (v) => setState(() => _sound = v)),
          DropdownButtonFormField<String>(
            initialValue: _controls,
            decoration: const InputDecoration(labelText: 'Controls'),
            items: const ['Tap', 'Swipe', 'Hold']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _controls = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _publish(test: true),
                child: const Text('▶ Build & Test'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _publish(),
                child: Text(widget.gameId == null ? 'Publish' : 'Update (v+)'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🤖 AI Game Creator — Phase 9-এ আসবে'))),
            icon: const Icon(Icons.smart_toy),
            label: const Text('🤖 AI Help'),
          ),
        ]),
      );
}