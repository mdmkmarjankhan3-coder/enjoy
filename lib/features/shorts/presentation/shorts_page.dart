import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../services/content_service.dart';
import '../../videos/presentation/widgets/comments_sheet.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});
  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final _service = ContentService.shorts;
  List<Map<String, dynamic>> _items = [];
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _service.feed().then((v) => setState(() => _items = v));
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _items.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => _ShortItem(
          item: _items[i],
          active: i == _current,
          service: _service,
        ),
      ),
    );
  }
}

class _ShortItem extends StatefulWidget {
  const _ShortItem({required this.item, required this.active, required this.service});
  final Map<String, dynamic> item;
  final bool active;
  final ContentService service;

  @override
  State<_ShortItem> createState() => _ShortItemState();
}

class _ShortItemState extends State<_ShortItem> {
  VideoPlayerController? _ctrl;
  bool _liked = false, _saved = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.item['video_url']))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      })
      ..setLooping(true);
    widget.service.recordView(widget.item['id']);
    final liked = await widget.service.myActionIds('likes');
    if (mounted) setState(() => _liked = liked.contains(widget.item['id']));
  }

  @override
  void didUpdateWidget(covariant _ShortItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _ctrl?.value.isInitialized == true) {
      _ctrl!.play();
    } else {
      _ctrl?.pause();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  int _c(String k) => ((widget.item[k] as List?)?.first as Map?)?['count'] ?? 0;

  @override
  Widget build(BuildContext context) {
    final v = widget.item;
    return Stack(fit: StackFit.expand, children: [
      if (_ctrl != null && _ctrl!.value.isInitialized)
        GestureDetector(
          onTap: () => setState(() =>
              _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play()),
          child: Center(child: VideoPlayer(_ctrl!)),
        )
      else
        const Center(child: CircularProgressIndicator()),
      Positioned(
        right: 8, bottom: 80,
        child: Column(children: [
          _btn(Icons.favorite, _c('likes'), _liked ? Colors.red : Colors.white, () {
            widget.service.toggleAction(v['id'], 'likes', _liked);
            setState(() => _liked = !_liked);
          }),
          _btn(Icons.comment, _c('comment_list'), Colors.white, () =>
              showModalBottomSheet(context: context, isScrollControlled: true,
                  builder: (_) => CommentsSheet(service: widget.service, contentId: v['id']))),
          _btn(Icons.share, 0, Colors.white, () {
            Clipboard.setData(ClipboardData(text: v['video_url']));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Link copy হয়েছে')));
          }),
          _btn(Icons.bookmark, 0, _saved ? Colors.yellow : Colors.white, () {
            widget.service.toggleAction(v['id'], 'saves', _saved);
            setState(() => _saved = !_saved);
          }),
          _btn(Icons.flag, 0, Colors.white, () {}),
          _btn(Icons.more_vert, 0, Colors.white, () {}),
        ]),
      ),
      Positioned(
        left: 12, bottom: 24, right: 70,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('@${(v['author'] as Map?)?['username'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(v['title'] ?? '', style: const TextStyle(color: Colors.white)),
        ]),
      ),
    ]);
  }

  Widget _btn(IconData icon, int count, Color color, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Column(children: [
            Icon(icon, color: color, size: 32),
            if (count > 0) Text('$count', style: const TextStyle(color: Colors.white)),
          ]),
        ),
      );
}