import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../features/ai/presentation/widgets/ai_components.dart';
import '../../../services/learning_service.dart';
import '../../../services/supabase_service.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.lessonId, required this.courseId,
      required this.totalLessons});
  final String lessonId;
  final String courseId;
  final int totalLessons;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  Map<String, dynamic>? _lesson;
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await SupabaseService.client
        .from('lessons').select().eq('id', widget.lessonId).maybeSingle();
    if (!mounted) return;
    setState(() => _lesson = l);
    final url = l?['video_url'];
    if (url != null) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) => setState(() {}))
        ..play();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await LearningService.completeLesson(
        widget.courseId, widget.lessonId, widget.totalLessons);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = _lesson;
    if (l == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(l['title'] ?? '')),
      body: Column(children: [
        if (_ctrl != null && _ctrl!.value.isInitialized)
          AspectRatio(
            aspectRatio: _ctrl!.value.aspectRatio,
            child: VideoPlayer(_ctrl!),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(l['content'] ?? ''),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAiChatSheet(context,
                    contextText:
                        'বুঝিয়ে দাও: Lesson "${l['title'] ?? ''}" — ${(l['content'] ?? '').toString().substring(0, (l['content'] ?? '').toString().length > 500 ? 500 : (l['content'] ?? '').toString().length)}'),
                icon: const Icon(Icons.smart_toy),
                label: const Text('🤖 AI Explain'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _complete,
              icon: const Icon(Icons.check),
              label: const Text('Complete'),
            ),
          ]),
        ),
      ]),
    );
  }
}