import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which language the app is in.
///
/// The client asked for Hebrew and English. Hebrew is the default because the
/// audience is local and the layout is right to left; English is the second
/// language rather than the first.
///
/// The choice is kept on the device rather than on the profile, so it holds
/// before anyone signs in — a resident who reads English should not have to
/// get through a Hebrew sign-in screen first.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

const supportedLocales = [Locale('he', 'IL'), Locale('en', 'US')];

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'app_locale';

  LocaleNotifier() : super(supportedLocales.first) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code == null) return;

      final saved = supportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => supportedLocales.first,
      );
      if (mounted) state = saved;
    } catch (_) {
      // Unreadable storage leaves the default in place rather than failing.
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {
      // The switch still takes effect for this run.
    }
  }

  bool get isHebrew => state.languageCode == 'he';

  Future<void> toggle() =>
      setLocale(isHebrew ? supportedLocales[1] : supportedLocales.first);
}
