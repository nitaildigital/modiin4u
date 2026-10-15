import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/core/time/israel_time.dart';

void main() {
  test('offset across the 2026 changeovers', () {
    // Summer time 2026: Fri 27 Mar 02:00 IST → Sun 25 Oct 02:00 IDT.
    expect(israelOffset(DateTime.utc(2026, 3, 26, 23, 59)).inHours, 2);
    expect(israelOffset(DateTime.utc(2026, 3, 27, 0, 0)).inHours, 3);
    expect(israelOffset(DateTime.utc(2026, 10, 24, 22, 59)).inHours, 3);
    expect(israelOffset(DateTime.utc(2026, 10, 24, 23, 0)).inHours, 2);
    expect(israelOffset(DateTime.utc(2027, 1, 1)).inHours, 2);
  });

  test('round trip', () {
    // 13:41 in Israel on 1 Jan 2027 (winter) is 11:41 UTC.
    expect(fromIsrael(DateTime(2027, 1, 1, 13, 41)), DateTime.utc(2027, 1, 1, 11, 41));
    // 23:59:59 on 14 Oct 2026 (summer) is 20:59:59 UTC.
    expect(fromIsrael(DateTime(2026, 10, 14, 23, 59, 59)), DateTime.utc(2026, 10, 14, 20, 59, 59));
    // Midnight 1 Feb 2027 is 22:00 UTC the day before.
    expect(fromIsrael(DateTime(2027, 2, 1)), DateTime.utc(2027, 1, 31, 22));
    final w = toIsrael(DateTime.utc(2026, 10, 14, 20, 59, 59));
    expect([w.year, w.month, w.day, w.hour, w.minute], [2026, 10, 14, 23, 59]);
    expect(israelFromStored('2027-01-01T11:41:00+00:00')!.hour, 13);
    expect(israelToStored(DateTime(2027, 1, 1, 13, 41)), '2027-01-01T11:41:00.000Z');
  });
}
