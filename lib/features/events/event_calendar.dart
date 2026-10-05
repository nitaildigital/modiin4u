import 'package:url_launcher/url_launcher.dart';

import 'models/event.dart';

/// Adds an event to the reader's calendar: Google Calendar's "new event" page,
/// filled in with the title, the times, the place and a line about it. One
/// link that works in any browser and on both phones, with no calendar
/// permission to ask for.
///
/// An event's date and its times are kept apart, the times as Israel's clock
/// shows them, so they are sent as they are with Israel's time zone named —
/// a phone set to another zone then shows them converted, not shifted. An
/// event with no time goes in as a whole day; one with no end time ends when
/// it starts, rather than being given a length nobody set.
Future<void> addEventToCalendar(Event event, {String? details}) {
  final day = event.startDate!;
  final lastDay = event.endDate ?? day;
  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) => '${d.year}${two(d.month)}${two(d.day)}';
  (int, int)? time(String? raw) {
    final parts = (raw ?? '').split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    return h == null || m == null ? null : (h, m);
  }

  final from = time(event.startTime);
  final String dates;
  if (event.isAllDay || from == null) {
    // Google's end date for whole days is the day after the last one.
    dates = '${date(day)}/${date(lastDay.add(const Duration(days: 1)))}';
  } else {
    final to = time(event.endTime) ?? from;
    var endDay = lastDay;
    // 21:00–01:00 on one date runs past midnight.
    if (event.endDate == null && (to.$1 * 60 + to.$2) < (from.$1 * 60 + from.$2)) {
      endDay = day.add(const Duration(days: 1));
    }
    dates = '${date(day)}T${two(from.$1)}${two(from.$2)}00/'
        '${date(endDay)}T${two(to.$1)}${two(to.$2)}00';
  }

  final place = [
    event.venueName?.trim() ?? '',
    event.address.trim(),
  ].where((s) => s.isNotEmpty).join(', ');
  final uri = Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': event.title,
    'dates': dates,
    'ctz': 'Asia/Jerusalem',
    if (place.isNotEmpty) 'location': place,
    if (details != null && details.isNotEmpty) 'details': details,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}
