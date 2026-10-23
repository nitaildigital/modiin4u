import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Pasted HTML made readable for the article editor.
///
/// Text copied from Google Docs reached the editor as one paragraph, all of
/// it bold and its headings flattened (the client, 23 Oct). Docs marks its
/// formatting in a way the editor's HTML reader does not follow: the whole
/// copy sits inside `<b style="font-weight:normal">`, which the reader takes
/// for bold, and bold and italic runs are `<span>`s with a style
/// (`font-weight:700`) rather than `<b>` and `<i>`. Word and other editors
/// do the same with styles.
///
/// So before the editor reads it: the "not bold" wrappers are unwrapped, a
/// bold or italic span becomes `<strong>` or `<em>`, and what the article page
/// never draws (fonts, sizes, colours, underline, Docs' own markers) is
/// dropped — the editor offers bold and italic only, for the same reason. Its
/// headings (`<h1>`–`<h3>`), lists, links and paragraphs pass through as they
/// were.
String cleanPastedHtml(String html) {
  final doc = html_parser.parse(html);
  final body = doc.body;
  if (body == null) return html;

  body.querySelectorAll('meta, style, script, link, title').forEach((e) => e.remove());

  // Outermost first, so a wrapper inside a wrapper is reached after its
  // parent has already been unwrapped.
  for (final el in body.querySelectorAll('*').toList()) {
    final name = el.localName;
    final style = _styles(el.attributes['style']);

    // `<b>` / `<strong>` that say they are not bold: Docs' wrapper.
    if ((name == 'b' || name == 'strong') && _notBold(style['font-weight'])) {
      _unwrap(el);
      continue;
    }

    if (name == 'span' || name == 'font') {
      final tags = [
        if (_isBold(style['font-weight'])) 'strong',
        if ((style['font-style'] ?? '').contains('italic')) 'em',
      ];
      if (tags.isEmpty) {
        _unwrap(el);
        continue;
      }
      // <strong><em>…</em></strong>, the span's text inside the innermost.
      final outer = dom.Element.tag(tags.first);
      var inner = outer;
      for (final t in tags.skip(1)) {
        final e = dom.Element.tag(t);
        inner.append(e);
        inner = e;
      }
      inner.nodes.addAll(el.nodes.toList());
      el.replaceWith(outer);
      continue;
    }

    // A heading Docs styled as normal text stays a heading; only its own
    // inline styles go.
    el.attributes.remove('style');
    el.attributes.remove('class');
    el.attributes.remove('id');
    el.attributes.remove('dir');
  }

  return body.innerHtml;
}

Map<String, String> _styles(String? style) {
  final out = <String, String>{};
  for (final part in (style ?? '').split(';')) {
    final i = part.indexOf(':');
    if (i <= 0) continue;
    out[part.substring(0, i).trim().toLowerCase()] = part.substring(i + 1).trim().toLowerCase();
  }
  return out;
}

bool _isBold(String? weight) {
  if (weight == null) return false;
  if (weight == 'bold' || weight == 'bolder') return true;
  final n = int.tryParse(weight);
  return n != null && n >= 600;
}

bool _notBold(String? weight) {
  if (weight == null) return false;
  if (weight == 'normal' || weight == 'lighter') return true;
  final n = int.tryParse(weight);
  return n != null && n < 600;
}

void _unwrap(dom.Element el) {
  final parent = el.parentNode;
  if (parent == null) return;
  for (final child in el.nodes.toList()) {
    parent.insertBefore(child, el);
  }
  el.remove();
}
