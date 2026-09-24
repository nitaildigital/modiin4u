import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_entry.dart';
import '../repositories/steps_repository.dart';

final stepsRepositoryProvider = Provider<StepsRepository>(
  (ref) => StepsRepository(),
);

/// What the counter knows right now.
enum StepPermission { unknown, granted, denied, unsupported }

class StepState {
  /// Steps taken today, or null before the first reading arrives.
  final int? today;
  final StepPermission permission;

  const StepState({this.today, this.permission = StepPermission.unknown});

  StepState copyWith({int? today, StepPermission? permission}) => StepState(
    today: today ?? this.today,
    permission: permission ?? this.permission,
  );
}

/// Today's steps, from the phone's own counter.
///
/// The screen used to show a fixed number with a fixed weekly chart beside
/// it. This reads the pedometer, and says plainly when it cannot.
///
/// The sensor reports steps since the phone last rebooted, not since
/// midnight, so the first reading of the day is kept as a baseline and
/// today's figure is the difference. The baseline is re-established whenever
/// the reading drops below it, which is what a reboot looks like.
class StepCounter extends StateNotifier<StepState> {
  StepCounter(this._ref) : super(const StepState()) {
    _start();
  }

  final Ref _ref;
  StreamSubscription<StepCount>? _sub;
  int? _baseline;
  DateTime? _baselineDay;
  Timer? _saveTimer;

  Future<void> _start() async {
    // The pedometer is a phone sensor; there is nothing to read on the web.
    if (kIsWeb) {
      state = state.copyWith(permission: StepPermission.unsupported);
      return;
    }

    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      state = state.copyWith(permission: StepPermission.denied);
      return;
    }
    state = state.copyWith(permission: StepPermission.granted);

    _sub = Pedometer.stepCountStream.listen(
      _onReading,
      onError: (_) =>
          state = state.copyWith(permission: StepPermission.unsupported),
      cancelOnError: false,
    );
  }

  void _onReading(StepCount reading) {
    final today = DateTime.now();
    final isNewDay =
        _baselineDay == null ||
        _baselineDay!.day != today.day ||
        _baselineDay!.month != today.month ||
        _baselineDay!.year != today.year;

    // A count lower than the baseline means the phone restarted and the
    // sensor began again from zero.
    if (isNewDay || _baseline == null || reading.steps < _baseline!) {
      _baseline = reading.steps;
      _baselineDay = today;
    }

    final steps = reading.steps - _baseline!;
    state = state.copyWith(today: steps);

    // The sensor fires often; writing on every reading would be a request per
    // step. This saves at most once a minute.
    _saveTimer ??= Timer(const Duration(minutes: 1), () {
      _saveTimer = null;
      final value = state.today;
      if (value != null && value > 0) {
        _ref.read(stepsRepositoryProvider).recordToday(value);
        _ref.invalidate(myStepWeekProvider);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}

final stepCounterProvider = StateNotifierProvider<StepCounter, StepState>(
  StepCounter.new,
);

/// This person's last seven days.
final myStepWeekProvider = FutureProvider<List<StepEntry>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const [];
  return ref.watch(stepsRepositoryProvider).fetchMyWeek();
});

/// The city ranking. Empty when signed out — the functions are only granted
/// to signed-in callers, because these are other people's figures.
final peopleLeaderboardProvider = FutureProvider<List<PersonRanking>>((
  ref,
) async {
  final user = ref.watch(authProvider);
  if (user == null) return const [];
  return ref.watch(stepsRepositoryProvider).fetchPeopleLeaderboard();
});

final neighborhoodLeaderboardProvider =
    FutureProvider<List<NeighborhoodRanking>>((ref) async {
      final user = ref.watch(authProvider);
      if (user == null) return const [];
      return ref.watch(stepsRepositoryProvider).fetchNeighborhoodLeaderboard();
    });

/// The challenge running now, if there is one.
///
/// The screen carried a fixed "MODIIN MONTHLY CHALLENGE — walk 150,000
/// steps" with a fixed progress bar. `challenges` is empty, so the section
/// is hidden rather than showing a challenge nobody set.
final activeChallengeProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final now = DateTime.now().toIso8601String();
  final rows = await SupabaseConfig.client
      .from('challenges')
      .select('*, challenge_participants(progress, completed)')
      .eq('is_active', true)
      .lte('start_at', now)
      .gte('end_at', now)
      .order('start_at', ascending: false)
      .limit(1);
  final list = List<Map<String, dynamic>>.from(rows);
  return list.isEmpty ? null : list.first;
});
