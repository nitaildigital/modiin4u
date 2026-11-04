import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

/// An article's HTML read into the panel's editor.
///
/// The HTML reader (flutter_quill_delta_from_html) takes `<p>` for inline
/// text and starts a new line only before a heading, list, div, quote or
/// code block, so `<p>one</p><p>two</p>` came in as the one line "onetwo".
/// An article opened in the editor showed its paragraphs run together, and
/// typing anything saved them as one paragraph, which also dropped the
/// article page's middle banner, placed between paragraphs (found 4 Nov).
///
/// Here every top-level element that is not inline text — paragraphs,
/// headings, lists, quotes, rules, tables, figures — starts its own line.
Delta editorDelta(String html) =>
    HtmlToDelta(isBlockValidator: _startsLine).convert(html);

bool _startsLine(String name) => !_inline.contains(name);

/// Text-level tags, and the reader's name for bare text, which continue the
/// line they are on.
const _inline = {
  'text-node',
  'a',
  'b',
  'strong',
  'i',
  'em',
  'u',
  'ins',
  's',
  'del',
  'sub',
  'sup',
  'span',
  'font',
  'br',
  'img',
  'small',
  'mark',
  'abbr',
  'cite',
  'q',
};
