import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../businesses/providers/business_providers.dart';
import '../../events/providers/event_providers.dart';
import '../data/map_pois.dart';



final _businessColor = mapLayers[0].$3;
final _eventColor = mapLayers[1].$3;

/// Every pin on the map, built from the database.
///
/// Only the Businesses and Events layers can be filled today: parking and
/// property have no tables, so those layers stay empty until they do.
final mapPoisProvider = FutureProvider<List<MapPoi>>((ref) async {
  final businesses = await ref.watch(businessesProvider.future);
  final events = await ref.watch(eventsProvider.future);

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
  ];
});
