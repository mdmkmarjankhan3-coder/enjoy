import 'package:flutter/material.dart';
import '../../../services/content_service.dart';
import '../../../services/fnf_service.dart';
import '../../../services/monetization_service.dart';

class CreatorStudioPage extends StatelessWidget {
  const CreatorStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🎨 Creator Studio'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Content'), Tab(text: 'Drafts'), Tab(text: 'Analytics'),
            Tab(text: 'Audience'), Tab(text: 'Monetization'),
          ]),
        ),
        body: const TabBarView(children: [
          _ContentList(status: 'published'),
          _ContentList(status: 'draft'),
          _Analytics(),
          _Audience(),
          _Monetization(),
        ]),
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  const _ContentList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: ContentService.videos.mine(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.where((v) => v['status'] == status).toList();
          if (items.isEmpty) {
            return Center(child: Text('কোনো $status content নেই'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final v = items[i];
              int c(String k) =>
                  ((v[k] as List?)?.first as Map?)?['count'] ?? 0;
              return ListTile(
                leading: const Icon(Icons.video_library),
                title: Text(v['title'] ?? ''),
                subtitle: Text('👁 ${c('views')}  ❤️ ${c('likes')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ContentService.videos.remove(v['id']),
                ),
              );
            },
          );
        },
      );
}

class _Analytics extends StatelessWidget {
  const _Analytics();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: ContentService.videos.mine(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          int total(String k) => snap.data!.fold<int>(
                0,
                (a, v) => a +
                    ((((v[k] as List?)?.first as Map?)?['count']) as int? ??
                        0),
              );
          return ListView(children: [
            _stat('Total Videos', '${snap.data!.length}'),
            _stat('Total Views', '${total('views')}'),
            _stat('Total Likes', '${total('likes')}'),
          ]);
        },
      );

  Widget _stat(String t, String v) => ListTile(
      leading: const Icon(Icons.insights), title: Text(t), trailing: Text(v));
}

class _Audience extends StatelessWidget {
  const _Audience();

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: FnfService.myFriends(),
        builder: (_, snap) => ListView(children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('FNF (Audience)'),
            trailing: Text('${snap.data?.length ?? 0}'),
          ),
        ]),
      );
}

/// 💰 Monetization (প্ল্যান ২৫: Eligibility → Review → Approval)
class _Monetization extends StatefulWidget {
  const _Monetization();

  @override
  State<_Monetization> createState() => _MonetizationState();
}

class _MonetizationState extends State<_Monetization> {
  late Future<Map<String, dynamic>> _elig = MonetizationService.eligibility();
  late Future<Map<String, dynamic>?> _status = MonetizationService.status();
  late Future<double> _balance = MonetizationService.availableBalance();
  late Future<List<Map<String, dynamic>>> _earnings =
      MonetizationService.earnings();

  void _refresh() => setState(() {
        _elig = MonetizationService.eligibility();
        _status = MonetizationService.status();
        _balance = MonetizationService.availableBalance();
        _earnings = MonetizationService.earnings();
      });

  @override
  Widget build(BuildContext context) => ListView(children: [
        FutureBuilder<double>(
          future: _balance,
          builder: (_, b) => Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Available Balance'),
              trailing: Text('৳${b.data ?? 0}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        FutureBuilder<Map<String, dynamic>?>(
          future: _status,
          builder: (_, s) {
            final st = s.data;
            if (st == null) return const SizedBox();
            final color = st['status'] == 'approved'
                ? Colors.green
                : st['status'] == 'rejected'
                    ? Colors.red
                    : Colors.orange;
            return ListTile(
              leading: Icon(Icons.verified, color: color),
              title: Text('Status: ${st['status']}'.toUpperCase()),
              subtitle: st['review_note'] != null
                  ? Text(st['review_note'])
                  : const Text('ENJOY review চলছে…'),
            );
          },
        ),
        const Divider(),
        const ListTile(title: Text('📋 Eligibility Conditions')),
        FutureBuilder<Map<String, dynamic>>(
          future: _elig,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final checks =
                snap.data!['checks'] as Map<String, bool>;
            return Column(children: [
              for (final e in checks.entries)
                ListTile(
                  dense: true,
                  leading: Icon(
                    e.value ? Icons.check_circle : Icons.cancel,
                    color: e.value ? Colors.green : Colors.red,
                  ),
                  title: Text(e.key),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: snap.data!['meets'] == true
                      ? () async {
                          await MonetizationService.apply(null);
                          _refresh();
                        }
                      : null,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Apply for Monetization'),
                ),
              ),
            ]);
          },
        ),
        const Divider(),
        const ListTile(title: Text('💳 Earnings')),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _earnings,
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('কোনো earning নেই এখনো')),
              );
            }
            return Column(children: [
              for (final e in snap.data!)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.payments),
                  title: Text(e['source_type'] ?? ''),
                  subtitle: Text('${e['status']}'.toUpperCase()),
                  trailing: Text('৳${e['amount']}'),
                ),
            ]);
          },
        ),
      ]);
}