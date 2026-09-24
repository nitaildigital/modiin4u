/// A deal, as the `offers` table stores it.
///
/// The Deals screen used to carry four invented offers on shops that are not
/// in Modiin — a Nike store, an "Urban Plate Kitchen & Bar" — with timers
/// counting down to nothing. This is the real row.
class Offer {
  final String id;
  final String name;
  final String? description;
  final String? terms;
  final String? imageUrl;

  /// What the resident shows at the till. Null when the offer needs no code.
  final String? code;

  final String? businessId;
  final String? businessName;
  final String? businessAddress;
  final String? businessLogoUrl;

  final DateTime? startAt;
  final DateTime? endAt;

  /// Null means no limit, which is not the same as none left.
  final int? maxClaims;
  final int? maxPerUser;

  final int pointsRequired;
  final bool isFeatured;
  final int claimCount;

  const Offer({
    required this.id,
    required this.name,
    this.description,
    this.terms,
    this.imageUrl,
    this.code,
    this.businessId,
    this.businessName,
    this.businessAddress,
    this.businessLogoUrl,
    this.startAt,
    this.endAt,
    this.maxClaims,
    this.maxPerUser,
    this.pointsRequired = 0,
    this.isFeatured = false,
    this.claimCount = 0,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final biz = json['businesses'];
    return Offer(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      terms: json['terms'] as String?,
      imageUrl: json['image_url'] as String?,
      code: json['code'] as String?,
      businessId: json['business_id'] as String?,
      businessName: biz is Map ? biz['name'] as String? : null,
      businessAddress: biz is Map ? biz['address'] as String? : null,
      businessLogoUrl: biz is Map
          ? (biz['logo_url'] ?? biz['cover_url']) as String?
          : null,
      startAt: DateTime.tryParse(json['start_at'] as String? ?? ''),
      endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
      maxClaims: (json['max_claims'] as num?)?.toInt(),
      maxPerUser: (json['max_per_user'] as num?)?.toInt(),
      pointsRequired: (json['points_required'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      claimCount: (json['claim_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// How long is left, or null when the offer has no end date — in which case
  /// the card shows nothing rather than an invented countdown.
  Duration? get timeLeft {
    final end = endAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get hasExpired => timeLeft == Duration.zero;

  /// True only when a limit was set and it has been reached.
  bool get isFullyClaimed => maxClaims != null && claimCount >= maxClaims!;

  bool get isClaimable => !hasExpired && !isFullyClaimed;
}
