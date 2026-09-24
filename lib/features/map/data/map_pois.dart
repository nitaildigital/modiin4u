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
