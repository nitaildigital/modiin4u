import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Tags, on the live table — 71 of them came across with the site import.
///
/// **What a tag does today: nothing a visitor sees.** A tag reaches a
/// business or an article through `entity_tags`, which holds no rows, and no
/// screen in the app or on the website reads either table. So the list here
/// is the vocabulary and nothing more; the panel says so. Putting tags on
/// the site is a feature of its own and wants the client's go-ahead.
///
/// `usage_count` is not a column: it is counted from `entity_tags` on each
/// load, so "sort by use" sorts by something real (all zero today).
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
    final rows = state.valueOrNull;
    if (rows == null) return;

    final Map<String, int> usage;
    try {
      usage = await _usageCounts();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
      return;
    }
    if (!mounted) return;

    final counted = [
      for (final r in rows) {...r, 'usage_count': usage[r['id']] ?? 0},
    ];
    if (_sortBy == 'usage') {
      // Most used first; ties stay alphabetical.
      counted.sort((a, b) {
        final byUse = (b['usage_count'] as int).compareTo(
          a['usage_count'] as int,
        );
        if (byUse != 0) return byUse;
        return (a['name'] as String? ?? '').compareTo(
          b['name'] as String? ?? '',
        );
      });
    }
    state = AsyncValue.data(counted);
  }

  /// How many things carry each tag, from `entity_tags`.
  Future<Map<String, int>> _usageCounts() async {
    final links = await SupabaseConfig.client
        .from('entity_tags')
        .select('tag_id');
    final counts = <String, int>{};
    for (final l in List<Map<String, dynamic>>.from(links)) {
      final id = l['tag_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> createTag(Map<String, dynamic> t) => create(t);
  Future<void> updateTag(String id, Map<String, dynamic> f) => update(id, f);

  /// Removes the tag for good — the table has no hidden state — and with it
  /// its `entity_tags` links (the foreign key cascades). The screen shows
  /// how many there are before asking.
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
