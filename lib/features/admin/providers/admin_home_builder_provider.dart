import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// The rows on the home screen, in the order they appear.
///
/// The app does not read these yet — its rows are fixed in the screen — but
/// the table is what will decide them, and the client can already arrange it.
final adminHomeBuilderProvider =
    StateNotifierProvider<
      AdminHomeBuilderNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminHomeBuilderNotifier();
    });

class AdminHomeBuilderNotifier extends AdminTableNotifier {
  AdminHomeBuilderNotifier()
    : super(
        table: 'home_blocks',
        searchColumns: const ['title', 'block_type'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  Future<void> createBlock(Map<String, dynamic> b) => create(b);
  Future<void> updateBlock(String id, Map<String, dynamic> f) => update(id, f);
  Future<void> deleteBlock(String id) => setActive(id, false);

  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (b) => b['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }

  /// Moves one block to a new position and renumbers the rest, because the
  /// order is a column rather than the row's place in the list.
  Future<void> reorder(String id, int newOrder) async {
    final rows = [...(state.valueOrNull ?? const <Map<String, dynamic>>[])];
    final from = rows.indexWhere((b) => b['id'] == id);
    if (from == -1) return;

    final moved = rows.removeAt(from);
    rows.insert(newOrder.clamp(0, rows.length), moved);

    final client = SupabaseConfig.client;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['sort_order'] == i) continue;
      await client
          .from('home_blocks')
          .update({'sort_order': i})
          .eq('id', rows[i]['id'] as String);
    }
    await load();
  }

  /// Makes the current arrangement the one the app reads.
  ///
  /// Blocks are edited as drafts and only take effect once published, so the
  /// home screen never shows a half-finished arrangement.
  Future<void> publishAll() async {
    final now = DateTime.now().toIso8601String();
    await SupabaseConfig.client
        .from('home_blocks')
        .update({'published': true, 'published_at': now})
        .eq('is_active', true);
    await load();
  }
}
