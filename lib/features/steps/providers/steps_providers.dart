import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_entry.dart';
import '../repositories/steps_repository.dart';
import '../services/health_steps.dart';

final stepsRepositoryProvider = Provider<StepsRepository>(
  (ref) => StepsRepository(),
);

/// What the phone's step sensor allows.
enum StepPermission { unknown, granted, denied, unsupported }

class StepState {
  /// Steps the sensor has counted today, or null before its first reading.
  final int? sensorToday;
  final StepPermission permission;
  final HealthAccess health;

  /// The last month from Health Connect or Apple Health, keyed by date.
  final Map<String, DayActivity> healthDays;

  const StepState({
    this.sensorToday,
    this.permission = StepPermission.unknown,
    this.health = HealthAccess.unavailable,
    this.healthDays = const {},
  });

  StepState copyWith({
    int? sensorToday,
    StepPermission? permission,
    HealthAccess? health,
    Map<String, DayActivity>? healthDays,
  }) => StepState(
    sensorToday: sensorToday ?? this.sensorToday,
    permission: permission ?? this.permission,
    health: health ?? this.health,
    healthDays: healthDays ?? this.healthDays,
  );

  DayActivity? get _healthToday => healthDays[dateKey(DateTime.now())];

  /// Today's steps: the health store's figure or the sensor's, whichever is
  /// higher — the sensor only counts while the app listens, the store may
  /// lag a few minutes behind the phone. Null while neither has reported.
  int? get today {
    final h = _healthToday?.steps;
    if (h == null) return sensorToday;
    if (sensorToday == null) return h;
    return h > sensorToday! ? h : sensorToday;
  }

  /// Measured distance and active calories, from the health store only.
  double? get todayMetres => _healthToday?.metres;
  double? get todayKcal => _healthToday?.kcal;

  /// Whether anything can count steps on this phone.
  bool get canCount =>
      health == HealthAccess.connected ||
      permission == StepPermission.granted ||
      permission == StepPermission.unknown;
}

/// Today's steps, from the phone's health store and its step sensor.
///
/// The health store (Health Connect, Apple Health) is read when the person
/// has allowed it: the whole day and the last month, with distance and
/// active calories. The sensor runs beside it for a count that moves while
/// the screen is open, and is all there is on a phone without the store.
///
/// The sensor reports steps since the phone last restarted, not since
/// midnight, so the first reading of the day is kept as a baseline and
/// today's figure is the difference. The baseline is kept on the phone, so
/// opening the app again later in the day carries on from it rather than
/// starting again at zero; and a reading below the last one — a restart —
/// carries what was counted so far.
///
/// What is counted goes to `daily_steps` (which keeps each day's highest
/// figure): today's at most once a minute while it changes, and the month
/// from the health store when it is read, so a group sees the morning walk
/// even if the app was opened only in the evening.
class StepCounter extends StateNotifier<StepState> {
  StepCounter(this._ref) : super(const StepState()) {
    _start();
  }

  final Ref _ref;
  // Late, so a browser — where there is no health store — never makes one.
  late final HealthSteps _healthSteps = HealthSteps();
  StreamSubscription<StepCount>? _sub;
  Timer? _tick;
  AppLifecycleListener? _lifecycle;
  SharedPreferences? _prefs;
  int? _lastUploaded;

  static const _kDay = 'steps_sensor_day';
  static const _kBase = 'steps_sensor_base';
  static const _kCarried = 'steps_sensor_carried';
  static const _kLast = 'steps_sensor_last';
  static const _kHealthAsked = 'steps_health_asked';

  /// The health store is read for this many days, the most Health Connect
  /// gives an app without the extra history permission.
  static const _healthDays = 30;

  Future<void> _start() async {
    // Neither the sensor nor the health store exists in a browser.
    if (kIsWeb) {
      state = state.copyWith(permission: StepPermission.unsupported);
      return;
    }
    _prefs = await SharedPreferences.getInstance();

    // Health first: on an iPhone it is the only reliable source, and its
    // permission screen should not race the sensor's.
    await refreshHealth(upload: true);
    await _startSensor();

    // A minute's tick saves today's count while it changes; coming back to
    // the app re-reads the health store, which went on counting meanwhile.
    _tick = Timer.periodic(const Duration(minutes: 1), (t) {
      if (t.tick % 5 == 0) refreshHealth();
      _uploadToday();
    });
    _lifecycle = AppLifecycleListener(onResume: () => refreshHealth());
  }

  Future<void> _startSensor() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      if (mounted) state = state.copyWith(permission: StepPermission.denied);
      return;
    }
    if (!mounted) return;
    state = state.copyWith(permission: StepPermission.granted);

    _sub = Pedometer.stepCountStream.listen(
      _onReading,
      onError: (_) {
        if (mounted) {
          state = state.copyWith(permission: StepPermission.unsupported);
        }
      },
      cancelOnError: false,
    );
  }

  void _onReading(StepCount reading) {
    final prefs = _prefs;
    if (prefs == null || !mounted) return;
    final today = dateKey(DateTime.now());
    final r = reading.steps;

    var base = prefs.getInt(_kBase);
    var carried = prefs.getInt(_kCarried) ?? 0;
    final last = prefs.getInt(_kLast);

    if (prefs.getString(_kDay) != today || base == null || last == null) {
      // The first reading today: everything before it belongs to earlier.
      base = r;
      carried = 0;
    } else if (r < last) {
      // The phone restarted and the sensor began again from zero; what was
      // counted before it is kept, and the new count adds to it.
      carried += last - base;
      base = 0;
    }

    prefs
      ..setString(_kDay, today)
      ..setInt(_kBase, base)
      ..setInt(_kCarried, carried)
      ..setInt(_kLast, r);

    state = state.copyWith(sensorToday: carried + r - base);
  }

  /// Re-reads the health store if it is allowed, and with [upload] sends
  /// the month it holds.
  Future<void> refreshHealth({bool upload = false}) async {
    if (kIsWeb) return;
    final asked = _prefs?.getBool(_kHealthAsked) ?? false;
    final access = await _healthSteps.access(askedBefore: asked);
    if (!mounted) return;
    state = state.copyWith(health: access);
    if (access != HealthAccess.connected) return;

    final days = await _healthSteps.readDays(_healthDays);
    if (!mounted) return;
    state = state.copyWith(healthDays: days);
    if (upload) {
      await _upload({
        for (final e in days.entries)
          if (e.value.steps > 0) e.key: e.value.steps,
      });
    }
  }

  /// Puts up the platform's permission screen for the health store, then
  /// reads it.
  Future<void> connectHealth() async {
    await _prefs?.setBool(_kHealthAsked, true);
    await _healthSteps.connect();
    await refreshHealth(upload: true);
  }

  /// Health Connect's Play Store page, for an Android 13 phone without it.
  Future<void> installHealthConnect() => _healthSteps.install();

  Future<void> _uploadToday() async {
    final value = state.today;
    if (value == null || value <= 0 || value == _lastUploaded) return;
    await _upload({dateKey(DateTime.now()): value});
    _lastUploaded = value;
  }

  Future<void> _upload(Map<String, int> days) async {
    if (days.isEmpty || _ref.read(authProvider) == null) return;
    try {
      await _ref.read(stepsRepositoryProvider).recordDays(days);
      _ref.invalidate(myStepWeekProvider);
      _ref.invalidate(myStepMonthProvider);
    } catch (_) {
      // Offline: the next minute tries again with the same or a higher
      // figure, and the day keeps its highest.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    _lifecycle?.dispose();
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

/// This person's last thirty days, for the month view.
final myStepMonthProvider = FutureProvider<List<StepEntry>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const [];
  return ref.watch(stepsRepositoryProvider).fetchMyDays(30);
});

/// The last [days] days (7 or 30) as the screen shows them: for each day the
/// highest of what is stored, what the health store has, and — for today —
/// the live count. Signed out, nothing is stored, and the health store and
/// the sensor still give the person their own figures.
final myActivityDaysProvider = Provider.family<List<StepEntry>, int>((
  ref,
  days,
) {
  final stored =
      (days <= 7 ? ref.watch(myStepWeekProvider) : ref.watch(myStepMonthProvider))
          .valueOrNull ??
      const <StepEntry>[];
  final counter = ref.watch(stepCounterProvider);
  final byDate = {for (final e in stored) dateKey(e.date): e.steps};
  final now = DateTime.now();
  final first = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: days - 1));
  int best(int a, int b) => a > b ? a : b;
  return [
    for (var i = 0; i < days; i++)
      () {
        final day = first.add(Duration(days: i));
        final key = dateKey(day);
        var steps = best(byDate[key] ?? 0, counter.healthDays[key]?.steps ?? 0);
        if (i == days - 1) steps = best(steps, counter.today ?? 0);
        return StepEntry(date: day, steps: steps);
      }(),
  ];
});

/// The days the leaderboards count: the last seven, or — while a challenge
/// runs — every day since it started, so the client's monthly city
/// competition (5 Oct) ranks the month so far. [since] is the first day
/// counted, null for the rolling week.
///
/// The ranking functions take a number of days ending today (00043), so a
/// challenge is counted from its start to today. Naming a winner once it has
/// ended needs the days between its start and its end, which they cannot
/// take: that is a migration of its own.
final leaderboardWindowProvider =
    FutureProvider<({int days, DateTime? since})>((ref) async {
      final challenge = await ref.watch(activeChallengeProvider.future);
      final start = DateTime.tryParse(
        challenge?['start_at'] as String? ?? '',
      )?.toLocal();
      if (start == null) return (days: 7, since: null);
      final now = DateTime.now();
      // Calendar days, in UTC so a change of clock does not lose one.
      final first = DateTime.utc(start.year, start.month, start.day);
      final today = DateTime.utc(now.year, now.month, now.day);
      final days = today.difference(first).inDays + 1;
      if (days < 1) return (days: 7, since: null);
      return (days: days.clamp(1, 62), since: first);
    });

/// This person's steps in the running challenge: every day since it
/// started, as the leaderboards count them. Null when signed out or when no
/// challenge runs.
///
/// The challenge card read `challenge_participants.progress`, which nothing
/// in the app writes — so it said "—" and its bar spun as if loading for
/// ever. In the city competition everyone with step counting on takes part,
/// so their own steps are their progress.
final myChallengeStepsProvider = FutureProvider<int?>((ref) async {
  if (ref.watch(authProvider) == null) return null;
  final window = await ref.watch(leaderboardWindowProvider.future);
  if (window.since == null) return null;
  final days = await ref
      .watch(stepsRepositoryProvider)
      .fetchMyDays(window.days);
  return days.fold<int>(0, (sum, d) => sum + d.steps);
});

/// The city ranking. Empty when signed out — the functions are only granted
/// to signed-in callers, because these are other people's figures.
final peopleLeaderboardProvider = FutureProvider<List<PersonRanking>>((
  ref,
) async {
  final user = ref.watch(authProvider);
  if (user == null) return const [];
  final window = await ref.watch(leaderboardWindowProvider.future);
  return ref
      .watch(stepsRepositoryProvider)
      .fetchPeopleLeaderboard(days: window.days);
});

final neighborhoodLeaderboardProvider =
    FutureProvider<List<NeighborhoodRanking>>((ref) async {
      final user = ref.watch(authProvider);
      if (user == null) return const [];
      final window = await ref.watch(leaderboardWindowProvider.future);
      return ref
          .watch(stepsRepositoryProvider)
          .fetchNeighborhoodLeaderboard(days: window.days);
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
