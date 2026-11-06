import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiddenContentNotifier extends StateNotifier<Set<String>> {
  HiddenContentNotifier() : super(<String>{}) {
    ready = _load();
  }

  static const _prefKey = 'hidden_content_ids';

  /// Done once the saved ids are read. `main` waits for it before the app
  /// starts, so the lists that leave hidden items out are fetched once.
  late final Future<void> ready;

  /// Sets the saved ids only when they differ. It set them always, a new
  /// set each time, and every list that watches them — businesses, all the
  /// articles, listings, jobs — dropped the fetch it had just started and
  /// sent it again, on every launch (6 Nov).
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList(_prefKey) ?? const <String>[]).toSet();
      if (mounted && !setEquals(saved, state)) state = saved;
    } catch (_) {}
  }

  Future<void> hide(String entityId) async {
    if (entityId.isEmpty) return;
    final next = {...state, entityId};
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, next.toList());
    } catch (_) {}
  }

  Future<void> unhide(String entityId) async {
    final next = {...state}..remove(entityId);
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, next.toList());
    } catch (_) {}
  }

  bool isHidden(String entityId) => state.contains(entityId);
}

final hiddenContentProvider =
    StateNotifierProvider<HiddenContentNotifier, Set<String>>((ref) {
  return HiddenContentNotifier();
});
