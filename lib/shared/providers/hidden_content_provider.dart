import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiddenContentNotifier extends StateNotifier<Set<String>> {
  HiddenContentNotifier() : super(<String>{}) {
    _load();
  }

  static const _prefKey = 'hidden_content_ids';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      state = list.toSet();
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
