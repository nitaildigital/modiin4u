/// Israel's clock, whatever computer the panel is opened on.
///
/// The panel's date and time pickers hand back the browser's own wall clock,
/// and `toUtc()` read it in the browser's time zone. From India (the team) a
/// campaign "until the 14th" ended at 23:59 India time — 21:29 in Israel — and
/// a push for 13:41 went at 11:11 Israel time. Every date the panel shows or
/// saves goes through here instead: what is picked is Israel's clock, and
/// what is shown is Israel's clock.
///
/// Israel's summer time (the 2013 law): from the Friday before the last
/// Sunday of March at 02:00 to the last Sunday of October at 02:00 — UTC+3
/// then, UTC+2 the rest of the year. Written out rather than taken from a
/// time-zone database, which the web build would have to download whole.
library;

/// The last Sunday of [month] in [year] (a UTC midnight).
DateTime _lastSunday(int year, int month) {
  final last = DateTime.utc(year, month + 1, 0);
  return last.subtract(Duration(days: last.weekday % 7));
}

/// Israel's offset from UTC at the instant [at].
Duration israelOffset(DateTime at) {
  final u = at.toUtc();
  // Friday 02:00 Israel standard time is 00:00 UTC.
  final start = _lastSunday(u.year, 3).subtract(const Duration(days: 2));
  // Sunday 02:00 Israel summer time is 23:00 UTC the evening before.
  final end = _lastSunday(u.year, 10).subtract(const Duration(hours: 1));
  final summer = !u.isBefore(start) && u.isBefore(end);
  return Duration(hours: summer ? 3 : 2);
}

/// [at] as Israel's clock shows it. The result's fields (year … second) are
/// Israel's; it is meant for pickers and for display, and goes back to an
/// instant only through [fromIsrael] — never `toUtc()`.
DateTime toIsrael(DateTime at) {
  final u = at.toUtc();
  final w = u.add(israelOffset(u));
  return DateTime(w.year, w.month, w.day, w.hour, w.minute, w.second);
}

/// The instant (UTC) at which Israel's clock reads [wall]'s fields.
DateTime fromIsrael(DateTime wall) {
  final naive = DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
  );
  var at = naive.subtract(israelOffset(naive.subtract(const Duration(hours: 2))));
  // Near the changeover the first guess can sit on the other side of it.
  final again = naive.subtract(israelOffset(at));
  if (again != at) at = again;
  return at;
}

/// Now, on Israel's clock.
DateTime israelNow() => toIsrael(DateTime.now());

/// A stored timestamp (ISO, as Supabase returns it) on Israel's clock; null
/// when there is none.
DateTime? israelFromStored(String? iso) {
  final at = DateTime.tryParse(iso ?? '');
  return at == null ? null : toIsrael(at);
}

/// A time picked on Israel's clock, for a timestamptz column.
String israelToStored(DateTime wall) => fromIsrael(wall).toIso8601String();
