import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:health/health.dart';

/// One day's activity as the phone's health store has it.
class DayActivity {
  final int steps;

  /// Walking and running distance in metres, when the store has it.
  final double? metres;

  /// Active calories — burned by moving, not the body's resting use — when
  /// the store has them.
  final double? kcal;

  const DayActivity({this.steps = 0, this.metres, this.kcal});
}

/// Where the phone's health data stands for this app.
enum HealthAccess {
  /// Not on this platform or phone (the web; Android older than 9).
  unavailable,

  /// Android 13 or older without the Health Connect app, or with one too
  /// old: it can be installed from the Play Store.
  needsInstall,

  /// Available, but the person has not allowed the app to read it.
  notConnected,

  /// iPhone only: Motion & Fitness was refused, and iOS will not ask again —
  /// only Settings can turn it on.
  denied,

  connected,
}

/// Reads steps, distance and active calories from Health Connect on Android.
///
/// It read Apple Health on an iPhone too, until 24 Nov 2026: App Review
/// turned 1.0 (4) down under Guideline 5.1.1(ix), and the iPhone now counts
/// with Core Motion (motion_steps.dart). The `health` plugin is declared for
/// Android only (packages/health_android_only), so on an iPhone this class
/// is never used and answers [HealthAccess.unavailable].
///
/// The phone's own step sensor only counts while the app is open to listen,
/// and starts again at every restart, so on its own it misses the morning
/// walk and knows nothing of yesterday. The health store has the whole day
/// and the past month, from the phone and from any watch, deduplicated by
/// the platform — so where it is allowed, it is the better figure.
class HealthSteps {
  final Health _health = Health();
  bool _configured = false;

  List<HealthDataType> get _types => [
    HealthDataType.STEPS,
    Platform.isIOS
        ? HealthDataType.DISTANCE_WALKING_RUNNING
        : HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  List<HealthDataAccess> get _read =>
      List.filled(_types.length, HealthDataAccess.READ);

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// [askedBefore] matters on an iPhone only: Apple never tells an app
  /// whether reading was allowed (so that a refusal reveals nothing about
  /// what is stored), so once the question has been put, the app reads and
  /// shows what comes back.
  Future<HealthAccess> access({required bool askedBefore}) async {
    try {
      await _configure();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status ==
            HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          return HealthAccess.needsInstall;
        }
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          return HealthAccess.unavailable;
        }
        final has = await _health.hasPermissions(_types, permissions: _read);
        return has == true ? HealthAccess.connected : HealthAccess.notConnected;
      }
    } catch (e) {
      debugPrint('Health access check failed: $e');
    }
    return HealthAccess.unavailable;
  }

  /// Shows the platform's own permission screen. True when the person came
  /// back having allowed it (on an iPhone: when the screen was shown).
  Future<bool> connect() async {
    try {
      await _configure();
      return await _health.requestAuthorization(_types, permissions: _read);
    } catch (e) {
      debugPrint('Health permission request failed: $e');
      return false;
    }
  }

  /// The steps Health Connect has between [from] and [to] — a competition's
  /// own hours (00088). Null when it could not be read.
  Future<int?> stepsBetween(DateTime from, DateTime to) async {
    if (!to.isAfter(from)) return 0;
    try {
      await _configure();
      return await _health.getTotalStepsInInterval(from, to);
    } catch (e) {
      debugPrint('Health steps between failed: $e');
      return null;
    }
  }

  /// Opens Health Connect's Play Store page.
  Future<void> install() async {
    await _configure();
    await _health.installHealthConnect();
  }

  /// The last [days] days including today, keyed `yyyy-mm-dd`.
  ///
  /// One total per day per kind, which the platform adds up across sources
  /// (Health Connect's aggregate, HealthKit's statistics query), so a phone
  /// and a watch worn together are not counted twice. A kind the store has
  /// nothing for is simply missing.
  Future<Map<String, DayActivity>> readDays(int days) async {
    await _configure();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final steps = <String, int>{};
    final metres = <String, double>{};
    final kcal = <String, double>{};

    for (final type in _types) {
      try {
        final points = await _health.getHealthIntervalDataFromTypes(
          startDate: start,
          endDate: now,
          types: [type],
          interval: const Duration(days: 1).inSeconds,
        );
        for (final p in points) {
          final value = p.value;
          if (value is! NumericHealthValue) continue;
          // The buckets are 24-hour slices from the first midnight, so on
          // a day the clocks change a bucket starts an hour off midnight;
          // its middle is always on the right date.
          final day = dateKey(p.dateFrom.add(const Duration(hours: 12)));
          final n = value.numericValue.toDouble();
          switch (type) {
            case HealthDataType.STEPS:
              steps[day] = (steps[day] ?? 0) + n.round();
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              kcal[day] = (kcal[day] ?? 0) + n;
            default:
              metres[day] = (metres[day] ?? 0) + n;
          }
        }
      } catch (e) {
        debugPrint('Health read of $type failed: $e');
      }
    }

    return {
      for (final day in {...steps.keys, ...metres.keys, ...kcal.keys})
        day: DayActivity(
          steps: steps[day] ?? 0,
          metres: metres[day],
          kcal: kcal[day],
        ),
    };
  }
}

/// `yyyy-mm-dd` in the phone's own calendar, as `daily_steps.date` holds it.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
