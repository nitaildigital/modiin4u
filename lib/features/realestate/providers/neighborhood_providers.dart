import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/listing.dart';
import 'listing_providers.dart';

/// One row of the `neighborhoods` table.
///
/// The detail screen used to carry a single neighbourhood written into it:
/// the name "Moriah", a city of "Modiin", and three paragraphs about when
/// Moriah was settled and where its street names come from. Whatever id the
/// route carried, every neighbourhood in the city rendered as Moriah.
class Neighborhood {
  final String id;
  final String name;
  final String slug;

  /// Written by the client in the admin panel. Null for most of them, and
  /// the About section is then not drawn at all rather than invented.
  final String? description;
  final String? imageUrl;

  const Neighborhood({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.imageUrl,
  });

  factory Neighborhood.fromJson(Map<String, dynamic> json) => Neighborhood(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    slug: (json['slug'] as String?) ?? '',
    description: (json['description'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['description'] as String).trim(),
    imageUrl: json['image_url'] as String?,
  );
}

/// The neighbourhood the route names. Null when the id matches no row.
final neighborhoodByIdProvider = FutureProvider.family<Neighborhood?, String>((
  ref,
  id,
) async {
  final rows = await SupabaseConfig.client
      .from('neighborhoods')
      .select('id, name, slug, description, image_url')
      .eq('id', id)
      .limit(1);

  final list = List<Map<String, dynamic>>.from(rows);
  return list.isEmpty ? null : Neighborhood.fromJson(list.first);
});

/// The two figures the database can actually answer for a neighbourhood.
///
/// The screen showed four: properties for sale, businesses in the area,
/// parks and playgrounds, schools and kindergartens — 12, 18, 6 and 7, the
/// same four numbers for every neighbourhood. There is no table of parks and
/// none of schools, so those two are gone rather than guessed at.
typedef NeighborhoodCounts = ({int listings, int businesses});

final neighborhoodCountsProvider =
    FutureProvider.family<NeighborhoodCounts, String>((ref, id) async {
      final client = SupabaseConfig.client;

      // `count: exact` with `head: true` asks Postgres for the number
      // without shipping the rows, which is all either figure needs.
      final listings = await client
          .from('listings')
          .select('id')
          .eq('neighborhood_id', id)
          .eq('status', 'active')
          .count();

      final businesses = await client
          .from('businesses')
          .select('id')
          .eq('neighborhood_id', id)
          .eq('status', 'active')
          .count();

      return (listings: listings.count, businesses: businesses.count);
    });

/// A neighbourhood's active listings of one kind, newest first.
///
/// `listings` has no rows yet, so both sections show their empty state. That
/// is the honest outcome: the screen used to carry two invented flats for
/// sale and two to let, priced and addressed, under every neighbourhood.
final neighborhoodListingsProvider =
    FutureProvider.family<List<Listing>, (String, ListingKind)>((
      ref,
      args,
    ) async {
      final (id, kind) = args;
      return ref
          .watch(listingRepositoryProvider)
          .fetchActive(neighborhoodId: id, kind: kind);
    });
