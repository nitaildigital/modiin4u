import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_entry.dart';
import '../repositories/steps_repository.dart';
import '../services/challenge_window.dart';
import '../services/health_steps.dart';
import '../services/motion_steps.dart';

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

  /// The last month from Health Connect, or on an iPhone the last week from
  /// Core Motion, keyed by date.
  final Map<String, DayActivity> healthDays;

  /// The running competition's figures as this phone last read them exactly,
  /// by date: only the steps inside its hours (00088). These are what is
  /// saved. Empty when none runs.
  final Map<String, DayActivity> challengeDays;

  /// Today's part of the competition as it moves with the live count
  /// between exact readings — shown, never saved.
  final DayActivity? challengeLive;

  const StepState({
    this.sensorToday,
    this.permission = StepPermission.unknown,
    this.health = HealthAccess.unavailable,
    this.healthDays = const {},
    this.challengeDays = const {},
    this.challengeLive,
  });

  StepState copyWith({
    int? sensorToday,
    StepPermission? permission,
    HealthAccess? health,
    Map<String, DayActivity>? healthDays,
    Map<String, DayActivity>? challengeDays,
    DayActivity? challengeLive,
    bool clearChallengeLive = false,
  }) => StepState(
    sensorToday: sensorToday ?? this.sensorToday,
    permission: permission ?? this.permission,
    health: health ?? this.health,
    healthDays: healthDays ?? this.healthDays,
    challengeDays: challengeDays ?? this.challengeDays,
    challengeLive: clearChallengeLive ? null : (challengeLive ?? this.challengeLive),
  );

  /// The competition's figures by date as shown: the exact ones, with
  /// today's live figure where it is ahead.
  Map<String, int> get challengeShown {
    final days = {for (final e in challengeDays.entries) e.key: e.value.steps};
    final live = challengeLive;
    if (live != null) {
      final key = dateKey(DateTime.now());
      if (live.steps > (days[key] ?? 0)) days[key] = live.steps;
    }
    return days;
  }

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

  /// Measured distance and active calories, from the health store only
  /// (on an iPhone, distance from Core Motion and no calories).
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
/// On an iPhone (since 24 Nov 2026) there is no health store: Core Motion
/// gives the day from midnight, the last week and a live count, with
/// distance — it counts whether or not the app is open, so nothing below
/// about baselines applies there. Android is as it was:
///
/// The health store (Health Connect) is read when the person
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
/// figure), when it matters rather than on a clock (9 Oct): as the app
/// goes to the background or closes, the moment a goal is reached (the
/// day's 10,000, or the running challenge's), when the Steps screen opens,
/// and every half hour while the app stays open, so a group sees a long
/// walk before it ends. The month from the health store goes when it is
/// read, so a group sees the morning walk even if the app was opened only
/// in the evening. Nothing is lost between: the count stays on the phone
/// and the day keeps its highest.
///
/// A running competition is counted beside the days, only inside its hours
/// (00088): each date's part of it is read from Core Motion or Health
/// Connect for exactly those hours, and grows with the live count between
/// readings; it is saved on the same occasions as the day.
class StepCounter extends StateNotifier<StepState> {
  StepCounter(this._ref) : super(const StepState()) {
    _start();
  }

  final Ref _ref;
  // Late, so a browser — where there is no health store — never makes one.
  late final HealthSteps _healthSteps = HealthSteps();
  late final MotionSteps _motion = MotionSteps();
  StreamSubscription<StepCount>? _sub;
  StreamSubscription<({String day, DayActivity activity})>? _motionSub;
  Timer? _tick;
  AppLifecycleListener? _lifecycle;
  SharedPreferences? _prefs;
  int? _lastUploaded;

  static const _kDay = 'steps_sensor_day';
  static const _kBase = 'steps_sensor_base';
  static const _kCarried = 'steps_sensor_carried';
  static const _kLast = 'steps_sensor_last';
  static const _kHealthAsked = 'steps_health_asked';
  // Android without Health Connect: the sensor's count when a competition
  // was first seen running on its first day, and its last figure there.
  static const _kChallengeBase = 'steps_challenge_base';
  static const _kChallengeLast = 'steps_challenge_last';

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

    final first = () async {
      if (Platform.isIOS) {
        // Core Motion is the count, the history and the live figure at
        // once. The first reading puts up Apple's Motion & Fitness
        // question, as the sensor's permission is asked here on Android.
        if (await _motion.access() == HealthAccess.notConnected) {
          final now = DateTime.now();
          await _motion.between(DateTime(now.year, now.month, now.day), now);
        }
        await _refreshMotion(upload: true);
      } else {
        // Health first, so its permission screen does not race the
        // sensor's — and the sensor straight after, as before; the
        // competition comes last so it never holds the count back.
        await _refreshHealthStore(upload: true);
        await _startSensor();
      }
      if (mounted) await _refreshChallenge(upload: true);
    }();
    _refreshing = first;
    await first.whenComplete(() => _refreshing = null);

    // Every half hour while the app stays open (it was every minute, with
    // six lists read again after each save — the database's busiest writer
    // for one person walking, 9 Oct). Coming back to the app re-reads the
    // health store, which went on counting meanwhile; leaving it saves.
    _tick = Timer.periodic(const Duration(minutes: 30), (_) async {
      await refreshHealth();
      await _uploadToday();
    });
    _lifecycle = AppLifecycleListener(
      onResume: () => refreshHealth(),
      onHide: () => _uploadToday(),
    );
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
    _followChallenge();
    _checkGoals();
  }

  /// The live figure from midnight, on an iPhone.
  void _listenMotion() {
    _motionSub ??= _motion.today().listen(
      (e) {
        // The stream starts again at midnight on its own; until it does, a
        // figure for yesterday is not today's.
        if (!mounted || e.day != dateKey(DateTime.now())) return;
        _liveDay = e.day;
        state = state.copyWith(
          sensorToday: e.activity.steps,
          healthDays: {...state.healthDays, e.day: e.activity},
        );
        _followChallenge();
        _checkGoals();
      },
      onError: (_) {
        // Refused in Settings meanwhile: the next reading says so.
        _motionSub?.cancel();
        _motionSub = null;
      },
    );
  }

  /// Re-reads the health store if it is allowed, and with [upload] sends
  /// the month it holds; then the running competition, if there is one.
  Future<void> refreshHealth({bool upload = false}) async {
    if (kIsWeb) return;
    // One at a time: opening the Steps screen as the app starts asked for
    // the same reads twice at once.
    final running = _refreshing;
    if (running != null) {
      await running;
      if (!upload) return;
    }
    final next = () async {
      if (Platform.isIOS) {
        await _refreshMotion(upload: upload);
      } else {
        await _refreshHealthStore(upload: upload);
      }
      if (mounted) await _refreshChallenge(upload: upload);
    }();
    _refreshing = next;
    await next.whenComplete(() {
      if (identical(_refreshing, next)) _refreshing = null;
    });
  }

  Future<void>? _refreshing;

  /// The day the iPhone's live figure belongs to; a figure from before
  /// midnight is not saved as today's.
  String? _liveDay;

  /// The iPhone's week from Core Motion.
  Future<void> _refreshMotion({required bool upload}) async {
    final access = await _motion.access();
    if (!mounted) return;
    state = state.copyWith(
      health: access,
      permission: switch (access) {
        HealthAccess.connected => StepPermission.granted,
        HealthAccess.denied => StepPermission.denied,
        HealthAccess.unavailable => StepPermission.unsupported,
        _ => StepPermission.unknown,
      },
    );
    if (access != HealthAccess.connected) return;

    final days = await _motion.readDays(MotionSteps.historyDays);
    if (!mounted) return;
    _liveDay = dateKey(DateTime.now());
    state = state.copyWith(
      healthDays: days,
      // Read again from midnight, so a figure left from yesterday is not
      // carried into today before the live count moves.
      sensorToday: days[dateKey(DateTime.now())]?.steps ?? 0,
    );
    _listenMotion();
    _checkGoals();
    if (upload) {
      await _upload({
        for (final e in days.entries)
          if (e.value.steps > 0) e.key: e.value.steps,
      });
    }
  }

  /// Android: Health Connect, as before.
  Future<void> _refreshHealthStore({required bool upload}) async {
    final asked = _prefs?.getBool(_kHealthAsked) ?? false;
    final access = await _healthSteps.access(askedBefore: asked);
    if (!mounted) return;
    state = state.copyWith(health: access);
    if (access != HealthAccess.connected) return;

    final days = await _healthSteps.readDays(_healthDays);
    if (!mounted) return;
    state = state.copyWith(healthDays: days);
    _checkGoals();
    if (upload) {
      await _upload({
        for (final e in days.entries)
          if (e.value.steps > 0) e.key: e.value.steps,
      });
    }
  }

  /// Puts up the platform's permission screen for the health store, then
  /// reads it. On an iPhone: Apple's Motion & Fitness question, or, once it
  /// has been refused — iOS asks only once — the app's page in Settings.
  Future<void> connectHealth() async {
    if (!kIsWeb && Platform.isIOS) {
      if (state.health == HealthAccess.denied) {
        await openAppSettings();
        return;
      }
      final now = DateTime.now();
      await _motion.between(DateTime(now.year, now.month, now.day), now);
      await refreshHealth(upload: true);
      return;
    }
    await _prefs?.setBool(_kHealthAsked, true);
    await _healthSteps.connect();
    await refreshHealth(upload: true);
  }

  // ─── The running competition (00088) ───
  //
  // What is saved is only ever an exact reading of the competition's hours —
  // Core Motion on an iPhone, Health Connect on Android — never the live
  // count, which can jump when Health Connect takes in a watch's earlier
  // steps; between readings the live count is only shown. Android without
  // Health Connect has only the sensor, whose count from the moment the
  // competition was first seen is both shown and saved.

  /// The competition being followed: running now.
  ChallengeWindow? _window;

  /// The competitions this phone should count, as last fetched, and when.
  List<ChallengeWindow> _counting = const [];
  DateTime? _countingAt;

  /// The sensor's figure and the competition's part of today at the last
  /// exact reading; the live figure grows from there.
  ({String date, int sensor, int slice, double? metres, double? sliceMetres})? _mark;

  /// What was saved, per competition and date, so only changed dates go.
  final Map<String, Map<String, int>> _saved = {};

  /// Past dates of the followed competition already read exactly this run:
  /// they are over, and are not read again on every refresh.
  final Set<String> _readPast = {};

  /// Competitions that ended and whose last figures were saved.
  final Set<String> _finished = {};

  bool get _exactSource =>
      !kIsWeb && (Platform.isIOS || state.health == HealthAccess.connected);

  /// Reads the competition's part of each of its dates for exactly its
  /// hours, and with [upload] saves them. One that ended less than two
  /// hours ago gets a last exact reading up to its end, saved at once — even
  /// when the next one has already started.
  Future<void> _refreshChallenge({bool upload = false}) async {
    // Signed out nothing can be saved or ranked, and without permission or
    // a sensor there is nothing to read.
    final canRead = _exactSource || state.permission == StepPermission.granted;
    if (_ref.read(authProvider) == null || !canRead) {
      _forgetChallenge();
      return;
    }

    final now = DateTime.now();
    // The competitions change seldom: asked again after ten minutes, not on
    // every return to the app.
    if (_countingAt == null || now.difference(_countingAt!) >= const Duration(minutes: 10)) {
      try {
        final rows = await _ref.read(stepsRepositoryProvider).fetchCountingChallenges();
        _counting = [for (final r in rows) ?ChallengeWindow.fromRow(r)];
        _countingAt = now;
      } catch (_) {
        // Offline: nothing new is read or saved, and the live figure stops
        // until a reading succeeds.
        _mark = null;
        return;
      }
    }
    if (!mounted) return;

    // Ended within the last two hours: a last exact reading, saved once.
    for (final w in _counting) {
      if (w.isRunning(now) || !now.isAfter(w.end) || _finished.contains(w.id)) continue;
      final days = await _readWindow(w, now, skipPast: false);
      if (!mounted) return;
      if (await _save(w, days) != false) _finished.add(w.id);
    }

    final w = _counting.where((c) => c.isRunning(now)).firstOrNull;
    if (w == null) {
      _forgetChallenge();
      return;
    }
    final old = _window;
    if (old == null || old.id != w.id || old.start != w.start || old.end != w.end) {
      // Another competition, or its times were changed: start again from
      // exact readings rather than keeping higher figures from other hours.
      _forgetChallenge(keepCounting: true);
      _clearSensorKeys(except: w.id);
    }
    _window = w;

    final read = await _readWindow(w, now, skipPast: true);
    if (!mounted || _window?.id != w.id) return;
    final days = {...state.challengeDays};
    read.forEach((k, v) {
      // A date never goes down here: Health Connect can lag.
      if (v.steps >= (days[k]?.steps ?? 0)) days[k] = v;
    });
    final key = dateKey(now);
    state = state.copyWith(challengeDays: days, clearChallengeLive: true);
    _mark = _exactSource
        ? (
            date: key,
            sensor: state.sensorToday ?? 0,
            slice: days[key]?.steps ?? 0,
            metres: state.healthDays[key]?.metres,
            sliceMetres: days[key]?.metres,
          )
        : null;
    _checkGoals();
    if (upload) await _uploadChallenge();
  }

  /// The competition's figures for its dates, read for exactly its hours.
  /// Past dates read before in this run are left out when [skipPast].
  Future<Map<String, DayActivity>> _readWindow(
    ChallengeWindow w,
    DateTime now, {
    required bool skipPast,
  }) async {
    final ios = Platform.isIOS;
    final healthConnect = !ios && state.health == HealthAccess.connected;
    final today = dateKey(now);
    final slices = windowSlices(
      w,
      now,
      // What the phone can still read back; the sensor alone knows today.
      historyDays: ios ? MotionSteps.historyDays : (healthConnect ? _healthDays : 1),
    );
    final out = <String, DayActivity>{};
    for (final s in slices) {
      if (skipPast && s.date != today && _readPast.contains(s.date)) continue;
      DayActivity? a;
      if (ios) {
        a = await _motion.between(s.from, s.to);
      } else if (healthConnect) {
        final n = await _healthSteps.stepsBetween(s.from, s.to);
        a = n == null ? null : DayActivity(steps: n);
      } else {
        a = _sensorSlice(w, s, now);
      }
      if (a == null) continue;
      if (skipPast && s.date != today) _readPast.add(s.date);
      if (a.steps > 0) out[s.date] = a;
    }
    return out;
  }

  void _forgetChallenge({bool keepCounting = false}) {
    _window = null;
    _mark = null;
    _readPast.clear();
    if (!keepCounting) {
      _counting = const [];
      _countingAt = null;
    }
    if (state.challengeDays.isNotEmpty || state.challengeLive != null) {
      state = state.copyWith(challengeDays: const {}, clearChallengeLive: true);
    }
  }

  /// Android without Health Connect: the sensor knows only today, from its
  /// first reading. On the competition's first day its count when the
  /// competition was first seen running is taken off, so the morning before
  /// it does not count; steps between its start and that moment are lost.
  /// After the end, the last figure from before it stays.
  DayActivity? _sensorSlice(ChallengeWindow w, WindowSlice s, DateTime now) {
    final prefs = _prefs;
    final today = state.sensorToday;
    if (prefs == null || today == null || s.date != dateKey(now)) return null;
    final baseKey = '$_kChallengeBase:${w.id}:${s.date}';
    final lastKey = '$_kChallengeLast:${w.id}:${s.date}';
    if (!w.isRunning(now)) {
      final last = prefs.getInt(lastKey);
      return last == null ? null : DayActivity(steps: last);
    }
    var base = 0;
    if (s.from == w.start) {
      final kept = prefs.getInt(baseKey);
      base = kept ?? today;
      if (kept == null) prefs.setInt(baseKey, base);
    }
    final steps = today - base < 0 ? 0 : today - base;
    if (prefs.getInt(lastKey) != steps) prefs.setInt(lastKey, steps);
    return DayActivity(steps: steps);
  }

  /// The sensor's competition keys of other competitions, which are over.
  void _clearSensorKeys({required String except}) {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final k in prefs.getKeys()) {
      if ((k.startsWith('$_kChallengeBase:') || k.startsWith('$_kChallengeLast:')) &&
          !k.contains(':$except:')) {
        prefs.remove(k);
      }
    }
  }

  /// Between exact readings, today's part of the competition moves with the
  /// live count — only while it runs.
  void _followChallenge() {
    final w = _window;
    if (w == null) return;
    final now = DateTime.now();
    final key = dateKey(now);
    if (!w.isRunning(now)) return;

    // Android without Health Connect: the sensor's own figure, shown and
    // saved alike.
    if (!_exactSource) {
      final midnight = DateTime(now.year, now.month, now.day);
      final from = w.start.isAfter(midnight) ? w.start : midnight;
      final a = _sensorSlice(w, (date: key, from: from, to: now), now);
      if (a != null && a.steps > (state.challengeDays[key]?.steps ?? 0)) {
        state = state.copyWith(challengeDays: {...state.challengeDays, key: a});
      }
      return;
    }

    // Otherwise from the phone's own step count since the last exact
    // reading — not from Health Connect's total, which jumps when a watch
    // syncs — and only shown.
    final m = _mark;
    final sensor = state.sensorToday;
    if (m == null || m.date != key || sensor == null) return;
    final steps = m.slice + (sensor - m.sensor < 0 ? 0 : sensor - m.sensor);
    if (steps <= (state.challengeLive?.steps ?? m.slice)) return;
    final metresNow = state.healthDays[key]?.metres;
    final metres = (m.sliceMetres != null && m.metres != null && metresNow != null)
        ? m.sliceMetres! + (metresNow - m.metres!)
        : null;
    state = state.copyWith(challengeLive: DayActivity(steps: steps, metres: metres));
  }

  /// Saves the followed competition's figures, first reading today's part
  /// again exactly (on the phone, no network) so what goes is up to date.
  Future<bool> _uploadChallenge({bool refreshRanks = false}) async {
    final w = _window;
    if (w == null || _ref.read(authProvider) == null) return false;
    final now = DateTime.now();
    if (_exactSource) {
      final today = windowSlices(w, now, historyDays: 1);
      if (today.isNotEmpty) {
        final fresh = await _readWindow(w, now, skipPast: true);
        if (!mounted || _window?.id != w.id) return false;
        final days = {...state.challengeDays};
        fresh.forEach((k, v) {
          if (v.steps >= (days[k]?.steps ?? 0)) days[k] = v;
        });
        state = state.copyWith(challengeDays: days);
      }
    }
    return await _save(w, state.challengeDays, refreshRanks: refreshRanks) ?? true;
  }

  /// Sends the dates that changed since the last save of [w]: true once
  /// saved, false when it failed (offline), null when nothing had changed.
  Future<bool?> _save(
    ChallengeWindow w,
    Map<String, DayActivity> days, {
    bool refreshRanks = false,
  }) async {
    final saved = _saved[w.id] ?? const {};
    final changed = {
      for (final e in days.entries)
        if (e.value.steps > (saved[e.key] ?? 0)) e.key: e.value,
    };
    if (changed.isEmpty) return null;
    try {
      await _ref.read(stepsRepositoryProvider).recordChallengeDays(w.id, changed);
      _saved[w.id] = {...saved, for (final e in changed.entries) e.key: e.value.steps};
      _ref.invalidate(myChallengeDaysProvider);
      final now = DateTime.now();
      // The rankings at most every quarter of an hour, or when asked — and
      // not again if the day's save just asked for them.
      final justRead = _ranksReadAt != null && now.difference(_ranksReadAt!) < const Duration(seconds: 10);
      if (!justRead &&
          (refreshRanks || _ranksReadAt == null || now.difference(_ranksReadAt!) >= const Duration(minutes: 15))) {
        _ranksReadAt = now;
        _ref.invalidate(peopleLeaderboardProvider);
        _ref.invalidate(neighborhoodLeaderboardProvider);
      }
      return true;
    } catch (_) {
      // Offline: sent again on the next occasion; each date keeps its
      // highest, so nothing is counted twice.
      return false;
    }
  }

  /// Health Connect's Play Store page, for an Android 13 phone without it.
  Future<void> installHealthConnect() => _healthSteps.install();

  /// The goals already saved for, today, so each sends once.
  final Set<String> _goalsSent = {};

  /// Saves today's count the moment it reaches a goal: the day's 10,000,
  /// or the running challenge's — a day's target, or its total since it
  /// began — so a win is recorded at once (00058).
  void _checkGoals() {
    final today = state.today;
    if (today == null || today <= 0) return;
    final day = dateKey(DateTime.now());
    // The panel's daily goal, the one the Steps screen's ring fills against.
    final dailyGoal = _ref.read(dailyStepGoalProvider);
    var reached = <String>[if (today >= dailyGoal) '$day:day'];
    // The competition's goal, counted inside its hours: saving at once
    // lets the rankings show it. The winner is named once it has ended.
    final w = _window;
    final goal = w?.goal;
    if (w != null && goal != null && goal > 0) {
      final saved = _ref.read(myChallengeDaysProvider).valueOrNull ?? const {};
      final merged = mergeHighest(saved, state.challengeShown);
      final score = w.perDay
          ? (merged[day] ?? 0)
          : windowScore(merged.values, perDay: false);
      if (score >= goal) reached.add('$day:challenge:${w.id}');
    }
    reached = reached.where((k) => !_goalsSent.contains(k)).toList();
    if (reached.isEmpty) return;
    _goalsSent.addAll(reached);
    _uploadToday(refreshRanks: true);
  }

  /// Saves today's count now and reads the rankings again — the Steps
  /// screen calls it as it opens.
  Future<void> syncNow() async {
    await refreshHealth();
    await _uploadToday(refreshRanks: true);
  }

  Future<void> _uploadToday({bool refreshRanks = false}) async {
    final value = state.today;
    // On an iPhone the live figure must be today's: past midnight, until the
    // count starts again, it is still yesterday's.
    final stale = !kIsWeb && Platform.isIOS && _liveDay != dateKey(DateTime.now());
    if (!stale && value != null && value > 0 && value != _lastUploaded) {
      // Remembered only once it is saved: offline, or before signing in,
      // the next occasion sends it again.
      if (await _upload({dateKey(DateTime.now()): value}, refreshRanks: refreshRanks)) _lastUploaded = value;
    }
    await _uploadChallenge(refreshRanks: refreshRanks);
  }

  DateTime? _ranksReadAt;

  /// Saves [days]; true once they are in the database.
  Future<bool> _upload(Map<String, int> days, {bool refreshRanks = false}) async {
    if (days.isEmpty || _ref.read(authProvider) == null) return false;
    try {
      await _ref.read(stepsRepositoryProvider).recordDays(days);
      // This person's own figures follow the walk.
      _ref.invalidate(myStepWeekProvider);
      _ref.invalidate(myStepMonthProvider);
      // The rankings and the challenge (a save can make someone the winner,
      // 00058) read every resident's days: again on a goal or as the screen
      // opens, otherwise at most every quarter of an hour.
      final now = DateTime.now();
      if (refreshRanks || _ranksReadAt == null || now.difference(_ranksReadAt!) >= const Duration(minutes: 15)) {
        _ranksReadAt = now;
        _ref.invalidate(activeChallengeProvider);
        _ref.invalidate(peopleLeaderboardProvider);
        _ref.invalidate(neighborhoodLeaderboardProvider);
      }
      return true;
    } catch (_) {
      // Offline: the next tick tries again with the same or a higher
      // figure, and the day keeps its highest.
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _motionSub?.cancel();
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

/// What the leaderboards' caption says they count: the last seven days, or —
/// while a competition runs — the competition since it started ("Since 23
/// September"). [since] is its first day, null for the rolling week. The
/// rankings themselves come from the competition's own figures (00088).
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
      // Every day since the start, as the caption says — no cap.
      return (days: days, since: first);
    });

/// This person's saved figures in the running competition, by date.
final myChallengeDaysProvider = FutureProvider<Map<String, int>>((ref) async {
  if (ref.watch(authProvider) == null) return const {};
  final id = (await ref.watch(activeChallengeProvider.future))?['id'] as String?;
  if (id == null) return const {};
  return ref.watch(stepsRepositoryProvider).fetchMyChallengeDays(id);
});

/// This person's figure in the running competition, counted only inside its
/// hours (00088): the total, or with "goal in a single day" today's — what
/// is saved, or the phone's own count where it is ahead. Null when signed
/// out or when no competition runs.
///
/// The challenge card read `challenge_participants.progress`, which nothing
/// in the app writes — so it said "—" and its bar spun as if loading for
/// ever. In the city competition everyone with step counting on takes part,
/// so their own steps are their progress.
final myChallengeStepsProvider = FutureProvider<int?>((ref) async {
  if (ref.watch(authProvider) == null) return null;
  final w = ChallengeWindow.fromRow(await ref.watch(activeChallengeProvider.future));
  if (w == null) return null;
  final saved = await ref.watch(myChallengeDaysProvider.future);
  final local = ref.watch(stepCounterProvider.select((s) => s.challengeShown));
  final merged = mergeHighest(saved, local);
  if (w.perDay) return merged[dateKey(DateTime.now())] ?? 0;
  return windowScore(merged.values, perDay: false);
});

/// A competition this person won lately, for the win message: the winner
/// is named only once it has ended (00088), when it is no longer the one
/// running. Null when signed out or without one in the last two weeks.
final myRecentWinProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return null;
  final since = DateTime.now().toUtc().subtract(const Duration(days: 14));
  final rows = await SupabaseConfig.client
      .from('challenges')
      .select()
      .eq('winner_id', user.id)
      .gte('won_at', since.toIso8601String())
      .order('won_at', ascending: false)
      .limit(1);
  final list = List<Map<String, dynamic>>.from(rows);
  return list.isEmpty ? null : list.first;
});

/// The city ranking. Empty when signed out — the functions are only granted
/// to signed-in callers, because these are other people's figures. While a
/// competition runs it is the competition's, counted inside its hours and
/// the way its winner is chosen (00088); otherwise the last seven days.
final peopleLeaderboardProvider = FutureProvider<List<PersonRanking>>((
  ref,
) async {
  final user = ref.watch(authProvider);
  if (user == null) return const [];
  final repo = ref.watch(stepsRepositoryProvider);
  final id = (await ref.watch(activeChallengeProvider.future))?['id'] as String?;
  if (id != null) return repo.fetchChallengePeople(id);
  return repo.fetchPeopleLeaderboard(days: 7);
});

final neighborhoodLeaderboardProvider =
    FutureProvider<List<NeighborhoodRanking>>((ref) async {
      final user = ref.watch(authProvider);
      if (user == null) return const [];
      final repo = ref.watch(stepsRepositoryProvider);
      final id = (await ref.watch(activeChallengeProvider.future))?['id'] as String?;
      if (id != null) return repo.fetchChallengeNeighborhoods(id);
      return repo.fetchNeighborhoodLeaderboard(days: 7);
    });

/// The challenge running now, if there is one.
///
/// The screen carried a fixed "MODIIN MONTHLY CHALLENGE — walk 150,000
/// steps" with a fixed progress bar. `challenges` is empty, so the section
/// is hidden rather than showing a challenge nobody set.
final activeChallengeProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  // In UTC, with its zone. The phone's local time carries no zone, and the
  // database reads one without a zone as UTC — in Israel the competition
  // appeared three hours before it began and was gone for its last three.
  final now = DateTime.now().toUtc().toIso8601String();
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
