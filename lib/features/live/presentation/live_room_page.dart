import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/live_service.dart';
import '../../../services/media_picker.dart';
import '../../../services/supabase_service.dart';

class LiveRoomPage extends StatefulWidget {
  const LiveRoomPage({super.key, required this.streamId, required this.isHost});
  final String streamId;
  final bool isHost;

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  final _input = TextEditingController();
  final _uid = SupabaseService.client.auth.currentUser!.id;
  Map<String, dynamic>? _stream;
  List<Map<String, dynamic>> _messages = [];
  int _viewers = 0, _likes = 0;
  RealtimeChannel? _ch, _viewersCh;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _ch = LiveService.subscribe(widget.streamId, onMessage: (row) async {
      final m = {...row};
      if (m['author'] == null) {
        final p = await SupabaseService.client
            .from('profiles').select('name, username').eq('id', m['user_id']).maybeSingle();
        m['author'] = p ?? {};
      }
      _messages.insert(0, m);
      if (mounted) setState(() {});
    }, onAnyChange: _load);
    _viewersCh = LiveService.subscribeViewers(widget.streamId, _refreshViewers);
    if (!widget.isHost) {
      LiveService.join(widget.streamId).then((_) => _refreshViewers());
    }
  }

  Future<void> _load() async {
    final s = await LiveService.byId(widget.streamId);
    if (mounted) {
      setState(() {
        _stream = s;
        _likes = s?['likes_count'] ?? 0;
      });
    }
    _refreshViewers();
    final msgs = await LiveService.messages(widget.streamId);
    if (mounted) setState(() => _messages = msgs);
  }

  Future<void> _refreshViewers() async {
    final n = await LiveService.viewerCount(widget.streamId);
    if (mounted) setState(() => _viewers = n);
  }

  @override
  void dispose() {
    _ch?.unsubscribe();
    _viewersCh?.unsubscribe();
    if (!widget.isHost) LiveService.leave(widget.streamId);
    super.dispose();
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    await LiveService.sendMessage(widget.streamId, t);
    _input.clear();
  }

  Future<void> _endWithReplay() async {
    setState(() => _busy = true);
    String? videoUrl;
    final v = await MediaPicker.pickVideo();
    if (v != null) {
      videoUrl = (await CloudinaryService.uploadVideo(v.bytes, v.name))['url'];
    }
    await LiveService.endLive(widget.streamId, videoUrl: videoUrl);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = _stream;
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isLive = s['status'] == 'live';
    final host = s['host'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isLive ? '🔴 LIVE' : s['status']} — ${s['title'] ?? ''}'),
        actions: [
          if (widget.isHost && !isLive)
            TextButton(
              onPressed: () async {
                await LiveService.goLive(widget.streamId);
                _load();
              },
              child: const Text('GO LIVE'),
            ),
          if (widget.isHost)
            TextButton(
              onPressed: _busy ? null : _endWithReplay,
              child: const Text('END'),
            ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: isLive ? Colors.red.withValues(alpha: 0.1) : null,
          child: Row(children: [
            CircleAvatar(child: Text(host?['name']?[0] ?? '?')),
            const SizedBox(width: 8),
            Expanded(child: Text(host?['name'] ?? '')),
            Text('👁 $_viewers  ❤️ $_likes'),
          ]),
        ),
        if (s['video_url'] != null && !isLive)
          const ListTile(
            leading: Icon(Icons.play_circle),
            title: Text('Replay available'),
          ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final a = m['author'] as Map<String, dynamic>?;
              final mine = m['user_id'] == _uid;
              return ListTile(
                dense: true,
                title: Text(a?['name'] ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                subtitle: Text(m['content'] ?? ''),
                trailing: (widget.isHost || mine)
                    ? IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: () async {
                          await LiveService.deleteMessage(m['id']);
                          _load();
                        },
                      )
                    : null,
              );
            },
          ),
        ),
        SafeArea(
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () async {
                await LiveService.like(widget.streamId);
                setState(() => _likes++);
              },
            ),
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(hintText: 'Live chat…'),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _send),
          ]),
        ),
      ]),
    );
  }
}