import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/businesses/hours_text.dart';

void main() {
  test('a space after the day, the times isolated left to right', () {
    expect(readableHoursLine('יום ראשון11:30–22:00'),
        'יום ראשון \u206611:30–22:00\u2069');
    expect(readableHoursLine('יום חמישיסגור'), 'יום חמישי סגור');
  });

  test('a line already spaced, or in English, keeps its words', () {
    expect(readableHoursLine('יום שבת 18:15 - 23:00'),
        'יום שבת \u206618:15 - 23:00\u2069');
    expect(readableHoursLine('Sun–Thu 08:00–17:00'), 'Sun–Thu \u206608:00–17:00\u2069');
    expect(readableHoursLine('בתיאום מראש'), 'בתיאום מראש');
  });
}
