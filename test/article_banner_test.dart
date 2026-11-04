import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/news/models/article_body.dart';
import 'package:modiin4u/features/news/widgets/article_banner.dart';
import 'package:modiin4u/features/news/widgets/m_article_parts.dart';

void main() {
  const defaults = {
    'top': {'image': 'https://x/def-top.png', 'link': 'https://def.example'},
    'middle': {'image': 'https://x/def-mid.png'},
  };
  const own = {
    'top': {'image': 'https://x/own-top.png', 'mobile': 'https://x/own-top-m.png', 'link': 'https://own.example'},
  };

  test("an article's own banner comes before the default", () {
    final b = articleBanner(own, defaults, 'top')!;
    expect(b.image, 'https://x/own-top.png');
    expect(b.mobile, 'https://x/own-top-m.png');
    expect(b.link, 'https://own.example');
  });

  test('an empty place falls back to the default, and to nothing', () {
    expect(articleBanner(own, defaults, 'middle')!.image, 'https://x/def-mid.png');
    expect(articleBanner(own, defaults, 'end'), isNull);
    expect(articleBanner(null, null, 'top'), isNull);
    expect(articleBanner('nonsense', 42, 'top'), isNull);
  });

  test('only web addresses count', () {
    expect(articleBanner({'top': {'image': 'javascript:alert(1)'}}, null, 'top'), isNull);
    final b = articleBanner({'top': {'image': 'https://x/a.png', 'link': 'javascript:alert(1)', 'mobile': 'data:x'}}, null, 'top')!;
    expect(b.link, isNull);
    expect(b.mobile, isNull);
  });

  String paragraphs(int n) => List.generate(n, (i) => '<p>Paragraph ${i + 1} with some words in it.</p>').join();

  test('the middle banner goes after the paragraph nearest halfway', () {
    final blocks = parseArticleBody(paragraphs(8));
    expect(MArticleBody.middleCut(blocks), 3);
  });

  test('a story of fewer than four paragraphs has no middle', () {
    expect(MArticleBody.middleCut(parseArticleBody(paragraphs(3))), isNull);
  });

  test('no middle when the break would sit far from halfway', () {
    final long = '<p>${'word ' * 400}</p>${paragraphs(4)}';
    expect(MArticleBody.middleCut(parseArticleBody(long)), isNull);
  });
}
