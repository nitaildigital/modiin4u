import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/step_entry.dart';
import '../services/health_steps.dart' show DayActivity;

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

  /// Records a competition's figures, `{'yyyy-mm-dd': steps and distance
  /// inside its hours}`, through `record_challenge_steps` (00088): it takes
  /// nothing before the start or once the competition is over, keeps each
  /// date's highest, and ignores dates outside it.
  Future<void> recordChallengeDays(
    String challengeId,
    Map<String, DayActivity> days,
  ) async {
    if (_client.auth.currentUser == null || days.isEmpty) return;
    await _client.rpc('record_challenge_steps', params: {
      'p_challenge': challengeId,
      'p_days': [
        for (final e in days.entries)
          if (e.value.steps > 0)
            {
              'date': e.key,
              'steps': e.value.steps,
              if (e.value.metres != null) 'metres': e.value.metres,
            },
      ],
    });
  }

  /// The competitions this phone should be counting: started, switched on,
  /// and not over for more than two hours — the time the database still
  /// takes their last figures (00088). More than one when one ended just as
  /// the next began.
  Future<List<Map<String, dynamic>>> fetchCountingChallenges() async {
    final now = DateTime.now().toUtc();
    final rows = await _client
        .from('challenges')
        .select('id, start_at, end_at, goal, goal_per_day')
        .eq('is_active', true)
        .eq('challenge_type', 'steps')
        .lte('start_at', now.toIso8601String())
        .gte('end_at', now.subtract(const Duration(hours: 2)).toIso8601String())
        .order('start_at', ascending: false)
        .limit(3);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// This person's saved figures in a competition, by date.
  Future<Map<String, int>> fetchMyChallengeDays(String challengeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const {};
    final rows = await _client
        .from('challenge_steps')
        .select('date, steps')
        .eq('challenge_id', challengeId)
        .eq('profile_id', uid);
    return {
      for (final r in List<Map<String, dynamic>>.from(rows))
        (r['date'] as String): (r['steps'] as num).toInt(),
    };
  }

  /// A running competition's ranking, counted only inside its hours.
  Future<List<PersonRanking>> fetchChallengePeople(String challengeId) async {
    final rows = await _client.rpc(
      'challenge_leaderboard_people',
      params: {'p_challenge': challengeId, 'limit_count': 20},
    );
    return List<Map<String, dynamic>>.from(
      rows ?? const [],
    ).map(PersonRanking.fromJson).toList();
  }

  Future<List<NeighborhoodRanking>> fetchChallengeNeighborhoods(
    String challengeId,
  ) async {
    final rows = await _client.rpc(
      'challenge_leaderboard_neighborhoods',
      params: {'p_challenge': challengeId, 'limit_count': 20},
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
