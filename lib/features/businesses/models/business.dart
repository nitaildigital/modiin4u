class BusinessHours {
  final int dayOfWeek; // 1=Monday, 7=Sunday
  final String? openTime; // "09:00"
  final String? closeTime; // "22:00"

  const BusinessHours({
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
  });

  bool get isClosed => openTime == null || closeTime == null;

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      // The table stores 0 = Sunday .. 6 = Saturday, while `isOpenNow`
      // compares against Dart's `weekday`, which is 1 = Monday .. 7 = Sunday.
      dayOfWeek: switch ((json['day_of_week'] as num?)?.toInt()) {
        null => 1,
        0 => DateTime.sunday,
        final d => d,
      },
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
    );
  }
}

enum BusinessStatus { pending, active, suspended, rejected }

class Business {
  final String id;
  final String name;
  final String slug;
  final String category;
  final String? subcategory;
  final String? description;
  final String? metaDescription;
  final String? phone;
  final String? website;
  final String? instagram;
  final String? whatsapp;
  final String? email;
  final String address;
  final String neighborhood;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? logoUrl;
  final List<String> tags;
  final List<BusinessHours> hours;
  final double rating;
  final int reviewCount;
  final String? kosherStatus;
  final String? priceLevel;
  final bool hasDelivery;
  final bool hasOutdoorSeating;
  final bool isAccessible;
  final bool hasParking;
  final bool petFriendly;
  final bool openOnShabbat;
  final BusinessStatus status;
  final String? ownerId;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.name,
    this.slug = '',
    required this.category,
    this.subcategory,
    this.description,
    this.metaDescription,
    this.phone,
    this.website,
    this.instagram,
    this.whatsapp,
    this.email,
    required this.address,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.logoUrl,
    this.tags = const [],
    this.hours = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.kosherStatus,
    this.priceLevel,
    this.hasDelivery = false,
    this.hasOutdoorSeating = false,
    this.isAccessible = false,
    this.hasParking = false,
    this.petFriendly = false,
    this.openOnShabbat = false,
    this.status = BusinessStatus.active,
    this.ownerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Business copyWith({
    String? name,
    String? slug,
    String? category,
    String? subcategory,
    String? description,
    String? metaDescription,
    String? phone,
    String? website,
    String? instagram,
    String? whatsapp,
    String? email,
    String? address,
    String? neighborhood,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? logoUrl,
    List<String>? tags,
    List<BusinessHours>? hours,
    double? rating,
    int? reviewCount,
    String? kosherStatus,
    String? priceLevel,
    bool? hasDelivery,
    bool? hasOutdoorSeating,
    bool? isAccessible,
    bool? hasParking,
    bool? petFriendly,
    bool? openOnShabbat,
    BusinessStatus? status,
    String? ownerId,
  }) {
    return Business(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      metaDescription: metaDescription ?? this.metaDescription,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      neighborhood: neighborhood ?? this.neighborhood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      tags: tags ?? this.tags,
      hours: hours ?? this.hours,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      kosherStatus: kosherStatus ?? this.kosherStatus,
      priceLevel: priceLevel ?? this.priceLevel,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      hasOutdoorSeating: hasOutdoorSeating ?? this.hasOutdoorSeating,
      isAccessible: isAccessible ?? this.isAccessible,
      hasParking: hasParking ?? this.hasParking,
      petFriendly: petFriendly ?? this.petFriendly,
      openOnShabbat: openOnShabbat ?? this.openOnShabbat,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt,
    );
  }

  String get statusLabel => switch (status) {
    BusinessStatus.pending => 'ממתין לאישור',
    BusinessStatus.active => 'פעיל',
    BusinessStatus.suspended => 'מושהה',
    BusinessStatus.rejected => 'נדחה',
  };

  bool get isOpenNow {
    final now = DateTime.now();
    final todayHours = hours.where((h) => h.dayOfWeek == now.weekday).toList();
    if (todayHours.isEmpty) return false;

    for (final h in todayHours) {
      if (h.isClosed) continue;
      final openParts = h.openTime!.split(':');
      final closeParts = h.closeTime!.split(':');
      final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;

      if (closeMinutes > openMinutes) {
        if (nowMinutes >= openMinutes && nowMinutes < closeMinutes) return true;
      } else {
        if (nowMinutes >= openMinutes || nowMinutes < closeMinutes) return true;
      }
    }
    return false;
  }

  /// Maps a row of the live `businesses` table.
  ///
  /// The table holds no `category` column — categories are linked through
  /// `entity_categories` — and the neighbourhood arrives as a joined object
  /// when the query asks for it, so both degrade gracefully when absent.
  /// The kosher certification as it should read on screen, or null when the
  /// business carries none.
  String? get kosherLabel => switch (kosherStatus) {
        'rabbanut' => 'רבנות',
        'mehadrin' => 'מהדרין',
        'badatz' => 'בד"ץ',
        'other' => 'כשר',
        _ => null,
      };

  factory Business.fromJson(Map<String, dynamic> json) {
    final joinedNeighborhood = json['neighborhoods'];
    final neighborhoodName = joinedNeighborhood is Map<String, dynamic>
        ? (joinedNeighborhood['name'] as String? ?? '')
        : (json['neighborhood'] as String? ?? '');

    final joinedHours = json['business_hours'];

    return Business(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      subcategory: json['subcategory'] as String?,
      description: (json['short_description'] ?? json['full_description'])
          as String?,
      metaDescription: json['meta_description'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      whatsapp: json['whatsapp'] as String?,
      email: json['email'] as String?,
      address: (json['address'] as String?) ?? '',
      neighborhood: neighborhoodName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: (json['cover_url'] ?? json['og_image_url']) as String?,
      logoUrl: json['logo_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      hours: joinedHours is List
          ? joinedHours
              .whereType<Map<String, dynamic>>()
              .map(BusinessHours.fromJson)
              .toList()
          : const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      kosherStatus: switch (json['kosher_level'] as String?) {
        null || '' || 'none' => null,
        final level => level,
      },
      priceLevel: json['price_level'] as String?,
      hasDelivery: json['has_delivery'] as bool? ?? false,
      hasOutdoorSeating: json['has_outdoor'] as bool? ?? false,
      isAccessible: json['is_accessible'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      petFriendly: json['pet_friendly'] as bool? ?? false,
      openOnShabbat: json['open_on_shabbat'] as bool? ?? false,
      status: BusinessStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BusinessStatus.active,
      ),
      ownerId: json['owner_id'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
