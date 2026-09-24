import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'l10n/app_localizations.dart';

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
    final locale = ref.watch(localeProvider);

    // Following a reset link signs the person in, so without this the app
    // would open as normal and the password they had forgotten would still be
    // the one on the account.
    ref.listen<bool>(passwordResetPendingProvider, (_, pending) {
      if (pending) appRouter.go('/reset-password');
    });

    return MaterialApp.router(
      title: 'מודיעין בשבילך',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,

      // ─── Language ───
      //
      // Hebrew by default, English on request, and the direction follows: the
      // framework lays the app out right to left for Hebrew and left to right
      // for English on its own, so nothing has to force it per screen.
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
