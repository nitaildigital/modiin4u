import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

/// What can be saved. The `favorites` table keys rows by this plus the id, so
/// one business and one article can share an id without colliding.
enum FavoriteKind { business, article, event, listing }

extension FavoriteKindValue on FavoriteKind {
  String get value => switch (this) {
    FavoriteKind.business => 'business',
    FavoriteKind.article => 'article',
    FavoriteKind.event => 'event',
    FavoriteKind.listing => 'listing',
  };
}

class FavoriteRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Everything this person has saved, as `type:id` keys.
  Future<Set<String>> fetchKeys(String profileId) async {
    final rows = await _client
        .from('favorites')
        .select('entity_type, entity_id')
        .eq('profile_id', profileId);

    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        '${row['entity_type']}:${row['entity_id']}',
    };
  }

  Future<void> add(String profileId, FavoriteKind kind, String id) {
    return _client.from('favorites').upsert({
      'profile_id': profileId,
      'entity_type': kind.value,
      'entity_id': id,
    }, onConflict: 'profile_id,entity_type,entity_id');
  }

  Future<void> remove(String profileId, FavoriteKind kind, String id) {
    return _client
        .from('favorites')
        .delete()
        .eq('profile_id', profileId)
        .eq('entity_type', kind.value)
        .eq('entity_id', id);
  }
}

/// One saved thing, flattened so the Favourites screen can list businesses,
/// events and articles together without caring which table each came from.
class FavoriteEntry {
  final FavoriteKind kind;
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String route;
  final double? rating;
  final int? reviewCount;
  final DateTime? date;

  const FavoriteEntry({
    required this.kind,
    required this.id,
    required this.title,
    required this.route,
    this.subtitle,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.date,
  });
}

extension FavoriteResolve on FavoriteRepository {
  /// Reads the saved rows back out of their own tables.
  ///
  /// One query per kind rather than one per saved item, and a kind with
  /// nothing saved is not queried at all.
  Future<List<FavoriteEntry>> resolve(Set<String> keys) async {
    List<String> idsOf(FavoriteKind kind) {
      final prefix = '${kind.value}:';
      return [
        for (final k in keys)
          if (k.startsWith(prefix)) k.substring(prefix.length),
      ];
    }

    final client = SupabaseConfig.client;
    final businessIds = idsOf(FavoriteKind.business);
    final eventIds = idsOf(FavoriteKind.event);
    final articleIds = idsOf(FavoriteKind.article);
    final listingIds = idsOf(FavoriteKind.listing);

    final results = await Future.wait([
      businessIds.isEmpty
          ? Future.value(const <Map<String, dynamic>>[])
          : client
                .from('businesses')
                .select(
                  'id, name, short_description, address, cover_url, '
                  'og_image_url, rating, review_count',
                )
                .inFilter('id', businessIds)
                .then(List<Map<String, dynamic>>.from),
      eventIds.isEmpty
          ? Future.value(const <Map<String, dynamic>>[])
          : client
                .from('events')
                .select('id, title, venue_name, address, image_url, start_date')
                .inFilter('id', eventIds)
                .then(List<Map<String, dynamic>>.from),
      articleIds.isEmpty
          ? Future.value(const <Map<String, dynamic>>[])
          : client
                .from('articles')
                .select('id, title, excerpt, featured_image, published_at')
                .inFilter('id', articleIds)
                .then(List<Map<String, dynamic>>.from),
      listingIds.isEmpty
          ? Future.value(const <Map<String, dynamic>>[])
          : client
                .from('listings')
                .select(
                  'id, title, address, cover_url, price, price_per_month, '
                  'kind, created_at',
                )
                .inFilter('id', listingIds)
                .then(List<Map<String, dynamic>>.from),
    ]);

    String? text(Object? v) {
      final s = v as String?;
      return (s == null || s.isEmpty) ? null : s;
    }

    return [
      for (final r in results[0])
        FavoriteEntry(
          kind: FavoriteKind.business,
          id: r['id'] as String,
          title: (r['name'] as String?) ?? '',
          subtitle: text(r['short_description']) ?? text(r['address']),
          imageUrl: text(r['cover_url']) ?? text(r['og_image_url']),
          route: '/business/${r['id']}',
          rating: (r['rating'] as num?)?.toDouble(),
          reviewCount: (r['review_count'] as num?)?.toInt(),
        ),
      for (final r in results[1])
        FavoriteEntry(
          kind: FavoriteKind.event,
          id: r['id'] as String,
          title: (r['title'] as String?) ?? '',
          subtitle: text(r['venue_name']) ?? text(r['address']),
          imageUrl: text(r['image_url']),
          route: '/event/${r['id']}',
          date: DateTime.tryParse(r['start_date'] as String? ?? ''),
        ),
      for (final r in results[2])
        FavoriteEntry(
          kind: FavoriteKind.article,
          id: r['id'] as String,
          title: (r['title'] as String?) ?? '',
          subtitle: text(r['excerpt']),
          imageUrl: text(r['featured_image']),
          route: '/article/${r['id']}',
          date: DateTime.tryParse(r['published_at'] as String? ?? ''),
        ),
      for (final r in results[3])
        FavoriteEntry(
          kind: FavoriteKind.listing,
          id: r['id'] as String,
          title: (r['title'] as String?) ?? '',
          subtitle: text(r['address']),
          imageUrl: text(r['cover_url']),
          route: '/listing/${r['id']}',
        ),
    ];
  }
}
