import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';

// ═══════════════════════════════════════════════════════════
// What the web homepage reads beyond the directory's own providers: the site
// notice under the hero, the businesses the "AI Picks" row puts first, and
// the trades the professionals row can be filtered by.
// ═══════════════════════════════════════════════════════════

/// A notice the control centre has put on the homepage — the design's
/// "Traffic update: Road work on Begin St." bar under the hero.
///
/// It is a `home_blocks` row of type `alert`. Its `config` carries the bold
/// label (`title`, else the row's own `title`), the sentence (`message`),
/// where "View details" goes (`url`, a path on this site or an address) and,
/// optionally, the link's wording (`link_label`). Each text may come as
/// `<key>_en` / `<key>_he`, so one notice reads in both languages; a plain
/// `<key>` is shown whichever way the page is set. With no `url` there is no
/// link to draw, so "View details" is left off rather than going nowhere.
class HomeNotice {
  final String id;
  final Map<String, dynamic> _config;
  final String? _title;

  HomeNotice._(this.id, this._title, this._config);

  String? _text(String key, bool hebrew) {
    final lang = _config['${key}_${hebrew ? 'he' : 'en'}'];
    if (lang is String && lang.trim().isNotEmpty) return lang.trim();
    final plain = _config[key];
    if (plain is String && plain.trim().isNotEmpty) return plain.trim();
    return null;
  }

  /// The bold label, or null.
  String? label(bool hebrew) {
    final own = _title?.trim() ?? '';
    return _text('title', hebrew) ?? _text('label', hebrew) ?? (own.isEmpty ? null : own);
  }

  /// The sentence after the label.
  String? message(bool hebrew) =>
      _text('message', hebrew) ?? _text('text', hebrew) ?? _text('body', hebrew);

  /// Where "View details" leads — a page on this site (`/…`) or an address
  /// elsewhere. Null draws no link.
  String? get link {
    for (final key in const ['url', 'link', 'link_url', 'href', 'route']) {
      final v = _config[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// The link's own wording, when the notice gives one.
  String? linkLabel(bool hebrew) => _text('link_label', hebrew) ?? _text('cta', hebrew);
}

/// The notice running now, or null.
///
/// Only published, active rows reach the site (the table's read policy), and
/// of those only one whose `start_at` / `end_at` window holds now, so a
/// road-works notice goes away when the works do without anyone taking it
/// down. A failed read shows no notice: it is never the point of the page.
final homeNoticeProvider = FutureProvider<HomeNotice?>((ref) async {
  try {
    final rows = await SupabaseConfig.client
        .from('home_blocks')
        .select('id, title, config, start_at, end_at, sort_order')
        .eq('block_type', 'alert')
        .eq('is_active', true)
        .eq('published', true)
        .order('sort_order', ascending: true);
    final now = DateTime.now().toUtc();
    for (final r in List<Map<String, dynamic>>.from(rows)) {
      final start = DateTime.tryParse((r['start_at'] as String?) ?? '');
      final end = DateTime.tryParse((r['end_at'] as String?) ?? '');
      if (start != null && start.isAfter(now)) continue;
      if (end != null && end.isBefore(now)) continue;
      final config = r['config'] is Map ? Map<String, dynamic>.from(r['config'] as Map) : <String, dynamic>{};
      final notice = HomeNotice._(r['id'] as String, r['title'] as String?, config);
      if (notice.message(false) == null && notice.label(false) == null) continue;
      return notice;
    }
    return null;
  } catch (_) {
    return null;
  }
});

/// The businesses the homepage recommends: those the control centre has
/// marked `is_recommended`, or `is_featured` inside their `featured_start` /
/// `featured_end` window. Ones with a photograph first.
final homeRecommendedBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  final rows = await SupabaseConfig.client
      .from('businesses')
      .select('''
        *,
        neighborhoods!businesses_neighborhood_id_fkey(id, name, slug)
      ''')
      .eq('status', 'active')
      .or('is_recommended.eq.true,is_featured.eq.true')
      .order('updated_at', ascending: false);
  final now = DateTime.now().toUtc();
  final picked = <Business>[];
  for (final r in List<Map<String, dynamic>>.from(rows)) {
    final recommended = r['is_recommended'] == true;
    if (!recommended) {
      final start = DateTime.tryParse((r['featured_start'] as String?) ?? '');
      final end = DateTime.tryParse((r['featured_end'] as String?) ?? '');
      if (start != null && start.isAfter(now)) continue;
      if (end != null && end.isBefore(now)) continue;
    }
    picked.add(Business.fromJson(r));
  }
  return [
    ...picked.where((b) => (b.imageUrl ?? '').isNotEmpty),
    ...picked.where((b) => (b.imageUrl ?? '').isEmpty),
  ];
});

/// One trade in the professionals row's filter — a category under Services —
/// and the businesses filed under it.
class ProfessionalTrade {
  final BusinessCategory category;
  final Set<String> businessIds;
  const ProfessionalTrade(this.category, this.businessIds);
}

/// Everybody the professionals row can show — whoever is filed under
/// Services or under a trade beneath it — and the trades that have somebody
/// in them, in the categories' own order.
///
/// A trade with nobody filed under it would be a pill that empties the row,
/// so it is left out.
final professionalTradesProvider =
    FutureProvider<({Set<String> everyone, List<ProfessionalTrade> trades})>((ref) async {
      final repo = ref.watch(businessRepositoryProvider);
      final rows = await repo.fetchCategories();
      final all = [for (final r in rows) BusinessCategory.fromJson(r)];
      final services = all.where((c) => c.parentId == null && c.slug == 'services').firstOrNull;
      if (services == null) return (everyone: const <String>{}, trades: const <ProfessionalTrade>[]);

      final children = all.where((c) => c.parentId == services.id).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final links = await repo.fetchCategoryLinks();
      final byCategory = <String, Set<String>>{};
      for (final l in links) {
        byCategory.putIfAbsent(l['category_id'] as String, () => {}).add(l['entity_id'] as String);
      }
      final trades = [
        for (final c in children)
          if ((byCategory[c.id] ?? const {}).isNotEmpty) ProfessionalTrade(c, byCategory[c.id]!),
      ];
      return (
        everyone: {...?byCategory[services.id], for (final t in trades) ...t.businessIds},
        trades: trades,
      );
    });
