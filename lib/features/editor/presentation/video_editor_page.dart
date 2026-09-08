import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/content_service.dart';
import '../../../services/media_picker.dart';

class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({super.key, required this.cloudUrl,
      required this.publicId, required this.isShort});
  final String cloudUrl;
  final String publicId;
  final bool isShort;

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  final _service = ContentService.videos;
  VideoPlayerController? _ctrl;

  // Edit state (প্ল্যানের সব tool)
  double _trimStart = 0, _trimEnd = 1, _speed = 1;
  int _rotation = 0;
  final List<String> _texts = [];
  final List<String> _stickers = [];
  final int _effectIndex = 0;
  final int _transitionIndex = 0;
  bool _caption = false;
  double _thumbAt = 0;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _category = 'Entertainment';
  String _privacy = 'public';

  static const _filters = ['Normal', 'B&W', 'Warm', 'Cool', 'Vivid'];
  static const _categories = [
    'Education', 'Entertainment', 'Gaming', 'Music', 'News', 'Sports', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.cloudUrl))
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true)
      ..play();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  List<ColorFilter> get _filterOps => [
        const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
        const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        ColorFilter.mode(
            Colors.orange.withValues(alpha: 0.2), BlendMode.overlay),
        ColorFilter.mode(
            Colors.blue.withValues(alpha: 0.2), BlendMode.overlay),
        ColorFilter.mode(
            Colors.purple.withValues(alpha: 0.15), BlendMode.overlay),
      ];

  Future<void> _publish({bool draft = false}) async {
    String? thumbUrl;
    final thumb = await MediaPicker.pickImage();
    if (thumb != null) {
      thumbUrl =
          (await CloudinaryService.uploadImage(thumb.bytes, thumb.name))['url'];
    }
    await _service.publish(
      title: _titleCtrl.text.trim().isEmpty
          ? 'Untitled'
          : _titleCtrl.text.trim(),
      description: _descCtrl.text,
      category: _category,
      tags: _tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      privacy: _privacy,
      status: draft ? 'draft' : 'published',
      videoUrl: widget.cloudUrl,
      publicId: widget.publicId,
      thumbnailUrl: thumbUrl,
    );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 Video Editor'),
        actions: [
          TextButton(
              onPressed: () => _publish(draft: true),
              child: const Text('Draft')),
          FilledButton(
              onPressed: () => _publish(), child: const Text('Publish')),
        ],
      ),
      body: Column(children: [
        // Preview
        Expanded(
          flex: 3,
          child: Center(
            child: _ctrl != null && _ctrl!.value.isInitialized
                ? Transform.rotate(
                    angle: _rotation * 3.14159 / 180,
                    child: ColorFiltered(
                      colorFilter: _filterOps[_filterIndex],
                      child: AspectRatio(
                        aspectRatio: _ctrl!.value.aspectRatio,
                        child: VideoPlayer(_ctrl!),
                      ),
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
        // Playback row
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _ctrl!.play()),
          IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _ctrl!.pause()),
          Text('Speed: ${_speed}x'),
          Slider(
            value: _speed,
            min: 0.5,
            max: 2,
            divisions: 3,
            onChanged: (v) => setState(() {
              _speed = v;
              _ctrl!.setPlaybackSpeed(v);
            }),
          ),
        ]),
        // Tools
        Expanded(
          flex: 4,
          child: ListView(children: [
            _tool(Icons.content_cut, '✂ Trim', '', _trimSlider()),
            _tool(Icons.splitscreen, '✂ Split',
                'Timeline-এ ভাগ (metadata হিসেবে সংরক্ষিত)',
                Slider(
                    value: _trimEnd,
                    min: 0,
                    max: 1,
                    onChanged: (v) => setState(() => _trimEnd = v))),
            _tool(Icons.crop, '📐 Crop', 'Aspect 16:9', const SizedBox()),
            _tool(Icons.rotate_right, '🔄 Rotate', '$_rotation°',
                IconButton(
                    icon: const Icon(Icons.rotate_90_degrees_ccw),
                    onPressed: () =>
                        setState(() => _rotation = (_rotation + 90) % 360))),
            _tool(Icons.music_note, '🎵 Music', 'Track যোগ', const SizedBox()),
            _tool(Icons.volume_up, '🔊 Audio', 'Volume adjust',
                const SizedBox()),
            _tool(Icons.mic, '🎙 Voice-over', 'Record', const SizedBox()),
            _tool(Icons.text_fields, '📝 Text', '${_texts.length} টি',
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final c = TextEditingController();
                      await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: const Text('Text যোগ করুন'),
                                content: TextField(controller: c),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'))
                                ],
                              ));
                      if (c.text.isNotEmpty) {
                        setState(() => _texts.add(c.text));
                      }
                    })),
            _tool(Icons.emoji_emotions, '😊 Sticker',
                '${_stickers.length} টি', const SizedBox()),
            _tool(Icons.auto_awesome, '✨ Effects', '$_effectIndex',
                const SizedBox()),
            _tool(Icons.filter_alt, '🎨 Filter', _filters[_filterIndex],
                DropdownButton<int>(
                  value: _filterIndex,
                  items: [
                    for (var i = 0; i < _filters.length; i++)
                      DropdownMenuItem(value: i, child: Text(_filters[i]))
                  ],
                  onChanged: (i) => setState(() => _filterIndex = i!),
                )),
            _tool(Icons.switch_video, '🔀 Transitions', '$_transitionIndex',
                const SizedBox()),
            SwitchListTile(
              title: const Text('💬 Captions'),
              value: _caption,
              onChanged: (v) => setState(() => _caption = v),
            ),
            _tool(Icons.image, '🖼 Thumbnail',
                '${_thumbAt.toStringAsFixed(1)}s',
                Slider(
                    value: _thumbAt,
                    min: 0,
                    max: 10,
                    onChanged: (v) => setState(() => _thumbAt = v))),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *')),
                TextField(
                    controller: _descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                TextField(
                    controller: _tagsCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Tags (comma দিয়ে)')),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _privacy,
                  decoration: const InputDecoration(labelText: 'Privacy'),
                  items: const ['public', 'unlisted', 'private']
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _privacy = v!),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('🤖 AI Help — Phase 9-এ আসবে'))),
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('🤖 AI Help (Optional)'),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  int _filterIndex = 0;

  Widget _trimSlider() => Column(children: [
        Text(
            'Trim: ${_trimStart.toStringAsFixed(2)} → ${_trimEnd.toStringAsFixed(2)}'),
        RangeSlider(
          values: RangeValues(_trimStart, _trimEnd),
          min: 0,
          max: 1,
          onChanged: (v) => setState(() {
            _trimStart = v.start;
            _trimEnd = v.end;
          }),
        ),
      ]);

  Widget _tool(IconData icon, String title, String subtitle, Widget control) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: control is SizedBox ? Text(subtitle) : null,
        trailing: control is SizedBox ? control : null,
      );
}