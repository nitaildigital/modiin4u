import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Light or dark, kept on the device like the language (`locale_provider`):
/// the Settings switch used to be forgotten at the next launch.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'app_theme_dark';

  ThemeModeNotifier() : super(ThemeMode.light) {
    _restore();
  }

  /// Set once the switch is used in this run, so the saved value — read a
  /// moment after start — does not overwrite it.
  bool _chosen = false;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dark = prefs.getBool(_key);
      if (dark == null || _chosen) return;
      if (mounted) state = dark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Unreadable storage leaves the light theme in place.
    }
  }

  void toggle() {
    setMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  void setMode(ThemeMode mode) {
    _chosen = true;
    state = mode;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_key, mode == ThemeMode.dark))
        .catchError((_) => false);
  }
}
