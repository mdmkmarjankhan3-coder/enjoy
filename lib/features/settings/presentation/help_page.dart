import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _issues = {
    'Login হচ্ছে না': [
      'Check: Internet connection আছে কিনা',
      'Fix: Supabase Dashboard → Authentication → Google provider on আছে কিনা দেখুন',
      'Verify: আবার Continue with Google চাপুন',
    ],
    'Video upload হচ্ছে না': [
      'Check: Cloudinary cloud name ও upload preset ঠিক আছে কিনা',
      'Fix: Upload preset Unsigned হতে হবে',
      'Verify: ছোট ভিডিও দিয়ে আবার চেষ্টা করুন',
    ],
    'Chat message যাচ্ছে না': [
      'Check: Realtime — messages table replication on আছে কিনা',
      'Fix: Dashboard → Database → Replication → messages enable',
      'Verify: পেজ refresh করে আবার পাঠান',
    ],
    'Notification আসছে না': [
      'Check: notifications table replication on আছে কিনা',
      'Fix: Replication-এ notifications enable করুন',
      'Verify: নতুন FNF request পাঠিয়ে দেখুন',
    ],
    'Points/Level বাড়ছে না': [
      'Check: add_points function SQL-এ run হয়েছে কিনা',
      'Fix: SQL Editor-এ function আবার run করুন',
      'Verify: আবার কোনো activity করুন',
    ],
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🛠️ Help & Recovery')),
        body: ListView(children: [
          for (final e in _issues.entries)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ExpansionTile(
                leading: const Icon(Icons.healing),
                title: Text(e.key),
                children: [
                  for (var i = 0; i < e.value.length; i++)
                    ListTile(
                      dense: true,
                      leading: Icon(switch (i) {
                        0 => Icons.search,
                        1 => Icons.build,
                        _ => Icons.check_circle_outline,
                      }),
                      title: Text(e.value[i]),
                    ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'সমাধান না পেলে: Supabase Dashboard → Support এবং '
              'ENJOY app-এর Report feature ব্যবহার করুন।',
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      );
}