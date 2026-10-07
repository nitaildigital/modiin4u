import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/listing.dart';
import '../repositories/listing_repository.dart';

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepository(),
);

/// What the browse screen filters by. Held as one object so a change to any
/// field refetches once rather than once per field.
class ListingFilter {
  final ListingKind? kind;
  final PropertyType? propertyType;
  final String? neighborhoodId;
  final String? search;
  final int? minPrice;
  final int? maxPrice;
  final double? minRooms;

  const ListingFilter({
    this.kind,
    this.propertyType,
    this.neighborhoodId,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.minRooms,
  });

  /// A null argument keeps the current value, so taking a field back to "any"
  /// needs its `clear…` flag. The map's filter sheet is what needs the last
  /// four: before it, nothing could set them, let alone unset them.
  ListingFilter copyWith({
    ListingKind? kind,
    PropertyType? propertyType,
    String? neighborhoodId,
    String? search,
    int? minPrice,
    int? maxPrice,
    double? minRooms,
    bool clearKind = false,
    bool clearPropertyType = false,
    bool clearNeighborhoodId = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRooms = false,
  }) => ListingFilter(
    kind: clearKind ? null : (kind ?? this.kind),
    propertyType: clearPropertyType
        ? null
        : (propertyType ?? this.propertyType),
    neighborhoodId: clearNeighborhoodId
        ? null
        : (neighborhoodId ?? this.neighborhoodId),
    search: search ?? this.search,
    minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
    maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    minRooms: clearMinRooms ? null : (minRooms ?? this.minRooms),
  );

  /// Whether anything beyond the typed search narrows the list — what the
  /// map's filter control marks with a dot.
  bool get hasFilters =>
      kind != null ||
      propertyType != null ||
      neighborhoodId != null ||
      minPrice != null ||
      maxPrice != null ||
      minRooms != null;

  @override
  bool operator ==(Object other) =>
      other is ListingFilter &&
      other.kind == kind &&
      other.propertyType == propertyType &&
      other.neighborhoodId == neighborhoodId &&
      other.search == search &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.minRooms == minRooms;

  @override
  int get hashCode => Object.hash(
    kind,
    propertyType,
    neighborhoodId,
    search,
    minPrice,
    maxPrice,
    minRooms,
  );
}

final listingFilterProvider = StateProvider<ListingFilter>(
  (ref) => const ListingFilter(),
);

/// Active listings matching the current filter.
final listingsProvider = FutureProvider<List<Listing>>((ref) async {
  final f = ref.watch(listingFilterProvider);
  return ref
      .watch(listingRepositoryProvider)
      .fetchActive(
        kind: f.kind,
        propertyType: f.propertyType,
        neighborhoodId: f.neighborhoodId,
        search: f.search,
        minPrice: f.minPrice,
        maxPrice: f.maxPrice,
        minRooms: f.minRooms,
      );
});

/// Every active listing, unfiltered.
///
/// The website's real-estate pages each narrow the list themselves — by kind,
/// by property type, by neighbourhood — and the map needs a listing's full
/// row behind its pin. [listingsProvider] is keyed to the filter the mobile
/// tab drives, which is not any of those, so the web reads this instead and
/// the pages share one fetch.
final allActiveListingsProvider = FutureProvider<List<Listing>>(
  (ref) => ref.watch(listingRepositoryProvider).fetchActive(),
);

/// One listing. Null when it was removed, or when it is not active and does
/// not belong to whoever is asking — row level security decides, not this.
final listingByIdProvider = FutureProvider.family<Listing?, String>(
  (ref, id) => ref.watch(listingRepositoryProvider).fetchById(id),
);

/// Other listings in the same neighbourhood as the one being viewed.
final nearbyListingsProvider = FutureProvider.family<List<Listing>, String>((
  ref,
  id,
) async {
  final listing = await ref.watch(listingByIdProvider(id).future);
  if (listing == null) return const [];
  return ref
      .watch(listingRepositoryProvider)
      .fetchNearby(listingId: id, neighborhoodId: listing.neighborhoodId);
});

/// Everything the signed-in person has posted, pending ones included.
/// Empty when signed out rather than an error, so the screen can offer to
/// sign in instead of showing a failure.
// Dropped when My Apartments closes, so reopening it shows what the panel
// decided meanwhile: kept for the session, an approved listing still read
// "Pending" until the app restarted.
final myListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const [];
  return ref.watch(listingRepositoryProvider).fetchMine(user.id);
});

/// The neighbourhoods a listing can be filed under, in the order the admin
/// set. The form needs the id, not the name, so the two travel together.
final listingNeighborhoodsProvider =
    FutureProvider<List<({String id, String name})>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('neighborhoods')
          .select('id, name')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(
        rows,
      ).map((r) => (id: r['id'] as String, name: r['name'] as String)).toList();
    });
