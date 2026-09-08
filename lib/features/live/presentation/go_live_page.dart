import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/live_service.dart';

class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});
  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final _title = TextEditingController();
  String _category = 'Entertainment';
  bool _busy = false;

  Future<void> _create() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final id = await LiveService.createStream(_title.text.trim(), _category);
    await LiveService.awardHostBadge();
    if (mounted) {
      context.go('/live/$id', extra: {'isHost': true});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🔴 Go Live')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Live Title *')),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const ['Entertainment', 'Gaming', 'Education', 'Music', 'Sports', 'News']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.podcasts),
            label: Text(_busy ? 'তৈরি হচ্ছে…' : 'Start Live Room'),
          ),
        ]),
      );
}