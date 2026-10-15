/// One line of a business's hours as the WordPress import wrote them
/// (`businesses.hours_text`), made readable whichever way it is set.
///
/// The import glued the day to what follows it ("יום ראשון11:30–22:00",
/// "יום חמישיסגור"), and a Hebrew line is set right to left, which draws a
/// range of times backwards: "22:00–11:30". So a space goes back after the
/// day's name, and every range of times is isolated left to right
/// (U+2066 … U+2069), which keeps it in reading order inside a Hebrew line
/// and changes nothing in an English one. The text itself is not altered.
library;

final _glued = RegExp(r'^(יום\s*(?:ראשון|שני|שלישי|רביעי|חמישי|שישי|שבת))\s*');
final _range = RegExp(r'\d{1,2}:\d{2}(?:\s*[–—-]\s*\d{1,2}:\d{2})?');

String readableHoursLine(String line) => line
    .replaceFirstMapped(_glued, (m) => '${m[1]} ')
    .replaceAllMapped(_range, (m) => '\u2066${m[0]}\u2069');
