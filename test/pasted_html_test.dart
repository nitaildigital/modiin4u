import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/admin/widgets/pasted_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

/// What the article editor would save after this paste: the HTML read into
/// the editor and written out again, as admin_rich_editor.dart does.
String saved(String html) {
  final ops = HtmlToDelta().convert(html).toJson().cast<Map<String, dynamic>>();
  return QuillDeltaToHtmlConverter(
    ops,
    ConverterOptions(
      multiLineParagraph: false,
      converterOptions: OpConverterOptions(inlineStylesFlag: false),
    ),
  ).convert();
}

void main() {
  // What Google Docs puts on the clipboard (23 Oct): everything inside a
  // "not bold" <b>, formatting as styled spans.
  const docs =
      '<meta charset="utf-8"><b style="font-weight:normal;" id="docs-internal-guid-ab12">'
      '<h2 dir="rtl"><span style="font-size:16pt;font-weight:400;">פרשת לך לך</span></h2>'
      '<p dir="rtl"><span style="font-weight:400;">פותחת ב</span>'
      '<span style="font-weight:700;">ניסיון קשה</span>'
      '<span style="font-weight:400;"> ו</span>'
      '<span style="font-style:italic;font-weight:400;">נטוי</span></p>'
      '<ul><li dir="rtl"><p dir="rtl"><span style="font-weight:400;">פריט</span></p></li></ul>'
      '<p dir="rtl"><a href="https://www.modiin4u.co.il/">'
      '<span style="text-decoration:underline;font-weight:400;">קישור</span></a></p></b>';

  test('a Google Docs paste keeps its headings, bold, italic, lists and links', () {
    final html = saved(cleanPastedHtml(docs));
    expect(html, contains('<h2>פרשת לך לך</h2>'));
    expect(html, contains('<strong>ניסיון קשה</strong>'));
    expect(html, contains('<em>נטוי</em>'));
    expect(html, contains('<ul><li>פריט</li></ul>'));
    expect(html, contains('<a href="https://www.modiin4u.co.il/"'));
    expect(html, isNot(contains('<u>')));
  });

  test('without the tidy-up it was one bold paragraph', () {
    final html = saved(docs);
    expect(html, isNot(contains('<h2>')));
    expect(html, startsWith('<p><strong>'));
  });

  test('ordinary HTML and Word-style bold pass through', () {
    expect(saved(cleanPastedHtml('<h2>כותרת</h2><p>טקסט <strong>מודגש</strong></p>')),
        '<h2>כותרת</h2><p>טקסט <strong>מודגש</strong></p>');
    expect(saved(cleanPastedHtml('<p class=MsoNormal><span style="font-weight:bold">מודגש</span> רגיל</p>')),
        '<p><strong>מודגש</strong> רגיל</p>');
  });
}
