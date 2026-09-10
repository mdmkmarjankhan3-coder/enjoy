import 'package:flutter/material.dart';
import '../../../../services/ai_service.dart';

/// 🤖 AI Button (প্ল্যান: shared component)
class AiButton extends StatelessWidget {
  const AiButton({super.key, required this.onPressed, this.label = '🤖 AI'});
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(Icons.smart_toy, size: 18),
        label: Text(label),
      );
}

/// 💬 AI Chat Sheet — সব জায়গা থেকে call করা যায়
void showAiChatSheet(BuildContext context, {String? contextText}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AiChatSheet(contextText: contextText),
  );
}

class AiChatSheet extends StatefulWidget {
  const AiChatSheet({super.key, this.contextText});
  final String? contextText;

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final _input = TextEditingController();
  final List<Map<String, String>> _chat = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.contextText != null) _ask(widget.contextText!);
  }

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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(children: [
          const ListTile(
            leading: Icon(Icons.smart_toy),
            title: Text('🤖 ENJOY AI'),
            subtitle: Text('Optional — আপনার সহকারী'),
          ),
          const Divider(height: 1),
          AiSuggestionChips(onSelect: _ask),
          Expanded(
            child: ListView.builder(
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
                  decoration: const InputDecoration(hintText: 'AI-কে জিজ্ঞেস করুন…'),
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
      ),
    );
  }
}

/// 💡 AI Suggestions
class AiSuggestionChips extends StatelessWidget {
  const AiSuggestionChips({super.key, required this.onSelect});
  final void Function(String) onSelect;

  static const _suggestions = [
    'ভিডিওর জন্য title suggestion দাও',
    'Tag কিভাবে দেবো?',
    'এই topic বুঝিয়ে দাও',
    'Game idea দাও',
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final s in _suggestions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  label: Text(s),
                  onPressed: () => onSelect(s),
                ),
              ),
          ],
        ),
      );
}

/// 📄 AI Result Card
class AiResultCard extends StatelessWidget {
  const AiResultCard({super.key, required this.text, this.isUser = false});
  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}

/// ⏳ AI Loading
class AiLoadingDots extends StatelessWidget {
  const AiLoadingDots({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('🤖 ENJOY AI ভাবছে…'),
        ]),
      );
}