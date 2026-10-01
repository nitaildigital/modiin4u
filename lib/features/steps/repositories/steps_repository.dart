import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/step_entry.dart';

/// Reads and writes `daily_steps`, and asks the database for the rankings.
///
/// A leaderboard cannot be a plain select: the policy on `daily_steps` is
/// own-rows-only, which is right — one resident has no business reading
/// another's day. The two `steps_leaderboard_*` functions from migration
/// 00022 return the totals instead, and only for people who turned the
/// health-data switch on.
class StepsRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Records day totals, `{'yyyy-mm-dd': steps}`.
  ///
  /// Through `record_daily_steps` (00041), which keeps the higher of what is
  /// stored and what is sent. The counter can restart lower — a reboot, a
  /// reinstall, a phone that lost its health permission — and a day already
  /// recorded must not shrink, least of all in a group's ranking.
  Future<void> recordDays(Map<String, int> days) async {
    if (_client.auth.currentUser == null || days.isEmpty) return;
    await _client.rpc('record_daily_steps', params: {
      'p_days': [
        for (final e in days.entries)
          if (e.value > 0) {'date': e.key, 'steps': e.value},
      ],
    });
  }

  /// This person's last seven days.
  Future<List<StepEntry>> fetchMyWeek() => fetchMyDays(7);

  /// This person's last [days] days, oldest first, with the missing days
  /// filled in at zero so the chart has a bar for every day rather than a
  /// gap.
  Future<List<StepEntry>> fetchMyDays(int days) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final from = DateTime.now().subtract(Duration(days: days - 1));
    final rows = await _client
        .from('daily_steps')
        .select('date, steps')
        .eq('profile_id', uid)
        .gte('date', _asDate(from))
        .order('date', ascending: true);

    final byDate = {
      for (final r in List<Map<String, dynamic>>.from(rows))
        (r['date'] as String): (r['steps'] as num).toInt(),
    };

    return [
      for (var i = 0; i < days; i++)
        () {
          final day = from.add(Duration(days: i));
          return StepEntry(date: day, steps: byDate[_asDate(day)] ?? 0);
        }(),
    ];
  }

  Future<List<PersonRanking>> fetchPeopleLeaderboard({int days = 7}) async {
    final rows = await _client.rpc(
      'steps_leaderboard_people',
      params: {'days': days, 'limit_count': 20},
    );
    return List<Map<String, dynamic>>.from(
      rows ?? const [],
    ).map(PersonRanking.fromJson).toList();
  }

  Future<List<NeighborhoodRanking>> fetchNeighborhoodLeaderboard({
    int days = 7,
  }) async {
    final rows = await _client.rpc(
      'steps_leaderboard_neighborhoods',
      params: {'days': days, 'limit_count': 20},
    );
    return List<Map<String, dynamic>>.from(
      rows ?? const [],
    ).map(NeighborhoodRanking.fromJson).toList();
  }

  static String _asDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
