import 'event.dart';
import 'event_category.dart';

/// How an event's date, time, price and category read on the website, in
/// whichever of its two languages is showing.
///
/// The four desktop event pages each carried their own copy of these, and
/// they had drifted: one wrote "20:00", the design "8:00 PM"; one printed
/// "Free", another "FREE"; the month badge had two spellings of September.
class EventLabels {
  final bool isHebrew;
  const EventLabels(this.isHebrew);

  String t(String en, String he) => isHebrew ? he : en;

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsHe = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];
  static const _shortHe = [
    'ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יוני',
    'יולי', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳',
  ];
  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _weekdaysHe = [
    'יום שני', 'יום שלישי', 'יום רביעי', 'יום חמישי',
    'יום שישי', 'שבת', 'יום ראשון',
  ];

  /// "AUG" on a date badge.
  String shortMonth(DateTime date) => isHebrew
      ? _shortHe[date.month - 1]
      : _monthsEn[date.month - 1].substring(0, 3).toUpperCase();

  /// "Thursday, August 21, 2026".
  String longDate(DateTime date) {
    final weekday = (isHebrew ? _weekdaysHe : _weekdaysEn)[date.weekday - 1];
    final month = (isHebrew ? _monthsHe : _monthsEn)[date.month - 1];
    return isHebrew
        ? '$weekday, ${date.day} ב$month ${date.year}'
        : '$weekday, $month ${date.day}, ${date.year}';
  }

  /// "8:00 PM" in English, "20:00" in Hebrew, from a `time` column value.
  String? _clock(String? value) {
    final parts = (value ?? '').split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final mm = m.toString().padLeft(2, '0');
    if (isHebrew) return '${h.toString().padLeft(2, '0')}:$mm';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    // A no-break space, so a narrow cell breaks a range at its dash rather
    // than between "11:00" and "PM".
    return '$hour12:$mm\u00A0${h < 12 ? 'AM' : 'PM'}';
  }

  /// When it starts, as a card shows it. Null when the row has no time.
  String? startTime(Event e) {
    if (e.isAllDay) return t('All day', 'כל היום');
    return _clock(e.startTime);
  }

  /// "8:00 PM – 11:00 PM", or just the start when there is no end time.
  String? timeRange(Event e) {
    if (e.isAllDay) return t('All day', 'כל היום');
    final start = _clock(e.startTime);
    if (start == null) return null;
    final end = _clock(e.endTime);
    return end == null ? start : '$start – $end';
  }

  /// "₪50", or "FREE" — capitals on the cards and rows, as drawn; the detail
  /// box writes "Free". Null when the row says neither.
  String? price(Event e, {bool upper = true}) {
    if (e.isFree) return upper ? t('FREE', 'חינם') : t('Free', 'חינם');
    final p = e.price;
    if (p == null || p.isEmpty) return null;
    return p.startsWith('₪') ? p : '₪$p';
  }

  /// Where it is, short: the venue, else the address.
  String? venue(Event e) {
    if (e.isOnline) return t('Online', 'אונליין');
    final v = e.venueName?.trim() ?? '';
    if (v.isNotEmpty) return v;
    return e.address.trim().isEmpty ? null : e.address.trim();
  }

  /// Where it is, in full: the address, else the venue.
  String? address(Event e) {
    if (e.isOnline) return t('Online', 'אונליין');
    final a = e.address.trim();
    if (a.isNotEmpty) return a;
    final v = e.venueName?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  /// "124 people interested".
  String peopleInterested(int n) =>
      n == 1
          ? t('1 person interested', '1 מתעניין')
          : t('$n people interested', '$n מתעניינים');

  /// A category's name in the language showing.
  ///
  /// `categories` holds one name, in Hebrew, and no English one. The English
  /// words are the design's own for the four categories it draws — Music,
  /// Municipal & Community, Kids & Family, Sports — and the category's slug
  /// for the rest; a category added later that is in neither list shows its
  /// Hebrew name rather than a guess.
  String category(EventCategory c) {
    if (isHebrew) return c.name;
    return _englishCategory[c.slug] ?? c.name;
  }

  static const _englishCategory = {
    'concerts': 'Music',
    'music': 'Music',
    'community': 'Municipal & Community',
    'municipal-community': 'Municipal & Community',
    'kids': 'Kids & Family',
    'kids-family': 'Kids & Family',
    'sports-events': 'Sports',
    'sports': 'Sports',
    'workshops': 'Workshops',
    'food-drink': 'Food & Drink',
  };
}

/// An event's description, split the way the event page lays it out: the
/// paragraphs under "About This Event", and the list under "What's
/// Included".
///
/// `events` has no column for what is included. Editors write it at the foot
/// of the description, under a line reading "מה כלול:" (or "What's
/// included:") with one "•" item per line, and the page draws those items as
/// the design's checklist instead of as text. A description without such a
/// list is all paragraphs, and the section is not drawn.
class EventDescription {
  final List<String> paragraphs;
  final List<String> included;
  const EventDescription(this.paragraphs, this.included);

  static final _heading = RegExp(
    r"^(מה כלול|מה כלול באירוע|what'?s included|what is included)\s*:?\s*$",
    caseSensitive: false,
  );
  static final _bullet = RegExp(r'^[•·\-\*–]\s*');

  factory EventDescription.parse(String? text) {
    final paragraphs = <String>[];
    final included = <String>[];
    for (final block in (text ?? '').split(RegExp(r'\n\s*\n'))) {
      final lines = block
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      final rest = lines.skip(1).toList();
      if (included.isEmpty &&
          _heading.hasMatch(lines.first) &&
          rest.isNotEmpty &&
          rest.every(_bullet.hasMatch)) {
        included.addAll(rest.map((l) => l.replaceFirst(_bullet, '')));
        continue;
      }
      paragraphs.add(lines.join('\n'));
    }
    return EventDescription(paragraphs, included);
  }
}
