import 'package:flutter/material.dart';
import '../../../../services/content_service.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.service, required this.contentId});
  final ContentService service;
  final String contentId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future =
      widget.service.comments(widget.contentId);

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    await widget.service.addComment(widget.contentId, _ctrl.text.trim());
    _ctrl.clear();
    setState(() => _future = widget.service.comments(widget.contentId));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('💬 Comments', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  if (snap.data!.isEmpty) return const Center(child: Text('প্রথম comment করুন'));
                  return ListView.builder(
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) {
                      final c = snap.data![i];
                      final a = c['author'] as Map<String, dynamic>?;
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                        title: Text(a?['name'] ?? '',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(c['content'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Comment লিখুন…'),
                )),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ]),
            ),
          ]),
        ),
      );
}