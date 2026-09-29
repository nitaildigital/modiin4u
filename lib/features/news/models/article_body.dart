/// An article's body, broken into the blocks a page lays out.
///
/// Bodies arrive two ways. The newsroom writes plain text in the admin panel,
/// a paragraph to a line. The stories brought over from the client's
/// WordPress site are its HTML — paragraphs, sub-headings, photos between
/// them, lists whose items open with a bold lead-in — which is what the
/// design's article page draws. Printing that HTML as text would put the tags
/// on the page, so it is read into blocks here, and anything the page has no
/// use for (WordPress's wrappers, classes, scripts) is dropped.
///
/// This is not a general HTML parser. The `html` package is on the machine
/// only as another package's dependency, and a body needs a dozen tags.
library;

enum ArticleBlockKind { paragraph, heading, listItem, image }

/// A run of text within a paragraph.
class ArticleSpan {
  final String text;
  final bool bold;
  final bool italic;

  /// Set when the run is a link.
  final String? href;

  const ArticleSpan(this.text, {this.bold = false, this.italic = false, this.href});
}

class ArticleBlock {
  final ArticleBlockKind kind;
  final List<ArticleSpan> spans;

  /// For [ArticleBlockKind.image].
  final String? src;
  final double? width;
  final double? height;

  const ArticleBlock.text(this.kind, this.spans)
      : src = null,
        width = null,
        height = null;

  const ArticleBlock.image(this.src, {this.width, this.height})
      : kind = ArticleBlockKind.image,
        spans = const [];

  String get plainText => spans.map((s) => s.text).join();
}

final _tag = RegExp(r'<(/?)([a-zA-Z][a-zA-Z0-9]*)([^>]*)>');
final _looksLikeHtml = RegExp(r'<(p|div|br|img|h[1-6]|ul|ol|li|strong|b|a|span|figure)\b', caseSensitive: false);

/// The body's blocks, in order. Empty paragraphs are left out.
List<ArticleBlock> parseArticleBody(String body) {
  final source = body.trim();
  if (source.isEmpty) return const [];
  if (!_looksLikeHtml.hasMatch(source)) return _plainText(source);
  return _html(source);
}

/// Plain text: a paragraph where the author left a blank line, or, when there
/// is none, a paragraph per line.
List<ArticleBlock> _plainText(String source) {
  final text = _decodeEntities(source).replaceAll('\r\n', '\n');
  final parts = RegExp(r'\n\s*\n').hasMatch(text) ? text.split(RegExp(r'\n\s*\n')) : text.split('\n');
  return [
    for (final p in parts.map((p) => p.trim()).where((p) => p.isNotEmpty))
      ArticleBlock.text(ArticleBlockKind.paragraph, [ArticleSpan(p)]),
  ];
}

const _blockTags = {
  'p', 'div', 'section', 'article', 'header', 'footer', 'blockquote', 'figure',
  'figcaption', 'table', 'tr', 'td', 'th', 'tbody', 'thead', 'ul', 'ol', 'pre',
};
const _headingTags = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};
const _skipTags = {'script', 'style', 'iframe', 'noscript', 'svg', 'form', 'button'};

List<ArticleBlock> _html(String source) {
  final blocks = <ArticleBlock>[];
  var spans = <ArticleSpan>[];
  var kind = ArticleBlockKind.paragraph;
  var bold = 0;
  var italic = 0;
  final links = <String?>[];
  String? skipping;

  void flush() {
    // Whitespace in HTML is layout, not content: runs collapse to a space,
    // and a paragraph does not start or end with one. A `<br>` survives as a
    // newline.
    final merged = <ArticleSpan>[];
    for (final s in spans) {
      final t = s.text.replaceAll(RegExp(r'[ \t\r\n\f]+'), ' ');
      if (t.isEmpty) continue;
      merged.add(ArticleSpan(t, bold: s.bold, italic: s.italic, href: s.href));
    }
    // Trim the ends, and the spaces either side of each line break.
    while (merged.isNotEmpty && merged.first.text.trimLeft().isEmpty) {
      merged.removeAt(0);
    }
    while (merged.isNotEmpty && merged.last.text.trimRight().isEmpty) {
      merged.removeLast();
    }
    if (merged.isNotEmpty) {
      final first = merged.first;
      merged[0] = ArticleSpan(first.text.trimLeft(), bold: first.bold, italic: first.italic, href: first.href);
      final last = merged.last;
      merged[merged.length - 1] = ArticleSpan(last.text.trimRight(), bold: last.bold, italic: last.italic, href: last.href);
      for (var i = 0; i < merged.length; i++) {
        final s = merged[i];
        final t = s.text.replaceAll(RegExp(r' *\n *'), '\n');
        if (t != s.text) merged[i] = ArticleSpan(t, bold: s.bold, italic: s.italic, href: s.href);
      }
      final text = merged.map((s) => s.text).join();
      if (text.trim().isNotEmpty) blocks.add(ArticleBlock.text(kind, merged));
    }
    spans = <ArticleSpan>[];
  }

  void addText(String raw) {
    if (raw.isEmpty) return;
    spans.add(ArticleSpan(
      _decodeEntities(raw),
      bold: bold > 0 || kind == ArticleBlockKind.heading,
      italic: italic > 0,
      href: links.isEmpty ? null : links.last,
    ));
  }

  var cursor = 0;
  for (final m in _tag.allMatches(source)) {
    if (skipping == null) addText(source.substring(cursor, m.start));
    cursor = m.end;

    final closing = m.group(1) == '/';
    final name = m.group(2)!.toLowerCase();
    final attrs = m.group(3) ?? '';

    if (skipping != null) {
      if (closing && name == skipping) skipping = null;
      continue;
    }
    if (!closing && _skipTags.contains(name) && !attrs.trimRight().endsWith('/')) {
      skipping = name;
      continue;
    }

    if (name == 'br') {
      spans.add(const ArticleSpan('\n'));
    } else if (name == 'img') {
      final src = _attr(attrs, 'src');
      if (src != null && src.isNotEmpty) {
        flush();
        blocks.add(ArticleBlock.image(
          _decodeEntities(src),
          width: double.tryParse(_attr(attrs, 'width') ?? ''),
          height: double.tryParse(_attr(attrs, 'height') ?? ''),
        ));
      }
    } else if (name == 'b' || name == 'strong') {
      bold += closing ? (bold > 0 ? -1 : 0) : 1;
    } else if (name == 'i' || name == 'em') {
      italic += closing ? (italic > 0 ? -1 : 0) : 1;
    } else if (name == 'a') {
      if (closing) {
        if (links.isNotEmpty) links.removeLast();
      } else {
        final href = _attr(attrs, 'href');
        links.add(href == null ? null : _decodeEntities(href));
      }
    } else if (name == 'li') {
      flush();
      kind = closing ? ArticleBlockKind.paragraph : ArticleBlockKind.listItem;
    } else if (_headingTags.contains(name)) {
      flush();
      kind = closing ? ArticleBlockKind.paragraph : ArticleBlockKind.heading;
    } else if (_blockTags.contains(name)) {
      // A paragraph inside a list item is still that item.
      flush();
    }
  }
  if (skipping == null) addText(source.substring(cursor));
  flush();
  return blocks;
}

String? _attr(String attrs, String name) {
  final m = RegExp('$name\\s*=\\s*("([^"]*)"|\'([^\']*)\'|([^\\s>]+))', caseSensitive: false).firstMatch(attrs);
  if (m == null) return null;
  return m.group(2) ?? m.group(3) ?? m.group(4);
}

const _named = {
  'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ',
  'hellip': '…', 'ndash': '–', 'mdash': '—', 'lsquo': '‘', 'rsquo': '’',
  'ldquo': '“', 'rdquo': '”', 'laquo': '«', 'raquo': '»', 'shy': '',
  'lrm': '\u200E', 'rlm': '\u200F', 'zwnj': '\u200C', 'zwj': '\u200D',
};

String _decodeEntities(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'), (m) {
    final e = m.group(1)!;
    if (e.startsWith('#x') || e.startsWith('#X')) {
      final code = int.tryParse(e.substring(2), radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    if (e.startsWith('#')) {
      final code = int.tryParse(e.substring(1));
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    return _named[e.toLowerCase()] ?? m.group(0)!;
  });
}
