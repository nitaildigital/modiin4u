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
      dayOfWeek: json['day_of_week'] as int,
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

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      whatsapp: json['whatsapp'] as String?,
      address: json['address'] as String,
      neighborhood: json['neighborhood'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      hours: (json['hours'] as List<dynamic>?)
              ?.map((h) => BusinessHours.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      kosherStatus: json['kosher_status'] as String?,
      priceLevel: json['price_level'] as String?,
      hasDelivery: json['has_delivery'] as bool? ?? false,
      hasOutdoorSeating: json['has_outdoor_seating'] as bool? ?? false,
      isAccessible: json['is_accessible'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      petFriendly: json['pet_friendly'] as bool? ?? false,
      openOnShabbat: json['open_on_shabbat'] as bool? ?? false,
    );
  }
}
