import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/learning_service.dart';
import '../../../services/media_picker.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});
  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _category = 'Education';
  String? _thumbUrl;

  final List<_LessonDraft> _lessons = [_LessonDraft()];
  final List<_QuestionDraft> _questions = [];
  bool _busy = false;

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await LearningService.createCourse(
        title: _title.text.trim(),
        description: _desc.text,
        category: _category,
        thumbnailUrl: _thumbUrl,
        lessons: [
          for (final l in _lessons)
            {'title': l.title.text, 'content': l.content.text, 'video_url': l.videoUrl}
        ],
        quizQuestions: [
          for (final q in _questions)
            {
              'q': q.q.text,
              'options': [for (final o in q.options) o.text],
              'answer': q.answer,
            }
        ],
      );
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('📚 Create Course')),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          GestureDetector(
            onTap: () async {
              final img = await MediaPicker.pickImage();
              if (img != null) {
                final r = await CloudinaryService.uploadImage(img.bytes, img.name);
                setState(() => _thumbUrl = r['url']);
              }
            },
            child: Container(
              height: 120,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: _thumbUrl == null
                  ? const Center(child: Icon(Icons.add_photo_alternate, size: 40))
                  : Image.network(_thumbUrl!, fit: BoxFit.cover),
            ),
          ),
          TextField(controller: _title,
              decoration: const InputDecoration(labelText: 'Course Title *')),
          TextField(controller: _desc,
              decoration: const InputDecoration(labelText: 'Description')),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const ['Education', 'Programming', 'Design', 'Business', 'Other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text('📖 Lessons', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _lessons.add(_LessonDraft())),
              child: const Text('+ Add'),
            ),
          ]),
          for (var i = 0; i < _lessons.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  TextField(
                    controller: _lessons[i].title,
                    decoration: InputDecoration(labelText: 'Lesson ${i + 1} title'),
                  ),
                  TextField(
                    controller: _lessons[i].content,
                    decoration: const InputDecoration(labelText: 'Text content'),
                    maxLines: 3,
                  ),
                  Row(children: [
                    Expanded(
                      child: Text(_lessons[i].videoUrl == null
                          ? 'Video: নেই (optional)'
                          : 'Video: আছে ✓'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final v = await MediaPicker.pickVideo();
                        if (v != null) {
                          final r = await CloudinaryService.uploadVideo(v.bytes, v.name);
                          setState(() => _lessons[i].videoUrl = r['url']);
                        }
                      },
                      child: const Text('Upload'),
                    ),
                  ]),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Text('📝 Quiz', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() =>
                  _questions.add(_QuestionDraft())),
              child: const Text('+ Question'),
            ),
          ]),
          for (var i = 0; i < _questions.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  TextField(
                    controller: _questions[i].q,
                    decoration: const InputDecoration(labelText: 'Question'),
                  ),
                  for (var oi = 0; oi < _questions[i].options.length; oi++)
                    Row(children: [
                      Radio<int>(
                        value: oi,
                        groupValue: _questions[i].answer,
                        onChanged: (v) =>
                            setState(() => _questions[i].answer = v!),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _questions[i].options[oi],
                          decoration: InputDecoration(
                              labelText: 'Option ${oi + 1} (radio = correct)'),
                        ),
                      ),
                    ]),
                ]),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _publish,
            child: Text(_busy ? 'Publishing…' : '🚀 Publish Course'),
          ),
        ]),
      );
}

class _LessonDraft {
  final title = TextEditingController();
  final content = TextEditingController();
  String? videoUrl;
}

class _QuestionDraft {
  final q = TextEditingController();
  final options = [TextEditingController(), TextEditingController(),
      TextEditingController(), TextEditingController()];
  int answer = 0;
}