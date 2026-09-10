import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/learning_service.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.courseId});
  final String courseId;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic> _questions = [];
  final List<int?> _answers = [];
  int? _score;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await LearningService.course(widget.courseId);
    final quizzes = rows?['quizzes'] as List? ?? [];
    if (quizzes.isNotEmpty) {
      final q = quizzes.first as Map<String, dynamic>;
      final qs = List<dynamic>.from(q['questions'] ?? []);
      if (mounted) {
        setState(() {
          _questions = qs;
          _answers.addAll(List.filled(qs.length, null));
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_answers.contains(null)) return;
    setState(() => _busy = true);
    final pct = await LearningService.submitQuiz(
        widget.courseId, _questions, _answers.map((e) => e!).toList());
    if (mounted) {
      setState(() {
        _score = pct;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      final passed = _score! >= 60;
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Result')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 64, color: passed ? Colors.amber : Colors.grey),
            Text('$_score%', style: Theme.of(context).textTheme.displaySmall),
            Text(passed ? 'পাস! 🎉' : 'Fail — আবার চেষ্টা করুন'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.pop(), child: const Text('Back')),
          ]),
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Quiz')),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _questions.length,
            itemBuilder: (_, i) {
              final q = _questions[i] as Map<String, dynamic>;
              final options = q['options'] as List? ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ${q['q'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      RadioGroup<int>(
                        onChanged: (v) {
                          if (v != null) setState(() => _answers[i] = v);
                        },
                        child: Column(children: [
                          for (var oi = 0; oi < options.length; oi++)
                            RadioListTile<int>(
                              dense: true,
                              title: Text('${options[oi]}'),
                              value: oi,
                            ),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Checking…' : 'Submit'),
          ),
        ),
      ]),
    );
  }
}