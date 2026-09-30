import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Shabbat and holiday times for Modi'in, from Hebcal (hebcal.com).
///
/// They are astronomical: they move every week and differ from town to town,
/// so nothing here is written into the app. A fixed "18:42" once stood on
/// the website's Municipal page for every week of the year. Hebcal is asked
/// by the city's coordinates, so the times are Modi'in's own, and its licence
/// (CC BY 4.0) asks for the credit the screens show.
///
/// The times follow the municipality's own table ("זמני הדלקת נרות" on
/// modiin.muni.il), as the client asked: candle lighting 20 minutes before
/// sunset, Havdalah 30 minutes after, with sunset taken at the city's
/// elevation (about 300 m). Checked against six weeks of the municipality's
/// table (Oct–Nov 2026): 9 of 12 times equal, the other three a minute
/// apart, which is the two sources rounding differently.
const _kLocation =
    'latitude=31.8969&longitude=35.0095&tzid=Asia/Jerusalem&geo=pos'
    '&ue=on&elev=300';

/// Candle lighting and Havdalah, in minutes from sunset.
const _kTimes = 'b=20&m=30';

/// A name Hebcal gives in both languages from one request.
class HebcalName {
  final String he;
  final String en;
  const HebcalName(this.he, this.en);

  String of(bool hebrew) => hebrew ? he : en;

  static HebcalName from(Map<String, dynamic> item) => HebcalName(
    (item['hebrew'] as String?) ?? (item['title'] as String? ?? ''),
    (item['title_orig'] as String?) ?? (item['title'] as String? ?? ''),
  );
}

/// The coming Shabbat: its dates, the two times, and what it is — the
/// week's parasha, or the holiday that falls on it.
class ShabbatWeek {
  final DateTime friday;
  final DateTime saturday;

  /// "18:03", in Israel's time, exactly as Hebcal gives it — read off the
  /// string rather than converted, so a phone set to another zone still
  /// shows the city's time.
  final String? candles;
  final String? havdalah;
  final HebcalName? parasha;
  final List<HebcalName> holidays;

  const ShabbatWeek({
    required this.friday,
    required this.saturday,
    this.candles,
    this.havdalah,
    this.parasha,
    this.holidays = const [],
  });
}

/// One day of a holiday, for the list on the Shabbat & Holidays page.
class HolidayDay {
  final DateTime date;
  final HebcalName name;
  const HolidayDay(this.date, this.name);
}

DateTime _day(String iso) {
  final d = DateTime.parse(iso.substring(0, 10));
  return DateTime(d.year, d.month, d.day);
}

String _time(String iso) => iso.length >= 16 ? iso.substring(11, 16) : '';

Future<List<Map<String, dynamic>>> _items(String url) async {
  final response = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Hebcal answered ${response.statusCode}');
  }
  final body = jsonDecode(utf8.decode(response.bodyBytes));
  return List<Map<String, dynamic>>.from(body['items'] as List? ?? const []);
}

/// This week's Shabbat. Kept for the session; an error shows as an error on
/// the screens, never as a guessed time.
final shabbatWeekProvider = FutureProvider<ShabbatWeek>((ref) async {
  final items = await _items(
    'https://www.hebcal.com/shabbat?cfg=json&$_kLocation&$_kTimes&lg=he',
  );

  // The week can hold a holiday's own candle lighting too (the eve of a
  // festival on a Thursday), so Shabbat's are the last before Havdalah.
  final havdalah = items.lastWhere(
    (i) => i['category'] == 'havdalah',
    orElse: () => const {},
  );
  final candles = items.lastWhere(
    (i) =>
        i['category'] == 'candles' &&
        (havdalah.isEmpty ||
            (i['date'] as String).compareTo(havdalah['date'] as String) < 0),
    orElse: () => const {},
  );

  final now = DateTime.now();
  final saturday = havdalah.isNotEmpty
      ? _day(havdalah['date'] as String)
      : DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: (DateTime.saturday - now.weekday) % 7));
  final friday = saturday.subtract(const Duration(days: 1));
  final parasha = items.where((i) => i['category'] == 'parashat').firstOrNull;

  return ShabbatWeek(
    friday: friday,
    saturday: saturday,
    candles: candles.isEmpty ? null : _time(candles['date'] as String),
    havdalah: havdalah.isEmpty ? null : _time(havdalah['date'] as String),
    parasha: parasha == null ? null : HebcalName.from(parasha),
    holidays: [
      for (final i in items)
        if (i['category'] == 'holiday' && _day(i['date'] as String) == saturday)
          HebcalName.from(i),
    ],
  );
});

/// Holidays in the next three months, as Israel keeps them — all of them,
/// as the client asked: the major ones, the minor ones, the modern Israeli
/// days and the minor fasts. Rosh Chodesh and the special Shabbatot are not
/// holidays and stay out.
final upcomingHolidaysProvider = FutureProvider<List<HolidayDay>>((ref) async {
  final today = DateTime.now();
  final end = today.add(const Duration(days: 90));
  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final items = await _items(
    'https://www.hebcal.com/hebcal?v=1&cfg=json&maj=on&min=on&mod=on&nx=off'
    '&ss=off&mf=on&c=off&i=on&lg=he&start=${ymd(today)}&end=${ymd(end)}',
  );
  return [
    for (final i in items)
      if (i['category'] == 'holiday')
        HolidayDay(_day(i['date'] as String), HebcalName.from(i)),
  ];
});
