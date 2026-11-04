import 'package:flutter/material.dart';

import '../admin_language.dart';
import '../ui/admin_kit.dart';
import 'image_upload_field.dart';

/// The article page's three banners — its start, middle and end (the client,
/// 4 Nov) — as the panel edits them: an article's own (`articles.banners`)
/// in its editor, the defaults (`article_banners` in app_settings) from the
/// Articles screen. The same shape in both, migration 00087:
/// `{ "top": {"image", "mobile", "link"}, "middle": {…}, "end": {…} }`.
class ArticleBannerControllers {
  static const slots = ['top', 'middle', 'end'];

  final Map<String, ({TextEditingController image, TextEditingController mobile, TextEditingController link})> _c;

  ArticleBannerControllers(Object? json)
      : _c = {
          for (final s in slots)
            s: (
              image: TextEditingController(text: _read(json, s, 'image')),
              mobile: TextEditingController(text: _read(json, s, 'mobile')),
              link: TextEditingController(text: _read(json, s, 'link')),
            ),
        };

  static String _read(Object? json, String slot, String key) {
    final b = json is Map ? json[slot] : null;
    final v = b is Map ? b[key] : null;
    return v is String ? v : '';
  }

  /// What is saved: only the slots with a picture, and null when none has
  /// one — an article with no banners of its own shows the defaults.
  Map<String, dynamic>? toJson() {
    final out = <String, dynamic>{};
    for (final s in slots) {
      final c = _c[s]!;
      final image = c.image.text.trim();
      if (image.isEmpty) continue;
      String? opt(TextEditingController t) => t.text.trim().isEmpty ? null : t.text.trim();
      out[s] = {'image': image, 'mobile': opt(c.mobile), 'link': opt(c.link)};
    }
    return out.isEmpty ? null : out;
  }

  void dispose() {
    for (final c in _c.values) {
      c.image.dispose();
      c.mobile.dispose();
      c.link.dispose();
    }
  }
}

/// The three slots' fields. [hint] says what an empty slot shows: the
/// defaults in an article's editor, nothing on the defaults screen.
class ArticleBannerFields extends StatelessWidget {
  final ArticleBannerControllers controllers;
  final String hint;

  const ArticleBannerFields({super.key, required this.controllers, required this.hint});

  static String _slotName(String slot) => switch (slot) {
        'top' => tr('ראש הכתבה — מעל הטקסט', 'Top — above the text'),
        'middle' => tr('אמצע הכתבה — בין הפסקאות (בכתבה של 4 פסקאות ומעלה)', 'Middle — between paragraphs (4 paragraphs or more)'),
        _ => tr('סוף הכתבה — מתחת לטקסט', 'End — below the text'),
      };

  /// Empty, or a web address: the site shows nothing else as a link.
  static String? _webOrEmpty(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty || RegExp(r'^https?://', caseSensitive: false).hasMatch(t)) return null;
    return tr('כתובת שמתחילה ב-https://', 'An address starting with https://');
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('גודל מומלץ: למחשב 796×228, לטלפון למשל 800×500. בלי תמונה לטלפון מוצגת תמונת המחשב. $hint',
              'Recommended: desktop 796×228, phone e.g. 800×500. Without a phone image the desktop one is shown. $hint'),
          style: k.hint.copyWith(fontSize: 12),
        ),
        for (final slot in ArticleBannerControllers.slots) ...[
          const SizedBox(height: 20),
          Text(_slotName(slot), style: k.label),
          const SizedBox(height: 10),
          ImageUploadField(
            label: tr('תמונה למחשב', 'Desktop image'),
            controller: controllers._c[slot]!.image,
            folder: 'articles/banners',
          ),
          const SizedBox(height: 12),
          ImageUploadField(
            label: tr('תמונה לטלפון (לא חובה)', 'Phone image (optional)'),
            controller: controllers._c[slot]!.mobile,
            folder: 'articles/banners',
          ),
          const SizedBox(height: 12),
          AdminField(
            label: tr('קישור (לא חובה)', 'Link (optional)'),
            controller: controllers._c[slot]!.link,
            hint: 'https://',
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            validator: _webOrEmpty,
          ),
        ],
      ],
    );
  }
}
