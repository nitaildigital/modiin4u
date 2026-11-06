import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/admin/providers/admin_table_notifier.dart';

// Row-level security refuses a write by matching no row, and the write then
// reports success. The panel's writes that must reach a row ask for the ids
// back and go through `expectWritten`, which turns "no row" into an error
// the screen shows (6 Nov).
void main() {
  test('a write that reached no row is refused', () async {
    await expectLater(
      expectWritten(Future.value(<Map<String, dynamic>>[])),
      throwsA(isA<AdminWriteRefused>()),
    );
  });

  test('a write that reached its row goes through', () async {
    await expectLater(
      expectWritten(Future.value(<Map<String, dynamic>>[
        {'id': 'a'},
      ])),
      completes,
    );
  });

  test('the refusal says the change was not saved', () {
    expect(
      const AdminWriteRefused().toString(),
      anyOf(contains('לא נשמר'), contains('not saved')),
    );
  });
}
