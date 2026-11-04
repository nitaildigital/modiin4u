import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/supabase/supabase_config.dart';

/// One of an article's three banners — its top, middle or end (the client,
/// 4 Nov; migration 00087) — as the website shows them.
class ArticleBannerData {
  final String image;
  final String? mobile;
  final String? link;
  const ArticleBannerData({required this.image, this.mobile, this.link});
}

/// The defaults set from the panel's Articles screen (`article_banners` in
/// app_settings), read on each article opened so a change shows without
/// restarting the app. Null when unset or unreadable.
final articleBannerDefaultsProvider = FutureProvider.autoDispose<Object?>((ref) async {
  try {
    final row = await SupabaseConfig.client.from('app_settings').select('value').eq('key', 'article_banners').maybeSingle();
    return row?['value'];
  } catch (_) {
    return null;
  }
});

String? _web(Object? v) {
  final t = v is String ? v.trim() : '';
  return RegExp(r'^https?://', caseSensitive: false).hasMatch(t) ? t : null;
}

/// [slot]'s banner — `top`, `middle` or `end`: the article's own ([own], its
/// `banners`), or else the default. Only a web address counts, for the
/// picture as for the link, as on the website.
ArticleBannerData? articleBanner(Object? own, Object? defaults, String slot) {
  for (final source in [own, defaults]) {
    final b = source is Map ? source[slot] : null;
    final image = b is Map ? _web(b['image']) : null;
    if (image != null) return ArticleBannerData(image: image, mobile: _web((b as Map)['mobile']), link: _web(b['link']));
  }
  return null;
}

/// The banner, the column's width at its own proportions; its phone image
/// on a phone-wide screen (the website's 1100 px), and opening its link.
class ArticleBanner extends StatelessWidget {
  final ArticleBannerData banner;
  const ArticleBanner({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 1100;
    final url = phone ? (banner.mobile ?? banner.image) : banner.image;
    final link = banner.link;
    final picture = Semantics(
      label: Localizations.localeOf(context).languageCode == 'he' ? 'פרסומת' : 'Advertisement',
      image: true,
      link: link != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          // A banner that cannot be fetched takes no room.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
    if (link == null) return picture;
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
      child: picture,
    );
  }
}
