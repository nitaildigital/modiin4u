import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('⚠️ Supabase init failed/timed out: $e');
  }
  runApp(const ProviderScope(child: Modiin4uApp()));
}

class Modiin4uApp extends ConsumerWidget {
  const Modiin4uApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'מודיעין בשבילך',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,

      // ─── Localization: Hebrew RTL globally ───
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'), // עברית — ברירת מחדל
        Locale('en', 'US'), // English fallback
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
