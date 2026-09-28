import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'l10n/app_localizations.dart';
import 'shared/web_asset_precache.dart';
import 'shared/widgets/web_chrome.dart' show restoreWebLanguage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Real paths on the web rather than `/#/…`.
  //
  // Without this, `AUTH_REDIRECT_URL` — https://app.modiin4u.co.il/auth/callback
  // — cannot work: the browser would fetch that path, the server would hand
  // back index.html, and go_router would then read an empty hash and land on
  // the home screen instead of the callback. Someone confirming their
  // address would be shown the home page with no word that it worked.
  //
  // It also means the server must serve index.html for any unknown path;
  // see deploy/nginx/app.modiin4u.co.il.conf.
  usePathUrlStrategy();

  // The website's pictures start downloading now, alongside the database
  // connection, and the first page waits a moment for the few it shows — so
  // it opens whole rather than filling in. Never more than a second and a
  // half: a slow picture must not hold the site back.
  final pictures = precacheWebAssets();

  try {
    await SupabaseConfig.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('⚠️ Supabase init failed/timed out: $e');
  }
  if (kIsWeb) {
    await restoreWebLanguage();
    await pictures.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
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
