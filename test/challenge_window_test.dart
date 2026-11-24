import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/steps/services/challenge_window.dart';

// A competition counts only inside its own hours (00088). These check how
// the phone cuts its dates into the stretches it reads back.
void main() {
  final w = ChallengeWindow(
    id: 'c1',
    start: DateTime(2026, 11, 20, 9),
    end: DateTime(2026, 11, 23, 18),
  );

  test('the first and last days are cut to the hours', () {
    final s = windowSlices(w, DateTime(2026, 11, 24, 10), historyDays: 7);
    expect(s.map((e) => e.date), [
      '2026-11-20',
      '2026-11-21',
      '2026-11-22',
      '2026-11-23',
    ]);
    // Nothing before 09:00 on the first day…
    expect(s.first.from, DateTime(2026, 11, 20, 9));
    expect(s.first.to, DateTime(2026, 11, 21));
    // …whole days between…
    expect(s[1].from, DateTime(2026, 11, 21));
    expect(s[1].to, DateTime(2026, 11, 22));
    // …and nothing after 18:00 on the last.
    expect(s.last.from, DateTime(2026, 11, 23));
    expect(s.last.to, DateTime(2026, 11, 23, 18));
  });

  test('while it runs, today stops at now', () {
    final s = windowSlices(w, DateTime(2026, 11, 22, 15, 30), historyDays: 7);
    expect(s.last.date, '2026-11-22');
    expect(s.last.to, DateTime(2026, 11, 22, 15, 30));
  });

  test('before it starts there is nothing to read', () {
    expect(windowSlices(w, DateTime(2026, 11, 20, 8, 59), historyDays: 7), isEmpty);
    expect(w.isRunning(DateTime(2026, 11, 20, 8, 59)), isFalse);
    expect(w.isRunning(DateTime(2026, 11, 20, 9)), isTrue);
    expect(w.isRunning(DateTime(2026, 11, 23, 18)), isFalse);
  });

  test('only as far back as the phone keeps figures', () {
    final long = ChallengeWindow(
      id: 'c2',
      start: DateTime(2026, 11, 1, 9),
      end: DateTime(2026, 11, 30, 21),
    );
    final s = windowSlices(long, DateTime(2026, 11, 24, 12), historyDays: 7);
    expect(s.length, 7);
    expect(s.first.date, '2026-11-18');
    expect(s.first.from, DateTime(2026, 11, 18));
    // The sensor alone: today only.
    final today = windowSlices(long, DateTime(2026, 11, 24, 12), historyDays: 1);
    expect(today.map((e) => e.date), ['2026-11-24']);
  });

  test('a competition inside one day is one stretch', () {
    final short = ChallengeWindow(
      id: 'c3',
      start: DateTime(2026, 11, 24, 10),
      end: DateTime(2026, 11, 24, 12),
    );
    final s = windowSlices(short, DateTime(2026, 11, 24, 23), historyDays: 7);
    expect(s.length, 1);
    expect(s.single.from, DateTime(2026, 11, 24, 10));
    expect(s.single.to, DateTime(2026, 11, 24, 12));
  });

  test('the score is the total, or the best day', () {
    expect(windowScore([3000, 12000, 5000], perDay: false), 20000);
    expect(windowScore([3000, 12000, 5000], perDay: true), 12000);
    expect(windowScore(const [], perDay: false), 0);
  });

  test('a date keeps the higher of what is saved and what is counted', () {
    expect(
      mergeHighest({'a': 5000, 'b': 100}, {'b': 900, 'c': 40}),
      {'a': 5000, 'b': 900, 'c': 40},
    );
  });

  test('a row without valid times is no competition', () {
    expect(ChallengeWindow.fromRow(null), isNull);
    expect(
      ChallengeWindow.fromRow({
        'id': 'x',
        'start_at': '2026-11-24T10:00:00Z',
        'end_at': '2026-11-24T09:00:00Z',
      }),
      isNull,
    );
    final ok = ChallengeWindow.fromRow({
      'id': 'x',
      'start_at': '2026-11-24T08:00:00Z',
      'end_at': '2026-11-25T08:00:00Z',
      'goal': 50000,
      'goal_per_day': true,
    });
    expect(ok?.goal, 50000);
    expect(ok?.perDay, isTrue);
  });
}
