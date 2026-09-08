import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy/core/routing/app_router.dart';
import 'package:enjoy/core/theme/app_theme.dart';

void main() {
  testWidgets('ENJOY app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        title: 'ENJOY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );

    expect(find.text('🌟 ENJOY'), findsOneWidget);
  });
}