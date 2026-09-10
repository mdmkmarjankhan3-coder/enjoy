import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy/core/routing/app_router.dart';
import 'package:enjoy/core/theme/app_theme.dart';
import 'package:enjoy/services/ai_service.dart';

void main() {
  testWidgets('ENJOY app renders splash screen', (tester) async {
    await tester.pumpWidget(MaterialApp.router(
      title: 'ENJOY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    ));
    expect(find.text('One App • One Account • One Ecosystem'), findsOneWidget);
  });

  test('AI local fallback responds', () async {
    final r = await AiService.ask('ভিডিওর জন্য title suggestion দাও');
    expect(r.isNotEmpty, true);
  });

  test('AI game idea produces config', () {
    final cfg = AiService.gameIdea('fast space game');
    expect(cfg.containsKey('speed'), true);
    expect(cfg.containsKey('reward'), true);
  });
}