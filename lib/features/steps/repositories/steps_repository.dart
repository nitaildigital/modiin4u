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

  /// Records today's count.
  ///
  /// Upserted on `(profile_id, date)` so the sensor can report repeatedly
  /// through the day and the row is corrected rather than duplicated.
  Future<void> recordToday(int steps) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client.from('daily_steps').upsert({
      'profile_id': uid,
      'date': _today(),
      'steps': steps,
    }, onConflict: 'profile_id,date');
  }

  /// This person's last [days] days, oldest first, with the missing days
  /// filled in at zero so the chart has a bar for every day rather than a
  /// gap.
  Future<List<StepEntry>> fetchMyWeek({int days = 7}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final from = DateTime.now().subtract(Duration(days: days - 1));
    final rows = await _client
        .from('daily_steps')
        .select('date, steps')
        .eq('profile_id', uid)
        .gte('date', _asDate(from))
        .order('date');

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

  static String _today() => _asDate(DateTime.now());

  static String _asDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
