import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/content_service.dart';
import '../../../services/fnf_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _users = [], _videos = [], _shorts = [];
  bool _searched = false;

  Future<void> _search(String q) async {
    final users = await FnfService.searchUsers(q);
    final vids = await ContentService.videos.feed();
    final shs = await ContentService.shorts.feed();
    setState(() {
      _users = users;
      _videos = vids.where((v) => (v['title'] ?? '').toString().contains(q)).toList();
      _shorts = shs.where((s) => (s['title'] ?? '').toString().contains(q)).toList();
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🔎 Search')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SearchBar(
              controller: _ctrl,
              hintText: 'Users, Videos, Shorts, Groups, Games…',
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: !_searched
                ? const Center(child: Text('একটি Unified Search — সব একসাথে'))
                : ListView(children: [
                    if (_users.isNotEmpty) const _Header('Users'),
                    ..._users.map((p) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(p['name'] ?? ''),
                          subtitle: Text('@${p['username'] ?? ''}'),
                        )),
                    if (_videos.isNotEmpty) const _Header('🎬 Videos'),
                    ..._videos.map((v) => ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(v['title'] ?? ''),
                          onTap: () => context.push('/video/${v['id']}'),
                        )),
                    if (_shorts.isNotEmpty) const _Header('📱 Shorts'),
                    ..._shorts.map((s) => ListTile(
                          leading: const Icon(Icons.smartphone),
                          title: Text(s['title'] ?? ''),
                          onTap: () => context.go('/shorts'),
                        )),
                    if (_users.isEmpty && _videos.isEmpty && _shorts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('কিছু পাওয়া যায়নি')),
                      ),
                  ]),
          ),
        ]),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}