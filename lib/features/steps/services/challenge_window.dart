import 'health_steps.dart' show dateKey;

/// A step competition's own hours (00088): only steps taken between its
/// start and its end count towards it — not the morning before it opened on
/// its first day, nor the evening after it closed on its last.
class ChallengeWindow {
  final String id;
  final DateTime start;
  final DateTime end;

  /// "Goal in a single day": progress and the winner go by the best day,
  /// otherwise by the total.
  final bool perDay;
  final int? goal;

  const ChallengeWindow({
    required this.id,
    required this.start,
    required this.end,
    this.perDay = false,
    this.goal,
  });

  /// From a `challenges` row; null without an id or valid times.
  static ChallengeWindow? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final id = row['id'] as String?;
    final start = DateTime.tryParse(row['start_at'] as String? ?? '')?.toLocal();
    final end = DateTime.tryParse(row['end_at'] as String? ?? '')?.toLocal();
    if (id == null || start == null || end == null || !end.isAfter(start)) {
      return null;
    }
    return ChallengeWindow(
      id: id,
      start: start,
      end: end,
      perDay: row['goal_per_day'] == true,
      goal: (row['goal'] as num?)?.toInt(),
    );
  }

  bool isRunning(DateTime now) => !now.isBefore(start) && now.isBefore(end);
}

/// One date's part of a competition: from [from] to [to], both inside it.
typedef WindowSlice = ({String date, DateTime from, DateTime to});

/// The competition's part of each calendar day from its first day to
/// today, as far back as the phone keeps figures ([historyDays] including
/// today), each cut to the competition's hours and to [now]. Oldest first;
/// a day with nothing inside the hours is left out.
List<WindowSlice> windowSlices(
  ChallengeWindow w,
  DateTime now, {
  required int historyDays,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final firstKept = DateTime(today.year, today.month, today.day - (historyDays - 1));
  final startDay = DateTime(w.start.year, w.start.month, w.start.day);
  var day = startDay.isAfter(firstKept) ? startDay : firstKept;
  final out = <WindowSlice>[];
  while (!day.isAfter(today)) {
    // The next midnight by the calendar, so a day the clocks change is
    // still one day.
    final next = DateTime(day.year, day.month, day.day + 1);
    final from = w.start.isAfter(day) ? w.start : day;
    var to = w.end.isBefore(next) ? w.end : next;
    if (now.isBefore(to)) to = now;
    if (to.isAfter(from)) out.add((date: dateKey(day), from: from, to: to));
    day = next;
  }
  return out;
}

/// A competition's figure from each date's: the best date with "goal in a
/// single day", otherwise their sum — the way the database ranks it.
int windowScore(Iterable<int> days, {required bool perDay}) {
  var total = 0;
  var best = 0;
  for (final d in days) {
    total += d;
    if (d > best) best = d;
  }
  return perDay ? best : total;
}

/// Each date's higher figure of two — what is saved and what the phone has
/// counted since — since a date only ever keeps its highest (00088).
Map<String, int> mergeHighest(Map<String, int> a, Map<String, int> b) => {
  for (final k in {...a.keys, ...b.keys})
    k: ((a[k] ?? 0) > (b[k] ?? 0) ? a[k] : b[k]) ?? 0,
};
