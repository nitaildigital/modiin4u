import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart' show GoRouter;

import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/push/push_host.dart';
import 'features/auth/providers/auth_provider.dart';
import 'l10n/app_localizations.dart';
import 'shared/page_title/page_title.dart';
import 'shared/web_asset_precache.dart';
import 'core/providers/content_language.dart';
import 'core/providers/resume_refresh.dart';
import 'core/update/force_update.dart';
import 'shared/widgets/web_chrome.dart' show restoreWebLanguage, webIsHebrew;

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

  // The screens open one another with `push`, which go_router by default
  // keeps out of the address bar: a visitor on a deal still saw /deals, and
  // a refresh or a copied link took them back to the list. With this the
  // address follows the page, as a website's should.
  GoRouter.optionURLReflectsImperativeAPIs = true;

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
  final container = ProviderContainer();
  // Businesses' and categories' names follow the language on screen
  // (content_language.dart).
  bool appEnglish() => container.read(localeProvider).languageCode == 'en';
  setContentLanguage(
    kIsWeb
        ? () {
            final view = PlatformDispatcher.instance.views.first;
            final width = view.physicalSize.width / view.devicePixelRatio;
            return width > 1100 ? !webIsHebrew.value : appEnglish();
          }
        : appEnglish,
  );
  if (kIsWeb) {
    final languageChosen = await restoreWebLanguage();
    _linkWebLanguage(container, languageChosen: languageChosen);
    await pictures.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
  }
  if (kIsWeb) _keepServedTitle();
  runApp(UncontrolledProviderScope(container: container, child: const Modiin4uApp()));
}

/// One language for the whole website.
///
/// It is kept in two places: [webIsHebrew], which the navbar's switch writes
/// and the desktop pages read, and [localeProvider], which the phone-width
/// pages, the ☰ menu and Flutter's own widgets read, and which the Change
/// Language page writes. Each switch wrote only its own, so choosing English
/// left the other half of the site in Hebrew. Now each follows the other.
///
/// A reader who has not chosen yet keeps the defaults as they were — the
/// desktop pages in English, the phone-width ones in Hebrew; once they
/// choose, the choice they saved wins over the app's.
void _linkWebLanguage(ProviderContainer container, {required bool languageChosen}) {
  void follow(bool hebrew) {
    final code = hebrew ? 'he' : 'en';
    if (container.read(localeProvider).languageCode == code) return;
    container.read(localeProvider.notifier).setLocale(supportedLocales.firstWhere((l) => l.languageCode == code));
  }

  webIsHebrew.addListener(() => follow(webIsHebrew.value));
  container.listen<Locale>(localeProvider, (_, next) => webIsHebrew.value = next.languageCode == 'he');
  if (languageChosen) follow(webIsHebrew.value);
}

/// The title the website's page was served with, while the visitor is still
/// on that page; null in the app and once they move on.
///
/// Each address is served with its own <title> (tool/build_seo_pages.py) —
/// the article's SEO title, the business's — and Flutter replaces the
/// document's title with whatever the app gives it. Given the app's name,
/// every page would be called the same in the version Google renders. So the
/// served title stands until the address changes, and the app's name after.
final _servedTitle = ValueNotifier<String?>(null);

void _keepServedTitle() {
  final title = servedPageTitle();
  if (title == null || title.trim().isEmpty) return;
  _servedTitle.value = title;
  String page(Uri uri) {
    final path = Uri.decodeFull(uri.path);
    return path.length > 1 && path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  final arrivedAt = page(Uri.base);
  void onRoute() {
    final now = appRouter.routerDelegate.currentConfiguration.uri;
    if (page(now) != arrivedAt) {
      _servedTitle.value = null;
      appRouter.routerDelegate.removeListener(onRoute);
    }
  }

  appRouter.routerDelegate.addListener(onRoute);
}

class Modiin4uApp extends ConsumerWidget {
  const Modiin4uApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    // Following a reset link signs the person in, so without this the app
    // would open as normal and the password they had forgotten would still be
    // the one on the account.
    ref.listen<bool>(passwordResetPendingProvider, (_, pending) {
      if (pending) appRouter.go('/reset-password');
    });

    return ValueListenableBuilder<String?>(
      valueListenable: _servedTitle,
      builder: (context, served, _) => MaterialApp.router(
        // The name in the recent-apps screen and the browser tab, in the
        // language chosen; a fixed Hebrew title stayed Hebrew in English. On
        // the website, the page's own title while the visitor is on it.
        onGenerateTitle: (context) => served ?? L.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Light only. The screens are drawn to the light designs with their
        // own colours, so a dark theme turned only a few parts dark; the
        // switch is gone until there is a dark design (8 Oct), and a dark
        // choice saved before is not applied.
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
        // Push notifications: taps open their page, and one that arrives
        // while the app is open shows as a banner over it. Outermost, the
        // update the panel can require: a build too old shows nothing else.
        builder: (context, child) => ForceUpdateGate(
          child: ResumeRefresh(
            child: PushHost(child: child ?? const SizedBox.shrink()),
          ),
        ),

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
          // The panel's article editor (flutter_quill) reads its own words.
          FlutterQuillLocalizations.delegate,
        ],
      ),
    );
  }
}
