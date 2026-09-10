import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';

/// ⚙️ Appearance control (Settings থেকে পরিবর্তন হয়)
class ThemeController {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const EnjoyApp());
}

class EnjoyApp extends StatelessWidget {
  const EnjoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, __) => MaterialApp.router(
        title: 'ENJOY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: AppRouter.router,
      ),
    );
  }
}