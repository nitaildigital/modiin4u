import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The people this resident has blocked, by profile id, each with the name
/// shown when they were blocked — so Profile → Blocked users can say who
/// they are without asking the database.
///
/// Apple's guideline 1.2 asks that blocking take the person's content out of
/// the feed at once; the Terms (13.4–13.5) promise the same. Kept on the
/// device, like reported content hidden from view (hidden_content_provider),
/// so it works the moment it is tapped. The team hears of every block
/// through a report on the person (block_user.dart).
class BlockedUsersNotifier extends StateNotifier<Map<String, String>> {
  BlockedUsersNotifier() : super(const {}) {
    _load();
  }

  static const _prefKey = 'blocked_users';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      state = Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(state));
    } catch (_) {}
  }

  Future<void> block(String userId, String name) async {
    if (userId.isEmpty) return;
    state = {...state, userId: name};
    await _save();
  }

  Future<void> unblock(String userId) async {
    state = {...state}..remove(userId);
    await _save();
  }
}

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, Map<String, String>>((ref) {
  return BlockedUsersNotifier();
});
