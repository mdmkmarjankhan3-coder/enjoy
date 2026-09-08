import 'badge_service.dart';
import 'supabase_service.dart';

class LearningService {
  static final _c = SupabaseService.client;
  static String get _uid => _c.auth.currentUser!.id;

  static Future<List<Map<String, dynamic>>> courses() => _c
      .from('courses')
      .select('*, creator:profiles!creator_id(name, username)')
      .eq('is_published', true)
      .order('created_at', ascending: false);

  static Future<Map<String, dynamic>?> course(String id) => _c
      .from('courses')
      .select('*, lessons(*), quizzes(*)')
      .eq('id', id)
      .maybeSingle();

  static Future<String> createCourse({
    required String title,
    String description = '',
    String? category,
    String? thumbnailUrl,
    required List<Map<String, String?>> lessons,
    List<Map<String, dynamic>> quizQuestions = const [],
  }) async {
    final c = await _c.from('courses').insert({
      'creator_id': _uid,
      'title': title,
      'description': description,
      'category': category,
      'thumbnail_url': thumbnailUrl,
      'is_published': true,
    }).select('id').single();
    final id = c['id'] as String;
    for (var i = 0; i < lessons.length; i++) {
      await _c.from('lessons').insert({
        'course_id': id,
        'title': lessons[i]['title'],
        'content': lessons[i]['content'],
        'video_url': lessons[i]['video_url'],
        'position': i + 1,
      });
    }
    if (quizQuestions.isNotEmpty) {
      await _c.from('quizzes').insert({
        'course_id': id,
        'title': '$title - Quiz',
        'questions': quizQuestions,
      });
    }
    return id;
  }

  static Future<Map<String, dynamic>?> enrollment(String courseId) => _c
      .from('enrollments')
      .select()
      .eq('course_id', courseId)
      .eq('user_id', _uid)
      .maybeSingle();

  static Future<void> enroll(String courseId) =>
      _c.from('enrollments').upsert({'course_id': courseId, 'user_id': _uid});

  static Future<void> completeLesson(
      String courseId, String lessonId, int totalLessons) async {
    final enr = await enrollment(courseId);
    final done = List<dynamic>.from(enr?['completed_lessons'] ?? []);
    if (!done.contains(lessonId)) done.add(lessonId);
    final progress =
        totalLessons == 0 ? 0 : ((done.length / totalLessons) * 100).round();
    final completed = progress >= 100;
    await _c.from('enrollments').upsert({
      'course_id': courseId,
      'user_id': _uid,
      'completed_lessons': done,
      'progress': progress,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    });
    if (completed && enr?['quiz_passed'] != true && enr?['completed_at'] == null) {
      await BadgeService.award('course_complete');
    }
  }

  /// স্কোর % return করে; pass হলে quiz_passed সেট হয়
  static Future<int> submitQuiz(String courseId, List<dynamic> questions,
      List<int> answers) async {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      if (answers[i] == q['answer']) correct++;
    }
    final pct =
        questions.isEmpty ? 0 : ((correct / questions.length) * 100).round();
    if (pct >= 60) {
      await _c.from('enrollments').upsert({
        'course_id': courseId,
        'user_id': _uid,
        'quiz_passed': true,
      });
      await BadgeService.award('quiz_master');
    }
    return pct;
  }
}