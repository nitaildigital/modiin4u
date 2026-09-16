import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

/// Shared map data — used by both the mobile map screen and the web map page.
final modiinCenter = LatLng(31.8928, 35.0104);

/// The four toggleable map layers: (label, icon, colour).
const mapLayers = [
  ('Businesses', IconsaxPlusBold.shop, Color(0xFF17A9D0)),
  ('Events', IconsaxPlusBold.calendar_1, Color(0xFF9032E1)),
  ('Parkings', IconsaxPlusBold.car, Color(0xFF31AC4E)),
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

final mapPois = [
  // ── Businesses (turquoise #17A9D0) ──
  MapPoi(
    name: 'Cafe Greg', category: 'Coffee Shop',
    position: LatLng(31.8935, 35.0110),
    icon: IconsaxPlusBold.coffee, color: const Color(0xFF17A9D0),
    layer: 'Businesses', route: '/business/demo_2',
    address: '12 Emek HaEla, Modiin',
    rating: 4.5, reviewCount: 182, viewCount: 315,
  ),
  MapPoi(
    name: 'Pizza Prego', category: 'Restaurant',
    position: LatLng(31.8920, 35.0080),
    icon: IconsaxPlusBold.reserve, color: const Color(0xFF17A9D0),
    layer: 'Businesses', route: '/business/demo_1',
    address: '8 HaMaccabim, Modiin',
    rating: 4.3, reviewCount: 97, viewCount: 246,
  ),
  MapPoi(
    name: 'Shipudey Hatikva', category: 'Restaurant',
    position: LatLng(31.8945, 35.0125),
    icon: IconsaxPlusBold.reserve, color: const Color(0xFF17A9D0),
    layer: 'Businesses', route: '/business/1',
    address: '3 Yona Hanavi Street, Modiin',
    rating: 4.8, reviewCount: 254, viewCount: 428,
  ),
  MapPoi(
    name: 'Sushi Modiin', category: 'Sushi',
    position: LatLng(31.8910, 35.0095),
    icon: IconsaxPlusBold.reserve, color: const Color(0xFF17A9D0),
    layer: 'Businesses', route: '/business/demo_4',
    address: '5 Levi Eshkol, Modiin',
    rating: 4.6, reviewCount: 143, viewCount: 390,
  ),
  MapPoi(
    name: 'Burgers Bar', category: 'Burgers',
    position: LatLng(31.8955, 35.0070),
    icon: IconsaxPlusBold.reserve, color: const Color(0xFF17A9D0),
    layer: 'Businesses', route: '/business/demo_3',
    address: '22 Moriya, Modiin',
    rating: 4.4, reviewCount: 201, viewCount: 510,
  ),
  MapPoi(
    name: 'Super Yochananof', category: 'Supermarket',
    position: LatLng(31.8940, 35.0060),
    icon: IconsaxPlusBold.shop, color: const Color(0xFF17A9D0),
    layer: 'Businesses',
    address: '1 Shivtei Israel, Modiin',
    rating: 4.1, reviewCount: 65, viewCount: 280,
  ),
  MapPoi(
    name: 'Style Studio', category: 'Hairdresser',
    position: LatLng(31.8915, 35.0130),
    icon: IconsaxPlusBold.scissor, color: const Color(0xFF17A9D0),
    layer: 'Businesses',
    address: '7 Yigal Alon, Modiin',
    rating: 4.7, reviewCount: 89, viewCount: 195,
  ),
  MapPoi(
    name: 'FitZone Gym', category: 'Fitness',
    position: LatLng(31.8958, 35.0115),
    icon: IconsaxPlusBold.weight, color: const Color(0xFF17A9D0),
    layer: 'Businesses',
    address: '14 HaPalmach, Modiin',
    rating: 4.2, reviewCount: 112, viewCount: 340,
  ),

  // ── Events (purple #9032E1) ──
  MapPoi(
    name: 'Street Food Festival', category: 'Food & Drink',
    position: LatLng(31.8900, 35.0130),
    icon: IconsaxPlusBold.calendar_1, color: const Color(0xFF9032E1),
    layer: 'Events', route: '/event/demo_0',
    venue: 'Anabe Park', time: '6:00 PM',
    eventPrice: '₪30', interestedCount: 256,
  ),
  MapPoi(
    name: 'Summer Music Night', category: 'Music',
    position: LatLng(31.8932, 35.0145),
    icon: IconsaxPlusBold.music, color: const Color(0xFF9032E1),
    layer: 'Events', route: '/event/demo_1',
    venue: 'Modiin Amphitheater', time: '8:00 PM',
    eventPrice: '₪50', interestedCount: 124,
  ),
  MapPoi(
    name: 'Kids Art Workshop', category: 'Art',
    position: LatLng(31.8948, 35.0088),
    icon: IconsaxPlusBold.brush_1, color: const Color(0xFF9032E1),
    layer: 'Events',
    venue: 'Community Center', time: '10:00 AM',
    eventPrice: 'Free', interestedCount: 78,
  ),
  MapPoi(
    name: 'Yoga in the Park', category: 'Wellness',
    position: LatLng(31.8905, 35.0055),
    icon: IconsaxPlusBold.weight, color: const Color(0xFF9032E1),
    layer: 'Events',
    venue: 'Modi\'in Park', time: '7:00 AM',
    eventPrice: 'Free', interestedCount: 45,
  ),

  // ── Parkings (green #31AC4E) ──
  MapPoi(
    name: 'Culture Hall Parking', category: 'Public',
    position: LatLng(31.8930, 35.0140),
    icon: IconsaxPlusBold.car, color: const Color(0xFF31AC4E),
    layer: 'Parkings',
    address: 'Near Culture Hall',
  ),
  MapPoi(
    name: 'Train Station Parking', category: 'Public',
    position: LatLng(31.8960, 35.0050),
    icon: IconsaxPlusBold.car, color: const Color(0xFF31AC4E),
    layer: 'Parkings',
    address: 'Modi\'in Central Station',
  ),
  MapPoi(
    name: 'Gray Parking', category: 'Public',
    position: LatLng(31.8918, 35.0115),
    icon: IconsaxPlusBold.car, color: const Color(0xFF31AC4E),
    layer: 'Parkings',
    address: 'City Center',
  ),

  // ── Real Estate (blue #006BF6) ──
  MapPoi(
    name: '₪3,650,000', category: 'HaPrachim',
    position: LatLng(31.8950, 35.0100),
    icon: IconsaxPlusBold.house_2, color: const Color(0xFF006BF6),
    layer: 'Real Estate', route: '/listing/demo_0',
    saleTag: 'FOR SALE', price: '₪3,650,000',
    address: '3 Yona Hanavi Street, Modiin',
    area: '140 m²', rooms: '6 Rooms', floor: 'Floor 3',
  ),
  MapPoi(
    name: '₪2,450,000', category: 'Avnei Chen',
    position: LatLng(31.8905, 35.0065),
    icon: IconsaxPlusBold.house_2, color: const Color(0xFF006BF6),
    layer: 'Real Estate', route: '/listing/demo_1',
    saleTag: 'FOR SALE', price: '₪2,450,000',
    address: '15 Sapir Street, Modiin',
    area: '110 m²', rooms: '4 Rooms', floor: 'Floor 2',
  ),
  MapPoi(
    name: '₪1,950,000', category: 'City Center',
    position: LatLng(31.8925, 35.0090),
    icon: IconsaxPlusBold.house_2, color: const Color(0xFF006BF6),
    layer: 'Real Estate', route: '/listing/demo_2',
    saleTag: 'FOR SALE', price: '₪1,950,000',
    address: '8 HaMaccabim, Modiin',
    area: '90 m²', rooms: '3 Rooms', floor: 'Floor 1',
  ),
];
