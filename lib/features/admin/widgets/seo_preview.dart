import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// What the website will put in Google for a page, read from the editor's
/// fields as they are now.
typedef SeoSnapshot = ({
  /// The title as the site sets it: the SEO title, else the name with the
  /// site's suffix.
  String title,
  bool ownTitle,

  /// The description as the site sets it: the meta description, else the
  /// start of the page's text.
  String description,
  bool ownDescription,

  /// The page's address on the site, e.g. `/news/<slug>/`.
  String path,

  /// The focus keyword, where the editor has one (articles).
  String? keyword,

  /// The page's text, for the keyword and length checks (articles).
  String? text,
});

/// The site's title suffix (tool/seo/site.json `title_suffix`), which a page
/// without its own SEO title gets after its name.
const seoTitleSuffix = ' - מודיעין בשבילך';

/// Plain text from stored HTML, folded, as the site's `plain()` makes it.
String seoPlain(String? html, [int? limit]) {
  var t = (html ?? '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'&#039;|&#8217;'), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (limit != null && t.length > limit) {
    t = '${t.substring(0, limit).replaceAll(RegExp(r'\s+\S*$'), '')}…';
  }
  return t;
}

/// A Google result as the page will show in it, and the checks Yoast ran on
/// WordPress: the title and description at a length Google shows whole, and,
/// with a focus keyword, whether the title, description, address and text
/// carry it. Updates as the fields are typed in.
class AdminSeoPreview extends StatelessWidget {
  /// The fields the snapshot reads; the preview redraws when any changes.
  final Listenable listenTo;
  final SeoSnapshot Function() read;

  const AdminSeoPreview({super.key, required this.listenTo, required this.read});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenTo,
      builder: (context, _) {
        final s = read();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Snippet(s),
            const SizedBox(height: 12),
            for (final c in _checks(s)) _CheckRow(c),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

enum _Level { good, ok, bad }

typedef _Check = ({_Level level, String text});

/// Google shows about 60 characters of a title and 160 of a description
/// before it cuts them; Yoast measured the same.
const _titleMax = 60;
const _descriptionMin = 120;
const _descriptionMax = 160;

List<_Check> _checks(SeoSnapshot s) {
  final out = <_Check>[];
  final t = s.title.length;
  out.add(switch (t) {
    _ when t > _titleMax + 10 => (level: _Level.bad, text: tr('הכותרת ארוכה ($t תווים) — גוגל יחתוך אותה. עד $_titleMax.', 'The title is long ($t characters) — Google will cut it. Up to $_titleMax.')),
    _ when t > _titleMax => (level: _Level.ok, text: tr('הכותרת קצת ארוכה ($t תווים) — ייתכן שתיחתך. עד $_titleMax.', 'The title is a little long ($t characters) — it may be cut. Up to $_titleMax.')),
    _ when t < 30 => (level: _Level.ok, text: tr('הכותרת קצרה ($t תווים) — יש מקום לעוד מילה שמחפשים.', 'The title is short ($t characters) — there is room for another word people search for.')),
    _ => (level: _Level.good, text: tr('אורך הכותרת טוב ($t תווים).', 'The title length is good ($t characters).')),
  });
  if (!s.ownTitle) {
    out.add((level: _Level.ok, text: tr('אין כותרת SEO — מוצג השם עם סיומת האתר.', "No SEO title — the name with the site's suffix is shown.")));
  }

  final d = s.description.length;
  if (d == 0) {
    out.add((level: _Level.bad, text: tr('אין תיאור — גוגל יבחר קטע מהעמוד בעצמו.', 'No description — Google will pick a piece of the page itself.')));
  } else {
    if (!s.ownDescription) {
      out.add((level: _Level.ok, text: tr('אין תיאור מטא — נלקחת תחילת הטקסט. תיאור שנכתב לגוגל מושך יותר הקלקות.', 'No meta description — the start of the text is used. One written for Google draws more clicks.')));
    }
    out.add(switch (d) {
      _ when d > _descriptionMax => (level: _Level.ok, text: tr('התיאור ארוך ($d תווים) — גוגל יחתוך אחרי כ-$_descriptionMax.', 'The description is long ($d characters) — Google cuts after about $_descriptionMax.')),
      _ when d < _descriptionMin => (level: _Level.ok, text: tr('התיאור קצר ($d תווים) — $_descriptionMin עד $_descriptionMax מנצלים את המקום.', 'The description is short ($d characters) — $_descriptionMin to $_descriptionMax use the space.')),
      _ => (level: _Level.good, text: tr('אורך התיאור טוב ($d תווים).', 'The description length is good ($d characters).')),
    });
  }

  final keyword = s.keyword?.trim() ?? '';
  if (s.keyword != null) {
    if (keyword.isEmpty) {
      out.add((level: _Level.ok, text: tr('אין ביטוי מפתח — הוסיפו אחד כדי לבדוק אותו.', 'No focus keyword — add one to check it.')));
    } else {
      final k = keyword.toLowerCase();
      bool has(String v) => v.toLowerCase().contains(k);
      final slugged = k.replaceAll(RegExp(r'\s+'), '-');
      String path;
      try {
        path = Uri.decodeFull(s.path).toLowerCase();
      } catch (_) {
        path = s.path.toLowerCase();
      }
      out.add(has(s.title)
          ? (level: _Level.good, text: tr('ביטוי המפתח מופיע בכותרת.', 'The focus keyword is in the title.'))
          : (level: _Level.bad, text: tr('ביטוי המפתח לא מופיע בכותרת.', 'The focus keyword is not in the title.')));
      out.add(has(s.description)
          ? (level: _Level.good, text: tr('ביטוי המפתח מופיע בתיאור.', 'The focus keyword is in the description.'))
          : (level: _Level.ok, text: tr('ביטוי המפתח לא מופיע בתיאור.', 'The focus keyword is not in the description.')));
      out.add(path.contains(slugged) || path.contains(k)
          ? (level: _Level.good, text: tr('ביטוי המפתח מופיע בכתובת.', 'The focus keyword is in the address.'))
          : (level: _Level.ok, text: tr('ביטוי המפתח לא מופיע בכתובת.', 'The focus keyword is not in the address.')));
      if (s.text != null) {
        final times = k.isEmpty ? 0 : RegExp(RegExp.escape(k)).allMatches(s.text!.toLowerCase()).length;
        out.add(times == 0
            ? (level: _Level.bad, text: tr('ביטוי המפתח לא מופיע בטקסט.', 'The focus keyword is not in the text.'))
            : (level: _Level.good, text: tr('ביטוי המפתח מופיע בטקסט $times פעמים.', 'The focus keyword appears in the text $times times.')));
      }
    }
  }

  if (s.text != null) {
    final words = s.text!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    out.add(words >= 300
        ? (level: _Level.good, text: tr('אורך הטקסט טוב ($words מילים).', 'The text length is good ($words words).'))
        : (level: _Level.ok, text: tr('הטקסט קצר ($words מילים) — מ-300 מילים גוגל רואה בו עמוד מלא.', 'The text is short ($words words) — from 300 words Google sees a full page.')));
  }
  return out;
}

class _Snippet extends StatelessWidget {
  final SeoSnapshot s;
  const _Snippet(this.s);

  String _cut(String v, int max) =>
      v.length <= max ? v : '${v.substring(0, max).replaceAll(RegExp(r'\s+\S*$'), '')} …';

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    String path;
    try {
      path = Uri.decodeFull(s.path);
    } catch (_) {
      path = s.path;
    }
    final crumbs = path.split('/').where((p) => p.isNotEmpty).join(' › ');
    // The page is Hebrew whatever language the panel is in.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: k.surface,
          border: Border.all(color: k.border),
          borderRadius: BorderRadius.circular(k.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('תצוגה בגוגל', 'Google preview'), style: k.hint.copyWith(fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              'www.modiin4u.co.il${crumbs.isEmpty ? '' : ' › $crumbs'}',
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: const Color(0xFF4D5156)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _cut(s.title, _titleMax),
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 18, color: const Color(0xFF1A0DAB), height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              s.description.isEmpty ? '—' : _cut(s.description, _descriptionMax),
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: const Color(0xFF4D5156), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final _Check c;
  const _CheckRow(this.c);

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final color = switch (c.level) {
      _Level.good => k.success,
      _Level.ok => k.warning,
      _Level.bad => k.danger,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(c.text, style: k.body.copyWith(fontSize: 12.5))),
        ],
      ),
    );
  }
}
