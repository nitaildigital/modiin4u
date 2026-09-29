import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

/// Shared map data — used by both the mobile map screen and the web map page.
final modiinCenter = LatLng(31.8928, 35.0104);

/// The toggleable map layers: (label, icon, colour).
///
/// The design has a fourth, Parkings. There is no parking table and no
/// source for one, so it drew four invented car parks and nothing else could
/// ever appear on it. It comes back when the data does.
const mapLayers = [
  ('Businesses', IconsaxPlusBold.shop, Color(0xFF17A9D0)),
  ('Events', IconsaxPlusBold.calendar_1, Color(0xFF9032E1)),
  ('Real Estate', IconsaxPlusBold.house_2, Color(0xFF006BF6)),
];

/// The phone map's fourth layer, from the `parking_lots` table the client
/// fills in the panel (migration 00030).
///
/// Kept out of [mapLayers] on purpose: the website's map and home page list
/// every entry there as a toggle, and their designs are a separate job. Its
/// pins carry this layer name, which neither website page switches on, so
/// they stay off the website until it is given the layer too.
const parkingLayer = ('Parkings', IconsaxPlusBold.car, Color(0xFF17A9D0));

// ═══════════════════════════════════════════════
// POI data model
// ═══════════════════════════════════════════════
class MapPoi {
  final String name;
  final String category;
  final LatLng position;
  final IconData icon;
  final Color color;
  final String layer;
  final String? route;

  /// The English name where the row has one; only parking lots carry it.
  final String? nameEn;
  // Shared
  final String? address;
  final String? imageAsset; // placeholder image path
  /// Remote photos from the WordPress export; empty on demo POIs.
  final List<String> photos;

  /// The site's own blurb; demo POIs fall back to a generated sentence.
  final String? description;
  // Restaurant / Business
  final double? rating;
  final int? reviewCount;
  final int? viewCount;
  // Real Estate
  final String? price;
  final String? area;
  final String? rooms;
  final String? floor;
  final String? saleTag; // "FOR SALE" / "FOR RENT"

  /// The figures behind [area], [rooms] and [floor], for a screen that
  /// words them in its own language; those three are English.
  final int? sqm;
  final double? roomCount;
  final int? floorNumber;
  // Events
  final String? time;
  final String? venue;
  final int? interestedCount;
  final String? eventPrice;

  const MapPoi({
    required this.name,
    required this.category,
    required this.position,
    required this.icon,
    required this.color,
    required this.layer,
    this.route,
    this.nameEn,
    this.address,
    this.imageAsset,
    this.photos = const [],
    this.description,
    this.rating,
    this.reviewCount,
    this.viewCount,
    this.price,
    this.area,
    this.rooms,
    this.floor,
    this.saleTag,
    this.sqm,
    this.roomCount,
    this.floorNumber,
    this.time,
    this.venue,
    this.interestedCount,
    this.eventPrice,
  });
}

// ═══════════════════════════════════════════════
// PIN GLYPHS
// ═══════════════════════════════════════════════

/// Pin glyph for a business, matched on its category names.
IconData businessPinIcon(List<String> terms) {
  bool has(List<String> words) => terms.any((t) => words.any(t.contains));
  if (has(['קפה', 'ארוחת בוקר', 'גלידות', 'קונדיטור']))
    return IconsaxPlusBold.coffee;
  if (has(['בר', 'אלכוהול', 'קריוקי'])) return IconsaxPlusBold.cup;
  if (has(['מסעד', 'פיצ', 'סושי', 'גריל', 'המבורגר', 'אסיאתי', 'איטלקי'])) {
    return IconsaxPlusBold.reserve;
  }
  if (has(['אסתטיק', 'טיפוח', 'יופי', 'ספא', 'מספר']))
    return IconsaxPlusBold.brush_1;
  if (has(['ספורט', 'כושר'])) return IconsaxPlusBold.weight;
  if (has(['דלק', 'רכב', 'פנצ'])) return IconsaxPlusBold.car;
  if (has(['בריאות', 'רופא', 'מרפא'])) return IconsaxPlusBold.health;
  if (has(['לימוד', 'חוג', 'גן'])) return IconsaxPlusBold.book_1;
  return IconsaxPlusBold.shop;
}
