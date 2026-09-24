import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Step challenges, on the live table.
///
/// The Step Counter screen reads `challenges` and shows the one running now.
/// Nothing could create one — there was no section for this table — so the
/// card was permanently hidden and the feature could never be used. This is
/// the form that fills it.
final adminChallengeListProvider =
    StateNotifierProvider<
      AdminChallengeListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminChallengeListNotifier();
    });

class AdminChallengeListNotifier extends AdminTableNotifier {
  AdminChallengeListNotifier()
    : super(
        table: 'challenges',
        searchColumns: const ['name', 'description'],
        orderBy: 'start_at',
        ascending: false,
        // `challenges` has `is_active`, not a `status` column.
        hasStatus: false,
      );

  /// 'active', 'inactive', or null for all.
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
            .where((r) => (r['is_active'] as bool? ?? false) == (f == 'active'))
            .toList(),
      );
    });
  }

  Future<void> createChallenge(Map<String, dynamic> c) => create(c);
  Future<void> updateChallenge(String id, Map<String, dynamic> f) =>
      update(id, f);
  Future<void> deleteChallenge(String id) => remove(id);
}

/// How many people have joined each challenge, keyed by challenge id.
///
/// Shown on the row so the client can see whether a challenge is being taken
/// up, rather than guessing.
final challengeParticipantCountsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('challenge_participants')
      .select('challenge_id');

  final counts = <String, int>{};
  for (final r in List<Map<String, dynamic>>.from(rows)) {
    final id = r['challenge_id'] as String?;
    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
});
