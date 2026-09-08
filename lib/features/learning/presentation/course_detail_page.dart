import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/learning_service.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});
  final String courseId;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  Map<String, dynamic>? _course;
  Map<String, dynamic>? _enrollment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await LearningService.course(widget.courseId);
    final e = await LearningService.enrollment(widget.courseId);
    if (mounted) setState(() { _course = c; _enrollment = e; });
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    if (c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lessons = (c['lessons'] as List? ?? [])
      ..sort((a, b) => (a['position'] ?? 0).compareTo(b['position'] ?? 0));
    final quizzes = c['quizzes'] as List? ?? [];
    final progress = _enrollment?['progress'] ?? 0;
    final done = List<dynamic>.from(_enrollment?['completed_lessons'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(c['title'] ?? '')),
      body: ListView(children: [
        if (c['thumbnail_url'] != null)
          Image.network(c['thumbnail_url'], height: 160, fit: BoxFit.cover),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['description'] ?? ''),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress / 100),
              Text('Progress: $progress%'),
              const SizedBox(height: 8),
              if (_enrollment == null)
                FilledButton(
                  onPressed: () async {
                    await LearningService.enroll(widget.courseId);
                    _load();
                  },
                  child: const Text('Enroll করুন'),
                ),
            ],
          ),
        ),
        const Divider(),
        const ListTile(title: Text('📖 Lessons')),
        for (final l in lessons)
          ListTile(
            leading: Icon(done.contains(l['id'])
                ? Icons.check_circle : Icons.play_circle_outline),
            title: Text(l['title'] ?? ''),
            onTap: () async {
              await context.push('/learning/lesson/${l['id']}', extra: {
                'course_id': widget.courseId,
                'total': lessons.length,
              });
              _load();
            },
          ),
        const Divider(),
        for (final q in quizzes)
          ListTile(
            leading: const Icon(Icons.quiz),
            title: Text(q['title'] ?? 'Quiz'),
            trailing: _enrollment?['quiz_passed'] == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
            onTap: () =>
                context.push('/learning/course/${widget.courseId}/quiz'),
          ),
      ]),
    );
  }
}