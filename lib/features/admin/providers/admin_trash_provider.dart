import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Deleted things, kept until they expire.
///
/// The client asked for a trash rather than anything permanent, so the
/// editors mark a row closed or archived and the original lands here with
/// the whole record in `entity_data` — enough to put it back.
final adminTrashListProvider =
    StateNotifierProvider<
      AdminTrashNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminTrashNotifier();
    });

class AdminTrashNotifier extends AdminTableNotifier {
  AdminTrashNotifier()
    : super(
        table: 'trash',
        searchColumns: const [],
        orderBy: 'deleted_at',
        hasStatus: false,
      );

  String? _entityType;

  void setEntityFilter(String? type) {
    _entityType = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final type = _entityType;
    if (type == null || type.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) => r['entity_type'] == type).toList(),
      );
    });
  }

  /// Writes the stored record back into its own table, then drops the entry.
  Future<void> restore(String id) async {
    final client = SupabaseConfig.client;
    final row = await client
        .from('trash')
        .select('entity_type, entity_data')
        .eq('id', id)
        .single();

    final table = row['entity_type'] as String?;
    final data = row['entity_data'];
    if (table == null || data is! Map) return;

    await client.from(table).upsert(Map<String, dynamic>.from(data));
    await client.from('trash').delete().eq('id', id);
    await load();
  }

  Future<void> permanentDelete(String id) async {
    await SupabaseConfig.client.from('trash').delete().eq('id', id);
    await load();
  }

  /// How long a row has left. The screen warns when it is nearly gone.
  int daysUntilExpiry(String expiresAt) {
    final exp = DateTime.tryParse(expiresAt);
    if (exp == null) return 0;
    return exp.difference(DateTime.now()).inDays;
  }

  Future<void> emptyTrash() async {
    // A delete needs a filter, and everything has an id, so this matches all.
    await SupabaseConfig.client.from('trash').delete().neq('id', '');
    await load();
  }
}
