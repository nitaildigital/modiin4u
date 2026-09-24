import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Estate agents, on the live table.
///
/// A listing can be credited to one — `listings.agent_id` — and the listing
/// page shows the agent's name, agency, photograph and telephone number.
/// Nothing could create an agent, so that column could never be set and the
/// contact block never appeared for any listing the client entered.
final adminAgentListProvider =
    StateNotifierProvider<
      AdminAgentListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminAgentListNotifier();
    });

class AdminAgentListNotifier extends AdminTableNotifier {
  AdminAgentListNotifier()
    : super(
        table: 'real_estate_agents',
        searchColumns: const ['name', 'agency', 'phone', 'email'],
        orderBy: 'name',
        ascending: true,
        // `real_estate_agents` has `is_active`, not `status`.
        hasStatus: false,
      );

  String? _activeFilter;

  void setActiveFilter(String? filter) {
    _activeFilter = filter;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final f = _activeFilter;
    if (f == null || f.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows
            .where((r) => (r['is_active'] as bool? ?? true) == (f == 'active'))
            .toList(),
      );
    });
  }

  Future<void> createAgent(Map<String, dynamic> a) => create(a);
  Future<void> updateAgent(String id, Map<String, dynamic> f) => update(id, f);
  Future<void> deleteAgent(String id) => remove(id);
}

/// How many listings each agent is credited on, keyed by agent id.
///
/// Deleting an agent nulls the column rather than removing the listing, so
/// this is shown on the row to make clear what a deletion would detach.
final agentListingCountsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final rows = await SupabaseConfig.client.from('listings').select('agent_id');

  final counts = <String, int>{};
  for (final r in List<Map<String, dynamic>>.from(rows)) {
    final id = r['agent_id'] as String?;
    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
});
