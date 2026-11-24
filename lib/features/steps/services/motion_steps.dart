import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

import 'health_steps.dart' show DayActivity, HealthAccess, dateKey;

/// The iPhone's own step count, through Core Motion (`MotionSteps` in
/// ios/Runner/AppDelegate.swift).
///
/// It took Apple Health's place on the iPhone on 24 Nov 2026, after App
/// Review's 5.1.1(ix) rejection; Android keeps Health Connect. The motion
/// coprocessor counts whether or not the app is open and the system keeps
/// the last seven days, so any stretch of them can be read back — the day
/// from midnight, or a competition from its start — and nothing starts
/// again at zero when the app or the phone restarts. What it does not have:
/// a watch's steps, anything older than a week, and calories.
class MotionSteps {
  static const _methods = MethodChannel('modiin4u/motion');
  static const _today = EventChannel('modiin4u/motion/today');

  /// How far back the system keeps the figures.
  static const historyDays = 7;

  /// Where the Motion & Fitness permission stands.
  Future<HealthAccess> access() async {
    try {
      final s = await _methods.invokeMapMethod<String, dynamic>('status');
      if (s == null || s['available'] != true) return HealthAccess.unavailable;
      return switch (s['auth']) {
        'authorized' => HealthAccess.connected,
        'denied' || 'restricted' => HealthAccess.denied,
        _ => HealthAccess.notConnected,
      };
    } catch (e) {
      debugPrint('Motion status failed: $e');
      return HealthAccess.unavailable;
    }
  }

  /// The steps and distance between [from] and [to]. The first query asks
  /// the Motion & Fitness question. Null when it could not be read
  /// (refused, or no sensor).
  Future<DayActivity?> between(DateTime from, DateTime to) async {
    if (!to.isAfter(from)) return const DayActivity();
    try {
      final r = await _methods.invokeMapMethod<String, dynamic>('query', {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
      });
      if (r == null) return null;
      return DayActivity(
        steps: (r['steps'] as num?)?.toInt() ?? 0,
        metres: (r['metres'] as num?)?.toDouble(),
      );
    } on PlatformException catch (e) {
      debugPrint('Motion query failed: ${e.code}');
      return null;
    }
  }

  /// The last [days] days including today, keyed `yyyy-mm-dd`, as
  /// HealthSteps.readDays gives them; at most [historyDays].
  Future<Map<String, DayActivity>> readDays(int days) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = <String, DayActivity>{};
    for (var i = 0; i < days.clamp(1, historyDays); i++) {
      // Calendar days, not 24 hours: a day the clocks change is 23 or 25.
      final start = DateTime(today.year, today.month, today.day - i);
      final end = i == 0 ? now : DateTime(start.year, start.month, start.day + 1);
      final day = await between(start, end);
      if (day == null) break;
      if (day.steps > 0) out[dateKey(start)] = day;
    }
    return out;
  }

  /// Today's figures from midnight, live; it starts again from the next
  /// midnight on its own.
  Stream<({String day, DayActivity activity})> today() => _today
      .receiveBroadcastStream()
      .map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final day = DateTime.fromMillisecondsSinceEpoch((m['day'] as num).toInt());
        return (
          day: dateKey(day),
          activity: DayActivity(
            steps: (m['steps'] as num?)?.toInt() ?? 0,
            metres: (m['metres'] as num?)?.toDouble(),
          ),
        );
      });
}
