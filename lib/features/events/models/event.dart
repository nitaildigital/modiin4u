/// One row of the live `events` table.
class Event {
  final String id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? fullDescription;
  final String? imageUrl;
  final DateTime? startDate;
  final String? startTime;
  final DateTime? endDate;
  final String? endTime;
  final bool isAllDay;
  final String? venueName;
  final String address;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final String? onlineUrl;
  final bool isFree;
  final String? price;
  final String? ticketUrl;
  final bool isSoldOut;
  final bool isFeatured;
  final int viewCount;
  final int rsvpCount;

  const Event({
    required this.id,
    required this.title,
    this.slug = '',
    this.shortDescription,
    this.fullDescription,
    this.imageUrl,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.isAllDay = false,
    this.venueName,
    this.address = '',
    this.latitude = 0,
    this.longitude = 0,
    this.isOnline = false,
    this.onlineUrl,
    this.isFree = false,
    this.price,
    this.ticketUrl,
    this.isSoldOut = false,
    this.isFeatured = false,
    this.viewCount = 0,
    this.rsvpCount = 0,
  });

  /// The start date and time as one value, where both are known.
  DateTime? get startsAt {
    final date = startDate;
    if (date == null) return null;
    final parts = (startTime ?? '').split(':');
    if (parts.length < 2) return date;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  bool get hasPassed {
    final start = startsAt;
    return start != null && start.isBefore(DateTime.now());
  }

  /// "20:00", or null when the event runs all day.
  String? get displayTime {
    if (isAllDay) return null;
    final parts = (startTime ?? '').split(':');
    if (parts.length < 2) return null;
    return '${parts[0]}:${parts[1]}';
  }

  /// What the ticket costs, as it should read on screen.
  String? get displayPrice {
    if (isFree) return 'חינם';
    final p = price;
    if (p == null || p.isEmpty) return null;
    return p.startsWith('₪') ? p : '₪$p';
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? v) =>
        v is String ? DateTime.tryParse(v) : null;

    return Event(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      shortDescription: json['short_description'] as String?,
      fullDescription: json['full_description'] as String?,
      imageUrl: (json['image_url'] ?? json['og_image']) as String?,
      startDate: date(json['start_date']),
      startTime: json['start_time'] as String?,
      endDate: date(json['end_date']),
      endTime: json['end_time'] as String?,
      isAllDay: json['is_all_day'] as bool? ?? false,
      venueName: json['venue_name'] as String?,
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      onlineUrl: json['online_url'] as String?,
      isFree: json['is_free'] as bool? ?? false,
      price: json['price']?.toString(),
      ticketUrl: json['ticket_url'] as String?,
      isSoldOut: json['is_sold_out'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      rsvpCount: (json['rsvp_count'] as num?)?.toInt() ?? 0,
    );
  }
}
