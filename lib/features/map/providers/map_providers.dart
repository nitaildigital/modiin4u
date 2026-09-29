import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/supabase/supabase_config.dart';
import '../../businesses/providers/business_providers.dart';
import '../../events/providers/event_providers.dart';
import '../../realestate/models/listing.dart';
import '../../realestate/providers/listing_providers.dart';
import '../data/map_pois.dart';

final _businessColor = mapLayers[0].$3;
final _eventColor = mapLayers[1].$3;
final _listingColor = mapLayers[2].$3;

/// The parking lots the client has entered and not hidden.
///
/// A lot the database refuses to return — the table not yet created where
/// migration 00030 has not run, say — leaves the Parkings layer empty rather
/// than taking the other three layers down with it.
final parkingLotsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final rows = await SupabaseConfig.client
        .from('parking_lots')
        .select('id, name, name_en, address, notes, latitude, longitude, image_url')
        .eq('is_active', true)
        .order('sort_order')
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  } on PostgrestException catch (e) {
    debugPrint('parking_lots: ${e.message}');
    return const [];
  }
});

/// Every pin on the map, built from the database.
///
/// Four layers, all live. The website draws the first three; parking is the
/// phone map's for now — see `parkingLayer`.
final mapPoisProvider = FutureProvider<List<MapPoi>>((ref) async {
  final businesses = await ref.watch(businessesProvider.future);
  final events = await ref.watch(eventsProvider.future);
  // Empty today, because the client has not supplied property content yet.
  // The layer is wired anyway, so it fills the moment a listing exists rather
  // than needing this file changed again.
  final listings = await ref.watch(listingsProvider.future);
  final parkingLots = await ref.watch(parkingLotsProvider.future);

  return [
    for (final b in businesses)
      // A pin needs coordinates; the seed leaves some at 0,0.
      if (b.latitude != 0 && b.longitude != 0)
        MapPoi(
          name: b.name,
          category: b.category.isNotEmpty
              ? b.category
              : (b.description ?? 'עסק'),
          position: LatLng(b.latitude, b.longitude),
          icon: businessPinIcon([b.name, b.description ?? '']),
          color: _businessColor,
          layer: 'Businesses',
          route: '/business/${b.id}',
          address: b.address.isEmpty ? b.neighborhood : b.address,
          rating: b.rating == 0 ? null : b.rating,
          reviewCount: b.reviewCount == 0 ? null : b.reviewCount,
          description: b.description,
          photos: [if (b.imageUrl != null) b.imageUrl!],
        ),
    for (final e in events)
      if (e.latitude != 0 && e.longitude != 0)
        MapPoi(
          name: e.title,
          category: 'אירוע',
          position: LatLng(e.latitude, e.longitude),
          icon: IconsaxPlusBold.calendar_1,
          color: _eventColor,
          layer: 'Events',
          route: '/event/${e.id}',
          address: e.address.isEmpty ? e.venueName : e.address,
          description: e.shortDescription,
          time: e.displayTime,
          venue: e.venueName,
          interestedCount: e.rsvpCount,
          eventPrice: e.displayPrice,
          photos: [if (e.imageUrl != null) e.imageUrl!],
        ),
    for (final l in listings)
      if (l.latitude != null && l.longitude != null)
        MapPoi(
          name: _priceLabel(l) ?? l.title,
          category: l.neighborhoodName ?? '',
          position: LatLng(l.latitude!, l.longitude!),
          icon: IconsaxPlusBold.house_2,
          color: _listingColor,
          layer: 'Real Estate',
          route: '/listing/${l.id}',
          address: l.address,
          description: l.description,
          price: _priceLabel(l),
          area: l.sqm == null ? null : '${l.sqm} m²',
          // Half rooms are normal here, so 3.5 must not print as 3.
          rooms: l.rooms == null ? null : _roomsLabel(l.rooms!),
          floor: l.floor == null ? null : 'Floor ${l.floor}',
          saleTag: l.kind == ListingKind.rent ? 'FOR RENT' : 'FOR SALE',
          sqm: l.sqm?.toInt(),
          roomCount: l.rooms,
          floorNumber: l.floor,
          photos: [if (l.coverUrl != null) l.coverUrl!, ...l.gallery],
        ),
    for (final p in parkingLots)
      MapPoi(
        name: p['name'] as String,
        nameEn: _nonEmpty(p['name_en']),
        category: '',
        position: LatLng(
          (p['latitude'] as num).toDouble(),
          (p['longitude'] as num).toDouble(),
        ),
        icon: parkingLayer.$2,
        color: parkingLayer.$3,
        // No route: a lot has no page of its own, so its card is all there
        // is to it.
        layer: parkingLayer.$1,
        address: _nonEmpty(p['address']),
        description: _nonEmpty(p['notes']),
        photos: [?_nonEmpty(p['image_url'])],
      ),
  ];
});

String? _nonEmpty(Object? value) {
  final s = (value as String?)?.trim();
  return s == null || s.isEmpty ? null : s;
}

/// "₪3,650,000", or null where the listing carries no price — which is not
/// the same as free, and must not be shown as ₪0.
String? _priceLabel(Listing l) {
  final amount = l.effectivePrice;
  if (amount == null) return null;
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '₪$buffer';
}

String _roomsLabel(double rooms) {
  final whole = rooms == rooms.roundToDouble();
  return '${whole ? rooms.toInt() : rooms} Rooms';
}
