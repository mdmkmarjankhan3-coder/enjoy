import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import 'widgets/ai_components.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _input = TextEditingController();
  final List<Map<String, String>> _chat = [];
  bool _busy = false;

  Future<void> _ask(String text) async {
    setState(() {
      _chat.add({'role': 'user', 'text': text});
      _busy = true;
    });
    final answer = await AiService.ask(text);
    if (mounted) {
      setState(() {
        _chat.add({'role': 'ai', 'text': answer});
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('🤖 ENJOY AI'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'AI Memory clear',
              onPressed: () {
                AiService.clearMemory();
                setState(() => _chat.clear());
              },
            ),
          ],
        ),
        body: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              AiService.configured
                  ? '🧠 AI connected • Memory: ON (আপনার অনুমতিতে)'
                  : '🧠 Built-in assistant • Settings-এ endpoint বসালে full AI চালু হবে',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          AiSuggestionChips(onSelect: _ask),
          Expanded(
            child: _chat.isEmpty
                ? const Center(child: Text('🤖 ENJOY AI — জিজ্ঞেস করুন যা চান'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _chat.length,
                    itemBuilder: (_, i) => AiResultCard(
                      text: _chat[i]['text']!,
                      isUser: _chat[i]['role'] == 'user',
                    ),
                  ),
          ),
          if (_busy) const AiLoadingDots(),
          SafeArea(
            child: Row(children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(hintText: 'Message লিখুন…'),
                  onSubmitted: (t) {
                    if (t.trim().isNotEmpty) {
                      _ask(t.trim());
                      _input.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_input.text.trim().isNotEmpty) {
                    _ask(_input.text.trim());
                    _input.clear();
                  }
                },
              ),
            ]),
          ),
        ]),
      );
}