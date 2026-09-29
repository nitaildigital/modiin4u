import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/supabase/supabase_config.dart';

/// A car park the client entered in the panel (חניונים, migration 00030).
///
/// Everything but the name and the point is optional, and a field left
/// empty stays null so the screens leave it out rather than print a guess.
class ParkingLot {
  final String id;
  final String name;
  final String? nameEn;
  final String? address;
  final String? hours;
  final String? priceNote;

  /// Null when the client has not said — which is not the same as paid.
  final bool? isFree;

  /// The number of spaces he entered. Not how many are free right now:
  /// nothing reports that.
  final int? capacity;
  final String? notes;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  const ParkingLot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.nameEn,
    this.address,
    this.hours,
    this.priceNote,
    this.isFree,
    this.capacity,
    this.notes,
    this.imageUrl,
  });

  factory ParkingLot.fromRow(Map<String, dynamic> r) => ParkingLot(
    id: r['id'] as String,
    name: r['name'] as String,
    nameEn: _nonEmpty(r['name_en']),
    address: _nonEmpty(r['address']),
    hours: _nonEmpty(r['hours']),
    priceNote: _nonEmpty(r['price_note']),
    isFree: r['is_free'] as bool?,
    capacity: r['capacity'] as int?,
    notes: _nonEmpty(r['notes']),
    imageUrl: _nonEmpty(r['image_url']),
    latitude: (r['latitude'] as num).toDouble(),
    longitude: (r['longitude'] as num).toDouble(),
  );

  /// The English name in English where he gave one, the Hebrew otherwise.
  String displayName({required bool english}) =>
      english ? (nameEn ?? name) : name;

  LatLng get position => LatLng(latitude, longitude);

  /// Waze, which people here drive with, as the business page does.
  Uri get wazeUri => Uri.parse(
    'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
  );
}

String? _nonEmpty(Object? value) {
  final s = (value as String?)?.trim();
  return s == null || s.isEmpty ? null : s;
}

/// The lots the client has entered and not hidden, in his order.
///
/// Used by the parking screens and by the city map's Parkings layer. A read
/// the database refuses — the table missing where migration 00030 has not
/// run, say — gives an empty list, so the map's other three layers still
/// load and the parking screen says the lots are coming.
final parkingLotsProvider = FutureProvider<List<ParkingLot>>((ref) async {
  try {
    final rows = await SupabaseConfig.client
        .from('parking_lots')
        .select(
          'id, name, name_en, address, hours, price_note, is_free, capacity, '
          'notes, latitude, longitude, image_url',
        )
        .eq('is_active', true)
        // Both ascending: postgrest's `order` is descending unless told.
        .order('sort_order', ascending: true)
        .order('name', ascending: true);
    return [for (final r in rows) ParkingLot.fromRow(r)];
  } on PostgrestException catch (e) {
    debugPrint('parking_lots: ${e.message}');
    return const [];
  }
});
