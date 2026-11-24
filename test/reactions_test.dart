import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/shared/reactions/reactions.dart';

// Likes and "helpful" (00089): the count shown moves with a tap before the
// server answers, and is put back if it refuses — so the toggle must be its
// own exact inverse.
void main() {
  test('a like adds one and marks it mine; again takes it back', () {
    const start = ReactionInfo(likes: 3, helpful: 1);
    final liked = start.toggled(ReactionKind.like);
    expect(liked.likes, 4);
    expect(liked.liked, isTrue);
    expect(liked.helpful, 1);
    expect(liked.markedHelpful, isFalse);
    final back = liked.toggled(ReactionKind.like);
    expect(back.likes, 3);
    expect(back.liked, isFalse);
  });

  test('helpful is counted apart from likes', () {
    const start = ReactionInfo(likes: 2, helpful: 0, liked: true);
    final helpful = start.toggled(ReactionKind.helpful);
    expect(helpful.helpful, 1);
    expect(helpful.markedHelpful, isTrue);
    expect(helpful.likes, 2);
    expect(helpful.liked, isTrue);
    expect(helpful.count(ReactionKind.helpful), 1);
    expect(helpful.mine(ReactionKind.like), isTrue);
  });

  test('a count never goes below zero', () {
    // Mine, but the count read as 0 (read before my like was saved).
    const odd = ReactionInfo(likes: 0, liked: true);
    expect(odd.toggled(ReactionKind.like).likes, 0);
  });
}
