import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// Real Estate Search — listing data & filter model
// Demo data for the web search page; swap for Supabase queries.
// ═══════════════════════════════════════════════════════════

class SearchListing {
  final String title, neighborhood, area, floor, type;
  final String typeKey; // apartment | penthouse | garden | duplex | villa | studio
  final int rooms;
  final int priceValue;
  final String price;
  final String? perMonth;
  final Color imageBg;

  const SearchListing({
    required this.title,
    required this.neighborhood,
    required this.area,
    required this.rooms,
    required this.floor,
    required this.type,
    required this.typeKey,
    required this.priceValue,
    required this.price,
    this.perMonth,
    this.imageBg = const Color(0xFFE8EEF4),
  });
}

/// Filter state shared by the web sidebar and the mobile filter sheet.
class SearchFilters {
  final Set<String> propertyTypes;
  final Set<int> rooms; // 5 means "5+"
  final RangeValues priceRange;
  final String floor; // 'any' | '1-3' | '4-7' | '8+'
  final String neighborhood; // 'any' or a neighborhood name
  final String query;

  const SearchFilters({
    this.propertyTypes = const {},
    this.rooms = const {},
    required this.priceRange,
    this.floor = 'any',
    this.neighborhood = 'any',
    this.query = '',
  });

  SearchFilters copyWith({
    Set<String>? propertyTypes,
    Set<int>? rooms,
    RangeValues? priceRange,
    String? floor,
    String? neighborhood,
    String? query,
  }) {
    return SearchFilters(
      propertyTypes: propertyTypes ?? this.propertyTypes,
      rooms: rooms ?? this.rooms,
      priceRange: priceRange ?? this.priceRange,
      floor: floor ?? this.floor,
      neighborhood: neighborhood ?? this.neighborhood,
      query: query ?? this.query,
    );
  }

  /// Number of active constraints, for the mobile "Filters (n)" badge.
  int activeCount(RangeValues fullRange) {
    var n = 0;
    if (propertyTypes.isNotEmpty) n++;
    if (rooms.isNotEmpty) n++;
    if (priceRange.start > fullRange.start || priceRange.end < fullRange.end) {
      n++;
    }
    if (floor != 'any') n++;
    if (neighborhood != 'any') n++;
    return n;
  }
}

// ── Price slider bounds per listing type ──
const rentPriceRange = RangeValues(2000, 25000);
const salePriceRange = RangeValues(1000000, 10000000);

RangeValues fullPriceRange({required bool isRent}) =>
    isRent ? rentPriceRange : salePriceRange;

// ── Floor buckets ──
bool _floorMatches(String bucket, String floor) {
  final f = int.tryParse(floor);
  if (f == null) return true;
  switch (bucket) {
    case '1-3':
      return f >= 1 && f <= 3;
    case '4-7':
      return f >= 4 && f <= 7;
    case '8+':
      return f >= 8;
    default:
      return true;
  }
}

/// Applies every active filter to [listings].
List<SearchListing> applyFilters(
  List<SearchListing> listings,
  SearchFilters filters,
) {
  final q = filters.query.trim().toLowerCase();
  return listings.where((l) {
    if (q.isNotEmpty &&
        !l.title.toLowerCase().contains(q) &&
        !l.neighborhood.toLowerCase().contains(q)) {
      return false;
    }
    if (filters.propertyTypes.isNotEmpty &&
        !filters.propertyTypes.contains(l.typeKey)) {
      return false;
    }
    if (filters.rooms.isNotEmpty) {
      final bucket = l.rooms >= 5 ? 5 : l.rooms;
      if (!filters.rooms.contains(bucket)) return false;
    }
    if (l.priceValue < filters.priceRange.start ||
        l.priceValue > filters.priceRange.end) {
      return false;
    }
    if (!_floorMatches(filters.floor, l.floor)) return false;
    if (filters.neighborhood != 'any' &&
        l.neighborhood != filters.neighborhood) {
      return false;
    }
    return true;
  }).toList();
}

// ═══════════════════════════════════════════════════════════
// Demo listings
// ═══════════════════════════════════════════════════════════

String _t(bool he, String en, String heText) => he ? heText : en;

String _typeLabel(bool he, String key) {
  switch (key) {
    case 'penthouse':
      return _t(he, 'Penthouse', 'פנטהאוז');
    case 'garden':
      return _t(he, 'Garden Apartment', 'דירת גן');
    case 'duplex':
      return _t(he, 'Duplex', 'דופלקס');
    case 'villa':
      return _t(he, 'Villa', 'וילה');
    case 'studio':
      return _t(he, 'Studio', 'סטודיו');
    default:
      return _t(he, 'Standard Apartment', 'דירה רגילה');
  }
}

List<SearchListing> searchListings({
  required bool isRent,
  bool isHebrew = false,
}) =>
    isRent ? _rentListings(isHebrew) : _saleListings(isHebrew);

List<SearchListing> _saleListings(bool he) => [
      SearchListing(
        title: _t(he, 'Mini Penthouse 6 Rooms – Avni Hen',
            'מיני פנטהאוז 6 חדרים – אבני חן'),
        neighborhood: _t(he, 'Maccabim Reut', 'מכבים רעות'),
        area: '140',
        rooms: 6,
        floor: '3',
        typeKey: 'penthouse',
        type: _typeLabel(he, 'penthouse'),
        priceValue: 4350000,
        price: '₪4,350,000',
        imageBg: const Color(0xFFD4E4F7),
      ),
      SearchListing(
        title: _t(he, 'Ha-Rav Kook St, Modiin', 'רח׳ הרב קוק, מודיעין'),
        neighborhood: _t(he, 'HaNahalim', 'הנחלים'),
        area: '120',
        rooms: 5,
        floor: '2',
        typeKey: 'apartment',
        type: _typeLabel(he, 'apartment'),
        priceValue: 3600000,
        price: '₪3,600,000',
        imageBg: const Color(0xFFE0D4C8),
      ),
      SearchListing(
        title: _t(he, 'Nachal Shilat, Modiin', 'נחל שילת, מודיעין'),
        neighborhood: _t(he, 'HaNahalim', 'הנחלים'),
        area: '163',
        rooms: 6,
        floor: '4',
        typeKey: 'duplex',
        type: _typeLabel(he, 'duplex'),
        priceValue: 4800000,
        price: '₪4,800,000',
        imageBg: const Color(0xFFC8D8E0),
      ),
      SearchListing(
        title: _t(he, 'Sheshet HaYamim, Modiin', 'ששת הימים, מודיעין'),
        neighborhood: _t(he, 'Buchman', 'בוכמן'),
        area: '135',
        rooms: 4,
        floor: '1',
        typeKey: 'garden',
        type: _typeLabel(he, 'garden'),
        priceValue: 4100000,
        price: '₪4,100,000',
        imageBg: const Color(0xFFD8E8D4),
      ),
      SearchListing(
        title: _t(he, 'Matityahu Doron St, Modiin', 'רח׳ מתתיהו דורון, מודיעין'),
        neighborhood: _t(he, 'Buchman', 'בוכמן'),
        area: '112',
        rooms: 4,
        floor: '2',
        typeKey: 'apartment',
        type: _typeLabel(he, 'apartment'),
        priceValue: 3280000,
        price: '₪3,280,000',
        imageBg: const Color(0xFFE8EEF4),
      ),
      SearchListing(
        title: _t(he, 'Hein St 6, Modiin', 'רח׳ חן 6, מודיעין'),
        neighborhood: _t(he, 'Maccabim Reut', 'מכבים רעות'),
        area: '112',
        rooms: 4,
        floor: '2',
        typeKey: 'apartment',
        type: _typeLabel(he, 'apartment'),
        priceValue: 3280000,
        price: '₪3,280,000',
        imageBg: const Color(0xFFF0E4D4),
      ),
      SearchListing(
        title: _t(he, 'Emek Ayalon Villa, Modiin', 'וילה עמק איילון, מודיעין'),
        neighborhood: _t(he, 'Kaiser', 'קייזר'),
        area: '240',
        rooms: 7,
        floor: '1',
        typeKey: 'villa',
        type: _typeLabel(he, 'villa'),
        priceValue: 8900000,
        price: '₪8,900,000',
        imageBg: const Color(0xFFDCE8D8),
      ),
      SearchListing(
        title: _t(he, 'Studio on Dam HaMaccabim', 'סטודיו בדם המכבים'),
        neighborhood: _t(he, 'HaNahalim', 'הנחלים'),
        area: '48',
        rooms: 2,
        floor: '8',
        typeKey: 'studio',
        type: _typeLabel(he, 'studio'),
        priceValue: 1650000,
        price: '₪1,650,000',
        imageBg: const Color(0xFFEDE4F2),
      ),
    ];

List<SearchListing> _rentListings(bool he) => [
      SearchListing(
        title: _t(he, 'Mini Penthouse 6 Rooms – Avni Hen',
            'מיני פנטהאוז 6 חדרים – אבני חן'),
        neighborhood: _t(he, 'Maccabim Reut', 'מכבים רעות'),
        area: '140',
        rooms: 6,
        floor: '3',
        typeKey: 'penthouse',
        type: _typeLabel(he, 'penthouse'),
        priceValue: 12500,
        price: '₪12,500',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFE4D8F0),
      ),
      SearchListing(
        title: _t(he, 'Ha-Rav Kook St, Modiin', 'רח׳ הרב קוק, מודיעין'),
        neighborhood: _t(he, 'HaNahalim', 'הנחלים'),
        area: '120',
        rooms: 5,
        floor: '2',
        typeKey: 'apartment',
        type: _typeLabel(he, 'apartment'),
        priceValue: 9800,
        price: '₪9,800',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFD4E0F0),
      ),
      SearchListing(
        title: _t(he, 'Nachal Shilat, Modiin', 'נחל שילת, מודיעין'),
        neighborhood: _t(he, 'HaNahalim', 'הנחלים'),
        area: '163',
        rooms: 6,
        floor: '4',
        typeKey: 'duplex',
        type: _typeLabel(he, 'duplex'),
        priceValue: 14000,
        price: '₪14,000',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFC8D8E0),
      ),
      SearchListing(
        title: _t(he, 'Sheshet HaYamim, Modiin', 'ששת הימים, מודיעין'),
        neighborhood: _t(he, 'Buchman', 'בוכמן'),
        area: '135',
        rooms: 4,
        floor: '1',
        typeKey: 'garden',
        type: _typeLabel(he, 'garden'),
        priceValue: 8500,
        price: '₪8,500',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFD8E8D4),
      ),
      SearchListing(
        title: _t(he, 'Matityahu Doron St, Modiin', 'רח׳ מתתיהו דורון, מודיעין'),
        neighborhood: _t(he, 'Buchman', 'בוכמן'),
        area: '112',
        rooms: 4,
        floor: '2',
        typeKey: 'apartment',
        type: _typeLabel(he, 'apartment'),
        priceValue: 7200,
        price: '₪7,200',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFE8EEF4),
      ),
      SearchListing(
        title: _t(he, 'Hein St 6, Modiin', 'רח׳ חן 6, מודיעין'),
        neighborhood: _t(he, 'Maccabim Reut', 'מכבים רעות'),
        area: '112',
        rooms: 4,
        floor: '2',
        typeKey: 'apartment',
        type: _typeLabel(he, 'apartment'),
        priceValue: 6800,
        price: '₪6,800',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFF0E4D4),
      ),
      SearchListing(
        title: _t(he, 'Studio on Dam HaMaccabim', 'סטודיו בדם המכבים'),
        neighborhood: _t(he, 'HaNahalim', 'הנחלים'),
        area: '48',
        rooms: 2,
        floor: '8',
        typeKey: 'studio',
        type: _typeLabel(he, 'studio'),
        priceValue: 4200,
        price: '₪4,200',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFEDE4F2),
      ),
      SearchListing(
        title: _t(he, 'Emek Ayalon Villa, Modiin', 'וילה עמק איילון, מודיעין'),
        neighborhood: _t(he, 'Kaiser', 'קייזר'),
        area: '240',
        rooms: 7,
        floor: '1',
        typeKey: 'villa',
        type: _typeLabel(he, 'villa'),
        priceValue: 21000,
        price: '₪21,000',
        perMonth: _t(he, '/ month', '/ לחודש'),
        imageBg: const Color(0xFFDCE8D8),
      ),
    ];

// ── Neighborhood options for the dropdowns ──
List<String> neighborhoodOptions(bool he) => [
      _t(he, 'Maccabim Reut', 'מכבים רעות'),
      _t(he, 'HaNahalim', 'הנחלים'),
      _t(he, 'Buchman', 'בוכמן'),
      _t(he, 'Kaiser', 'קייזר'),
    ];

const floorOptions = ['any', '1-3', '4-7', '8+'];

String floorLabel(bool he, String bucket) =>
    bucket == 'any' ? _t(he, 'Any', 'הכל') : bucket;

String formatPrice(int value) {
  final s = value.toString();
  return '₪${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}
