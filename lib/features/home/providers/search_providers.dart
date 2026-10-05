import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../../events/models/event.dart';
import '../../events/providers/event_providers.dart';
import '../../news/models/article.dart';
import '../../news/providers/news_providers.dart';
import '../../deals/providers/offer_providers.dart';
import '../../realestate/providers/listing_providers.dart';

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

/// Search across businesses (parks too), events still to come, deals,
/// property listings and news. Deals and listings were left out, and events
/// that had ended came up beside ones to come.
///
/// The filtering happens in the database rather than over a list held in the
/// app, so it covers everything in each table, not just what is on screen.
final searchResultsProvider =
    FutureProvider.family<List<SearchHit>, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final results = await Future.wait([
    ref.watch(businessRepositoryProvider).fetchAll(status: 'active', search: q, kind: null),
    ref.watch(articleRepositoryProvider).fetchAll(status: 'published', search: q),
    ref.watch(eventRepositoryProvider).fetchAll(search: q),
  ]);
  final listings = await ref.watch(listingRepositoryProvider).fetchActive(search: q);
  final needle = q.toLowerCase();
  final offers = (await ref.watch(activeOffersProvider.future)).where(
    (o) =>
        !o.hasExpired &&
        [o.name, o.businessName, o.description]
            .any((t) => (t ?? '').toLowerCase().contains(needle)),
  );

  final businesses = results[0].map(Business.fromJson);
  final articles = results[1].map(Article.fromJson);
  // An event is still to come until the day it ends (or starts, when it
  // gives no end) is over, so one running today is found.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final events = results[2].map(Event.fromJson).where((e) {
    final last = (e.endDate ?? e.startDate)?.toLocal();
    return last == null || !DateTime(last.year, last.month, last.day).isBefore(today);
  });

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
    for (final o in offers)
      SearchHit(
        title: o.name,
        subtitle: o.businessName ?? '',
        icon: IconsaxPlusLinear.ticket_discount,
        route: '/deal/${o.id}',
        category: 'הטבה',
        imageUrl: o.imageUrl,
      ),
    for (final l in listings)
      SearchHit(
        title: l.title,
        subtitle: [l.address, l.neighborhoodName]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' · '),
        icon: IconsaxPlusLinear.building_3,
        route: '/listing/${l.id}',
        category: 'נדל״ן',
        imageUrl: l.coverUrl,
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
