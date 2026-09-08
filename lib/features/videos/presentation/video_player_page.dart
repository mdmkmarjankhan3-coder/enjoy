import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../services/content_service.dart';
import '../../../services/supabase_service.dart';
import 'widgets/comments_sheet.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.id});
  final String id;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final _service = ContentService.videos;
  Map<String, dynamic>? _video;
  VideoPlayerController? _ctrl;
  bool _liked = false, _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _service.byId(widget.id);
    final liked = await _service.myActionIds('likes');
    final saved = await _service.myActionIds('saves');
    if (!mounted) return;
    setState(() {
      _video = v;
      _liked = liked.contains(widget.id);
      _saved = saved.contains(widget.id);
    });
    if (v != null) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(v['video_url']))
        ..initialize().then((_) => setState(() {}))
        ..setLooping(true)
        ..play();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  int _c(String k) => ((_video?[k] as List?)?.first as Map?)?['count'] ?? 0;

  Future<void> _report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('🚩 Report'),
        children: [
          for (final r in ['Spam', 'Violence', 'Copyright', 'Other'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, r),
              child: Text(r),
            ),
        ],
      ),
    );
    if (reason != null) {
      await SupabaseService.client.from('reports').insert({
        'reporter_id': SupabaseService.client.auth.currentUser!.id,
        'target_type': 'video',
        'target_id': widget.id,
        'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report জমা হয়েছে')),
        );
      }
    }
  }

  Future<void> _download() async {
    final v = _video;
    if (v == null) return;
    await SupabaseService.client.from('downloads').insert({
      'user_id': SupabaseService.client.auth.currentUser!.id,
      'content_type': 'video',
      'content_id': widget.id,
      'url': v['video_url'],
    });
    await launchUrl(
      Uri.parse(v['video_url']),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    if (v == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final author = v['author'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: Text(v['title'] ?? '')),
      body: Column(children: [
        AspectRatio(
          aspectRatio: _ctrl?.value.aspectRatio ?? 16 / 9,
          child: _ctrl != null && _ctrl!.value.isInitialized
              ? GestureDetector(
                  onTap: () => setState(() {
                    _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
                  }),
                  child: VideoPlayer(_ctrl!),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: Text(
                '👁 ${_c('views')}  ❤️ ${_c('likes')}  💬 ${_c('comment_list')}',
              ),
            ),
            Text(author?['name'] ?? ''),
          ]),
        ),
        const Divider(height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _action(Icons.favorite, _liked ? 'Liked' : 'Like', () {
              _service.toggleAction(widget.id, 'likes', _liked);
              setState(() => _liked = !_liked);
            }, active: _liked),
            _action(Icons.comment, 'Comment', () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    CommentsSheet(service: _service, contentId: widget.id),
              );
            }),
            _action(Icons.share, 'Share', () {
              Clipboard.setData(ClipboardData(text: v['video_url']));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copy হয়েছে')),
              );
            }),
            _action(Icons.bookmark, _saved ? 'Saved' : 'Save', () {
              _service.toggleAction(widget.id, 'saves', _saved);
              setState(() => _saved = !_saved);
            }, active: _saved),
            _action(Icons.download, 'Download', _download),
            _action(Icons.flag, 'Report', _report),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Text(v['description'] ?? ''),
          ),
        ),
      ]),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
          {bool active = false}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: active ? Theme.of(context).colorScheme.primary : null),
            Text(label, style: const TextStyle(fontSize: 10)),
          ]),
        ),
      );
}