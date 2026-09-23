import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Tags, on the live table — 71 of them came across with the news import.
final adminTagListProvider =
    StateNotifierProvider<
      AdminTagListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminTagListNotifier();
    });

class AdminTagListNotifier extends AdminTableNotifier {
  AdminTagListNotifier()
    : super(
        table: 'tags',
        searchColumns: const ['name', 'slug'],
        orderBy: 'name',
        ascending: true,
        hasStatus: false,
      );

  void setSortBy(String? column) {
    _sortBy = column;
    load();
  }

  String? _sortBy;

  @override
  Future<void> load() async {
    await super.load();
    final by = _sortBy;
    if (by == null || by.isEmpty) return;

    state.whenData((rows) {
      final sorted = [...rows]..sort((a, b) {
        final x = a[by], y = b[by];
        if (x is num && y is num) return y.compareTo(x);
        return '$x'.compareTo('$y');
      });
      state = AsyncValue.data(sorted);
    });
  }

  Future<void> createTag(Map<String, dynamic> t) => create(t);
  Future<void> updateTag(String id, Map<String, dynamic> f) => update(id, f);
  Future<void> deleteTag(String id) => remove(id);

  /// Points everything tagged [from] at [to], then removes the empty tag.
  ///
  /// The import produced near-duplicates — the same subject written two ways —
  /// so merging is the repair for that rather than deleting one and losing
  /// what it was attached to.
  Future<void> mergeTags(String from, String to) async {
    final client = SupabaseConfig.client;

    final existing = await client
        .from('entity_tags')
        .select('entity_type, entity_id')
        .eq('tag_id', to);
    final already = {
      for (final r in List<Map<String, dynamic>>.from(existing))
        '${r['entity_type']}:${r['entity_id']}',
    };

    final moving = await client
        .from('entity_tags')
        .select('entity_type, entity_id')
        .eq('tag_id', from);

    final rows = [
      for (final r in List<Map<String, dynamic>>.from(moving))
        if (!already.contains('${r['entity_type']}:${r['entity_id']}'))
          {
            'entity_type': r['entity_type'],
            'entity_id': r['entity_id'],
            'tag_id': to,
          },
    ];
    if (rows.isNotEmpty) await client.from('entity_tags').insert(rows);

    await client.from('entity_tags').delete().eq('tag_id', from);
    await client.from('tags').delete().eq('id', from);
    await load();
  }
}
