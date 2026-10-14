import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// The text of an information page, laid out from the three conventions the
/// panel describes: a line starting "# " or "## " is a heading, a line
/// starting "- " (or "* ") is a list item, and a blank line starts a new
/// paragraph. Lines inside a paragraph keep their breaks — an address or a
/// list of contact details is written one line under the other.
///
/// Web addresses and e-mail addresses are links, because an accessibility
/// statement has to give a way to reach the person responsible for it.
///
/// The panel's preview draws with this same widget, so what the client sees
/// before publishing is what the page shows.
class SitePageBody extends StatefulWidget {
  final String text;

  /// The size of paragraph text; headings are scaled from it.
  final double fontSize;
  final double lineHeight;

  const SitePageBody({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.lineHeight = 1.75,
  });

  @override
  State<SitePageBody> createState() => _SitePageBodyState();
}

sealed class _Block {
  const _Block();
}

class _Heading extends _Block {
  final String text;
  final int level;
  const _Heading(this.text, this.level);
}

class _Bullet extends _Block {
  final String text;
  const _Bullet(this.text);
}

class _Divider extends _Block {
  const _Divider();
}

class _Paragraph extends _Block {
  final String text;
  const _Paragraph(this.text);
}

/// Splits the text into headings, list items, dividers and paragraphs.
List<_Block> _parse(String text) {
  final blocks = <_Block>[];
  final paragraph = <String>[];

  void flush() {
    if (paragraph.isNotEmpty) {
      blocks.add(_Paragraph(paragraph.join('\n')));
      paragraph.clear();
    }
  }

  for (final raw in text.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flush();
    } else if (line == '---' || line == '***' || line == '___' || line == '--') {
      flush();
      blocks.add(const _Divider());
    } else if (line.startsWith('## ')) {
      flush();
      blocks.add(_Heading(line.substring(3).trim(), 2));
    } else if (line.startsWith('# ')) {
      flush();
      blocks.add(_Heading(line.substring(2).trim(), 1));
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      flush();
      blocks.add(_Bullet(line.substring(2).trim()));
    } else {
      paragraph.add(line);
    }
  }
  flush();
  return blocks;
}

final _linkPattern = RegExp(
  r'(https?://[^\s]+|www\.[^\s]+|[\w.+-]+@[\w-]+(\.[\w-]+)+)',
);

class _SitePageBodyState extends State<SitePageBody> {
  /// Tap handlers for the links, released when the text is laid out again
  /// and when the page closes.
  final _recognizers = <TapGestureRecognizer>[];

  void _releaseRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _releaseRecognizers();
    super.dispose();
  }

  Uri _uriFor(String link) {
    if (link.contains('@') && !link.contains('/')) {
      return Uri(scheme: 'mailto', path: link);
    }
    return Uri.parse(link.startsWith('www.') ? 'https://$link' : link);
  }

  /// Turns URLs and emails into clickable links.
  List<InlineSpan> _linkify(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in _linkPattern.allMatches(text)) {
      var link = m.group(0)!;
      final trailing =
          RegExp(r'[.,;:!?)\]]+$').firstMatch(link)?.group(0) ?? '';
      link = link.substring(0, link.length - trailing.length);
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start), style: style));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => launchUrl(_uriFor(link));
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: link,
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
          style: style.copyWith(
            color: AppColors.midBlue,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.midBlue,
          ),
        ),
      );
      start = m.start + link.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return spans;
  }

  /// [text] with **bold** markers rendered as bold text and web/email addresses made into links.
  List<InlineSpan> _spans(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;

    for (final m in boldPattern.allMatches(text)) {
      if (m.start > start) {
        spans.addAll(_linkify(text.substring(start, m.start), style));
      }
      final boldText = m.group(1)!;
      final boldStyle = style.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0A1230),
      );
      spans.addAll(_linkify(boldText, boldStyle));
      start = m.end;
    }

    if (start < text.length) {
      spans.addAll(_linkify(text.substring(start), style));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _releaseRecognizers();
    final base = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: const Color(0xFF1C1C1E),
    );
    final blocks = _parse(widget.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(
              top: i == 0
                  ? 0
                  : switch (blocks[i]) {
                      _Divider() => widget.fontSize * 0.75,
                      _Heading() => widget.fontSize * 1.75,
                      _Bullet() when blocks[i - 1] is _Bullet =>
                        widget.fontSize * 0.35,
                      _ => widget.fontSize * 0.9,
                    },
            ),
            child: _buildBlock(blocks[i], base),
          ),
      ],
    );
  }

  Widget _buildBlock(_Block block, TextStyle base) {
    switch (block) {
      case _Divider():
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE5E5EA),
          ),
        );
      case _Heading(:final text, :final level):
        final style = base.copyWith(
          fontSize: widget.fontSize * (level == 1 ? 1.5 : 1.25),
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: const Color(0xFF0A1230),
        );
        return Semantics(
          header: true,
          child: Text.rich(TextSpan(children: _spans(text, style)), style: style),
        );
      case _Bullet(:final text):
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: widget.fontSize * 1.4,
              child: Text('•', style: base, textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text.rich(TextSpan(children: _spans(text, base)), style: base),
            ),
          ],
        );
      case _Paragraph(:final text):
        return Text.rich(TextSpan(children: _spans(text, base)), style: base);
    }
  }
}
