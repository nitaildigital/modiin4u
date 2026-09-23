import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../../events/models/event.dart';
import '../../events/providers/event_providers.dart';
import '../../news/models/article.dart';
import '../../news/providers/news_providers.dart';

/// One row in the search results, whatever it came from.
class SearchHit {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String category;

  /// The record's photo, when it carries one; the tile falls back to `icon`.
  final String? imageUrl;

  const SearchHit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.category,
    this.imageUrl,
  });
}

/// Search across businesses, news and events.
///
/// The filtering happens in the database rather than over a list held in the
/// app, so it covers everything in each table, not just what is on screen.
final searchResultsProvider =
    FutureProvider.family<List<SearchHit>, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final results = await Future.wait([
    ref.watch(businessRepositoryProvider).fetchAll(status: 'active', search: q),
    ref.watch(articleRepositoryProvider).fetchAll(status: 'published', search: q),
    ref.watch(eventRepositoryProvider).fetchAll(search: q),
  ]);

  final businesses = results[0].map(Business.fromJson);
  final articles = results[1].map(Article.fromJson);
  final events = results[2].map(Event.fromJson);

  return [
    for (final b in businesses)
      SearchHit(
        title: b.name,
        subtitle: [b.description, b.neighborhood]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' · '),
        icon: IconsaxPlusLinear.shop,
        route: '/business/${b.id}',
        category: 'עסק',
        imageUrl: b.imageUrl,
      ),
    for (final e in events)
      SearchHit(
        title: e.title,
        subtitle: [e.venueName, e.displayTime]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' · '),
        icon: IconsaxPlusLinear.calendar_1,
        route: '/event/${e.id}',
        category: 'אירוע',
        imageUrl: e.imageUrl,
      ),
    for (final a in articles)
      SearchHit(
        title: a.title,
        subtitle: a.excerpt ?? a.subtitle ?? '',
        icon: IconsaxPlusLinear.document_text,
        route: '/article/${a.id}',
        category: 'חדשות',
        imageUrl: a.imageUrl,
      ),
  ];
});
