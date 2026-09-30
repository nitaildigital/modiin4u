/// A place on one of the Municipal page's service tiles — a row in
/// `municipal_places` (migration 00040), managed in the panel.
class MunicipalPlace {
  final String id;
  final String category;
  final String name;
  final String? nameEn;
  final String? address;
  final String? phone;
  final String? notes;
  final double? latitude;
  final double? longitude;

  /// Brought in from OpenStreetMap, whose licence asks for a credit.
  final bool fromOsm;

  const MunicipalPlace({
    required this.id,
    required this.category,
    required this.name,
    this.nameEn,
    this.address,
    this.phone,
    this.notes,
    this.latitude,
    this.longitude,
    this.fromOsm = false,
  });

  /// The English name where one is set, and the Hebrew one otherwise.
  String nameIn(bool hebrew) =>
      hebrew || (nameEn ?? '').trim().isEmpty ? name : nameEn!.trim();

  bool get hasLocation => latitude != null && longitude != null;

  static String? _text(Object? v) {
    final s = (v as String?)?.trim() ?? '';
    return s.isEmpty ? null : s;
  }

  factory MunicipalPlace.fromJson(Map<String, dynamic> j) => MunicipalPlace(
    id: j['id'] as String,
    category: j['category'] as String,
    name: (j['name'] as String? ?? '').trim(),
    nameEn: _text(j['name_en']),
    address: _text(j['address']),
    phone: _text(j['phone']),
    notes: _text(j['notes']),
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    fromOsm: j['source'] == 'osm',
  );
}

/// The categories a place can be filed under, in the order the pages list
/// them, with their names in Hebrew and English.
const kMunicipalCategories = <String, ({String he, String en})>{
  'institution': (he: 'מוסדות ציבור', en: 'Public institutions'),
  'synagogue': (he: 'בתי כנסת', en: 'Synagogues'),
  'health': (he: 'מרפאות ובריאות', en: 'Clinics & health'),
  'school': (he: 'בתי ספר', en: 'Schools'),
  'kindergarten': (he: 'גני ילדים', en: 'Kindergartens'),
  'train_station': (he: 'תחנות רכבת', en: 'Train stations'),
  'bus_stop': (he: 'תחנות אוטובוס', en: 'Bus stops'),
  'emergency': (he: 'מספרי חירום', en: 'Emergency numbers'),
};

/// The Municipal page's tiles that list places, and the categories each
/// shows — as the client described them.
enum MunicipalSection {
  institutions(['institution', 'synagogue']),
  health(['health']),
  education(['school', 'kindergarten']),
  transport(['train_station', 'bus_stop']),
  emergency(['emergency']);

  final List<String> categories;
  const MunicipalSection(this.categories);

  static MunicipalSection? fromSlug(String slug) =>
      MunicipalSection.values.where((s) => s.name == slug).firstOrNull;
}
