import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

/// One of the fixed information pages the client writes in the panel
/// (עמודי מידע, migration 00037): About Us and the Accessibility Statement.
class SitePage {
  final String slug;
  final String titleHe;
  final String titleEn;
  final String bodyHe;
  final String bodyEn;
  final DateTime? updatedAt;

  const SitePage({
    required this.slug,
    required this.titleHe,
    required this.titleEn,
    required this.bodyHe,
    required this.bodyEn,
    this.updatedAt,
  });

  factory SitePage.fromRow(Map<String, dynamic> r) => SitePage(
    slug: r['slug'] as String? ?? '',
    titleHe: (r['title_he'] as String? ?? '').trim(),
    titleEn: (r['title_en'] as String? ?? '').trim(),
    bodyHe: (r['body_he'] as String? ?? '').trim(),
    bodyEn: (r['body_en'] as String? ?? '').trim(),
    updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '')?.toLocal(),
  );

  /// Which language the page is read in: the reader's, unless the client
  /// wrote only the other one — then that one, rather than an empty page.
  /// Null when neither body has been written.
  bool? contentIsHebrew(bool wantHebrew) {
    final wanted = wantHebrew ? bodyHe : bodyEn;
    final other = wantHebrew ? bodyEn : bodyHe;
    if (wanted.isNotEmpty) return wantHebrew;
    if (other.isNotEmpty) return !wantHebrew;
    return null;
  }

  String body(bool hebrew) => hebrew ? bodyHe : bodyEn;

  /// The title in [hebrew], or the other language's when that one is empty.
  String title(bool hebrew) {
    final wanted = hebrew ? titleHe : titleEn;
    return wanted.isNotEmpty ? wanted : (hebrew ? titleEn : titleHe);
  }
}

/// The published page with this slug, or null while it is not published.
///
/// Published is asked for explicitly: an administrator signed in on the site
/// may read drafts (the panel needs to), and the public page must still show
/// him what residents see. Disposed with the page, so coming back after the
/// client publishes reads it again.
final sitePageProvider = FutureProvider.autoDispose.family<SitePage?, String>((
  ref,
  slug,
) async {
  final row = await SupabaseConfig.client
      .from('site_pages')
      .select('slug, title_he, title_en, body_he, body_en, updated_at')
      .eq('slug', slug)
      .eq('is_published', true)
      .maybeSingle();
  return row == null ? null : SitePage.fromRow(row);
});
