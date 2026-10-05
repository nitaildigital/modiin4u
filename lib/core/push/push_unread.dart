import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_fonts.dart';
import 'push_feed.dart';

/// When this device last opened the bell. Anything sent after it is unread.
///
/// Kept on the device, like the rest of notifications. The first time the
/// app or the browser runs it is set to that moment, so a new device does not
/// open on a pile of "unread" from the weeks before it existed.
final pushSeenProvider = StateNotifierProvider<PushSeenNotifier, DateTime?>((
  ref,
) {
  return PushSeenNotifier();
});

class PushSeenNotifier extends StateNotifier<DateTime?> {
  static const _key = 'push_seen_at';

  PushSeenNotifier() : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = DateTime.tryParse(prefs.getString(_key) ?? '');
      if (!mounted || state != null) return;
      if (saved != null) {
        state = saved;
      } else {
        await markSeen();
      }
    } catch (_) {
      // Unreadable storage: nothing is counted unread rather than everything.
    }
  }

  /// The bell was opened: everything sent so far has been seen.
  Future<void> markSeen() async {
    final now = DateTime.now();
    state = now;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, now.toIso8601String());
    } catch (_) {}
  }
}

/// Notifications this device opened — from the tray, the banner or the
/// bell. One that was opened is not unread, though the bell was not visited.
/// The newest 200 are kept; older ones are long past the bell's 60 days.
final pushOpenedProvider =
    StateNotifierProvider<PushOpenedNotifier, Set<String>>((ref) {
      return PushOpenedNotifier();
    });

class PushOpenedNotifier extends StateNotifier<Set<String>> {
  static const _key = 'push_opened_ids';

  PushOpenedNotifier() : super(const {}) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key) ?? const [];
      if (mounted) state = {...saved, ...state};
    } catch (_) {}
  }

  Future<void> add(String campaignId) async {
    if (state.contains(campaignId)) return;
    final next = [...state, campaignId];
    state = next.skip(next.length > 200 ? next.length - 200 : 0).toSet();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.toList());
    } catch (_) {}
  }
}

/// Whether one notification counts as unread here: sent after the bell was
/// last opened, and not opened since.
bool isPushUnread(PushFeedItem item, DateTime? seen, Set<String> opened) =>
    seen != null && item.sentAt.isAfter(seen) && !opened.contains(item.id);

/// How many notifications in the bell this device has not seen yet.
final pushUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final seen = ref.watch(pushSeenProvider);
  final opened = ref.watch(pushOpenedProvider);
  final items = ref.watch(pushFeedProvider).valueOrNull ?? const [];
  return items.where((i) => isPushUnread(i, seen, opened)).length;
});

/// The unread count on its own, for a row that names the bell in words.
class PushCountPill extends StatelessWidget {
  final int count;
  const PushCountPill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// A red count over an icon, or nothing when [count] is 0. Over nine it
/// says 9+, so the badge stays a dot rather than a word.
class PushCountBadge extends StatelessWidget {
  final int count;
  final Widget child;

  /// Just a dot, for places too small for a number (the ☰).
  final bool dotOnly;

  const PushCountBadge({
    super.key,
    required this.count,
    required this.child,
    this.dotOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: dotOnly ? 0 : -6,
          end: dotOnly ? 0 : -8,
          child: dotOnly
              ? Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
