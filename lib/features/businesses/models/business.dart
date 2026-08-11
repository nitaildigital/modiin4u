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

class Business {
  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final String? description;
  final String? phone;
  final String? website;
  final String? instagram;
  final String? whatsapp;
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

  const Business({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    this.description,
    this.phone,
    this.website,
    this.instagram,
    this.whatsapp,
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
  });

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
