import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/listing.dart';

/// Reads and writes `listings`.
///
/// Row level security does the deciding: the public read policy returns only
/// `active` rows unless the row is yours or you are an administrator, so
/// [fetchMine] needs no filter on the owner to be safe — it passes one anyway,
/// to say what it means.
class ListingRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// The joins the cards and the detail page read. `!inner` is deliberately
  /// not used: a listing with no agent and no neighbourhood is normal and
  /// must still come back.
  static const _select = '''
    *,
    neighborhoods(id, name, description),
    real_estate_agents(id, name, agency, phone, photo_url)
  ''';

  Future<List<Listing>> fetchActive({
    ListingKind? kind,
    PropertyType? propertyType,
    String? neighborhoodId,
    String? search,
    int? minPrice,
    int? maxPrice,
    double? minRooms,
    int limit = 100,
  }) async {
    var query = _client
        .from('listings')
        .select(_select)
        .eq('status', ListingStatus.active.name);

    if (kind != null) query = query.eq('kind', kind.name);
    if (propertyType != null) {
      query = query.eq('property_type', propertyType.name);
    }
    if (neighborhoodId != null && neighborhoodId.isNotEmpty) {
      query = query.eq('neighborhood_id', neighborhoodId);
    }
    if (minRooms != null) query = query.gte('rooms', minRooms);
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or('title.ilike.%$q%,address.ilike.%$q%');
    }

    // A rental is priced in `price_per_month` and a sale in `price`, so the
    // bound is applied to whichever column the kind actually uses. With no
    // kind chosen there is no single column to compare, so the filter is left
    // off rather than silently dropping every rental.
    final priceColumn = switch (kind) {
      ListingKind.rent => 'price_per_month',
      ListingKind.sale => 'price',
      null => null,
    };
    if (priceColumn != null) {
      if (minPrice != null) query = query.gte(priceColumn, minPrice);
      if (maxPrice != null) query = query.lte(priceColumn, maxPrice);
    }

    final rows = await query
        .order('is_featured', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows).map(Listing.fromJson).toList();
  }

  Future<Listing?> fetchById(String id) async {
    final row = await _client
        .from('listings')
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Listing.fromJson(row);
  }

  /// Everything this person has posted, whatever its status — that is the
  /// point of the screen, so a pending one has to be included.
  Future<List<Listing>> fetchMine(String ownerId) async {
    final rows = await _client
        .from('listings')
        .select(_select)
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(Listing.fromJson).toList();
  }

  /// Other active listings in the same neighbourhood, for the strip at the
  /// bottom of a listing. Excludes the one being looked at.
  Future<List<Listing>> fetchNearby({
    required String listingId,
    String? neighborhoodId,
    int limit = 6,
  }) async {
    if (neighborhoodId == null || neighborhoodId.isEmpty) return const [];
    final rows = await _client
        .from('listings')
        .select(_select)
        .eq('status', ListingStatus.active.name)
        .eq('neighborhood_id', neighborhoodId)
        .neq('id', listingId)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows).map(Listing.fromJson).toList();
  }

  /// Posts a listing for review.
  ///
  /// Status is fixed at `pending` here rather than taken from the caller: a
  /// resident must not be able to publish straight to the directory. The
  /// insert policy requires `owner_id` to be the signed-in account, so it is
  /// read from the session rather than passed in.
  Future<Listing> create({
    required String title,
    String? description,
    required ListingKind kind,
    required PropertyType propertyType,
    double? rooms,
    int? bathrooms,
    int? floor,
    int? totalFloors,
    int? sqm,
    int? price,
    int? pricePerMonth,
    String? address,
    String? neighborhoodId,
    bool hasParking = false,
    bool hasElevator = false,
    bool hasStorage = false,
    bool hasBalcony = false,
    bool hasMamad = false,
    String? coverUrl,
    List<String> gallery = const [],
    bool isBroker = false,
    String? contactName,
    String? contactPhone,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('A listing can only be posted by a signed-in account.');
    }

    final row = await _client
        .from('listings')
        .insert({
          'title': title,
          'description': description,
          'kind': kind.name,
          'property_type': propertyType.name,
          'status': ListingStatus.pending.name,
          'rooms': rooms,
          'bathrooms': bathrooms,
          'floor': floor,
          'total_floors': totalFloors,
          'sqm': sqm,
          'price': price,
          'price_per_month': pricePerMonth,
          'address': address,
          'neighborhood_id': neighborhoodId,
          'has_parking': hasParking,
          'has_elevator': hasElevator,
          'has_storage': hasStorage,
          'has_balcony': hasBalcony,
          'has_mamad': hasMamad,
          'cover_url': coverUrl,
          'gallery': gallery,
          'owner_id': uid,
          'is_broker': isBroker,
          'contact_name': contactName,
          'contact_phone': contactPhone,
        })
        .select(_select)
        .single();

    return Listing.fromJson(row);
  }

  Future<void> deleteById(String id) =>
      _client.from('listings').delete().eq('id', id);
}
