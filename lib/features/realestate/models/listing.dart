/// An apartment listing, as the `listings` table stores it.
///
/// The real-estate screens were built against hardcoded values — the same
/// ₪3,650,000 flat and the same agent on every page — while the table sat
/// unused. This is what the screens read now.
enum ListingKind { sale, rent }

enum PropertyType { apartment, penthouse, garden, duplex, villa, studio, other }

/// `draft` is never shown; a resident's new listing starts at `pending` and an
/// administrator moves it to `active`.
enum ListingStatus { draft, pending, active, sold, rented, expired, removed }

T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

class Listing {
  final String id;
  final String title;
  final String? slug;
  final String? description;

  final ListingKind kind;
  final PropertyType propertyType;
  final ListingStatus status;

  /// Half rooms are normal here, so 3.5 is a real value.
  final double? rooms;
  final int? bathrooms;
  final int? floor;
  final int? totalFloors;
  final int? sqm;

  /// Whole shekels. A sale carries [price]; a rental carries
  /// [pricePerMonth]. The other stays null rather than zero, so "not priced"
  /// and "free" do not look the same.
  final int? price;
  final int? pricePerMonth;

  final String? address;
  final String? neighborhoodId;
  final String? neighborhoodName;

  /// Written by the client in the admin panel. The listing page had a
  /// paragraph about Moriah hardcoded into it and showed it whatever the
  /// neighbourhood was; this is the real one, and null when none was written.
  final String? neighborhoodDescription;
  final double? latitude;
  final double? longitude;

  final bool hasParking;
  final bool hasElevator;
  final bool hasStorage;
  final bool hasBalcony;

  /// ממ"ד — the protected room. The local word, as a listing here writes it.
  final bool hasMamad;
  final bool isFurnished;
  final bool isAccessible;
  final bool isRenovated;

  final String? coverUrl;
  final List<String> gallery;

  /// All of these may be null: a listing can arrive by telephone and be
  /// entered by the client with no account behind it.
  final String? agentId;
  final String? agentName;
  final String? agentAgency;
  final String? agentPhone;
  final String? agentPhotoUrl;
  final String? ownerId;
  final bool isBroker;
  final String? contactName;
  final String? contactPhone;

  final bool isFeatured;
  final int viewCount;
  final DateTime? availableFrom;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    this.kind = ListingKind.sale,
    this.propertyType = PropertyType.apartment,
    this.status = ListingStatus.draft,
    this.rooms,
    this.bathrooms,
    this.floor,
    this.totalFloors,
    this.sqm,
    this.price,
    this.pricePerMonth,
    this.address,
    this.neighborhoodId,
    this.neighborhoodName,
    this.neighborhoodDescription,
    this.latitude,
    this.longitude,
    this.hasParking = false,
    this.hasElevator = false,
    this.hasStorage = false,
    this.hasBalcony = false,
    this.hasMamad = false,
    this.isFurnished = false,
    this.isAccessible = false,
    this.isRenovated = false,
    this.coverUrl,
    this.gallery = const [],
    this.agentId,
    this.agentName,
    this.agentAgency,
    this.agentPhone,
    this.agentPhotoUrl,
    this.ownerId,
    this.isBroker = false,
    this.contactName,
    this.contactPhone,
    this.isFeatured = false,
    this.viewCount = 0,
    this.availableFrom,
    required this.createdAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    final hood = json['neighborhoods'];
    final agent = json['real_estate_agents'];

    return Listing(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      kind: _enumFrom(ListingKind.values, json['kind'], ListingKind.sale),
      propertyType: _enumFrom(
        PropertyType.values,
        json['property_type'],
        PropertyType.apartment,
      ),
      status: _enumFrom(
        ListingStatus.values,
        json['status'],
        ListingStatus.draft,
      ),
      rooms: (json['rooms'] as num?)?.toDouble(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      floor: (json['floor'] as num?)?.toInt(),
      totalFloors: (json['total_floors'] as num?)?.toInt(),
      sqm: (json['sqm'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      pricePerMonth: (json['price_per_month'] as num?)?.toInt(),
      address: json['address'] as String?,
      neighborhoodId: json['neighborhood_id'] as String?,
      neighborhoodName: hood is Map ? hood['name'] as String? : null,
      neighborhoodDescription: hood is Map
          ? hood['description'] as String?
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hasParking: json['has_parking'] as bool? ?? false,
      hasElevator: json['has_elevator'] as bool? ?? false,
      hasStorage: json['has_storage'] as bool? ?? false,
      hasBalcony: json['has_balcony'] as bool? ?? false,
      hasMamad: json['has_mamad'] as bool? ?? false,
      isFurnished: json['is_furnished'] as bool? ?? false,
      isAccessible: json['is_accessible'] as bool? ?? false,
      isRenovated: json['is_renovated'] as bool? ?? false,
      coverUrl: json['cover_url'] as String?,
      gallery: List<String>.from(json['gallery'] as List? ?? const []),
      agentId: json['agent_id'] as String?,
      agentName: agent is Map ? agent['name'] as String? : null,
      agentAgency: agent is Map ? agent['agency'] as String? : null,
      agentPhone: agent is Map ? agent['phone'] as String? : null,
      agentPhotoUrl: agent is Map ? agent['photo_url'] as String? : null,
      ownerId: json['owner_id'] as String?,
      isBroker: json['is_broker'] as bool? ?? false,
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      availableFrom: DateTime.tryParse(json['available_from'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Whichever of the two prices applies, or null when the listing carries
  /// no price at all.
  int? get effectivePrice => kind == ListingKind.rent ? pricePerMonth : price;

  /// Who to call. A listing entered by telephone has a contact but no agent
  /// and no account.
  String? get contactDisplayName => agentName ?? contactName;
  String? get contactDisplayPhone => agentPhone ?? contactPhone;
}
