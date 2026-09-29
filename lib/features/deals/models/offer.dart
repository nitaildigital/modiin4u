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

  /// The logo where the business has one, its cover where it does not — for
  /// the small round mark on a card, which should never be empty.
  final String? businessLogoUrl;

  /// The business's own logo and nothing else. The brand tiles are logos on
  /// white; a cover photograph squeezed into one is not a logo.
  final String? businessLogo;
  final String? businessCoverUrl;

  /// The neighbourhood the business is filed under — "Hatikva Quarter" on the
  /// design's card — or null.
  final String? businessNeighborhood;

  final DateTime? startAt;
  final DateTime? endAt;

  /// Null means no limit, which is not the same as none left.
  final int? maxClaims;
  final int? maxPerUser;

  final int pointsRequired;
  final bool isFeatured;
  final int claimCount;
  final int viewCount;

  /// Who may take it: `all`, `verified` or `new_users` (migration 00007).
  final String? audience;
  final DateTime? createdAt;

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
    this.businessLogo,
    this.businessCoverUrl,
    this.businessNeighborhood,
    this.startAt,
    this.endAt,
    this.maxClaims,
    this.maxPerUser,
    this.pointsRequired = 0,
    this.isFeatured = false,
    this.claimCount = 0,
    this.viewCount = 0,
    this.audience,
    this.createdAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final biz = json['businesses'];
    String? bizText(String key) {
      if (biz is! Map) return null;
      final v = biz[key];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    final hood = biz is Map ? biz['neighborhoods'] : null;
    return Offer(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      terms: json['terms'] as String?,
      imageUrl: json['image_url'] as String?,
      code: json['code'] as String?,
      businessId: json['business_id'] as String?,
      businessName: bizText('name'),
      businessAddress: bizText('address'),
      businessLogoUrl: bizText('logo_url') ?? bizText('cover_url'),
      businessLogo: bizText('logo_url'),
      businessCoverUrl: bizText('cover_url'),
      businessNeighborhood: hood is Map && (hood['name'] as String?)?.trim().isNotEmpty == true
          ? hood['name'] as String
          : null,
      startAt: DateTime.tryParse(json['start_at'] as String? ?? ''),
      endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
      maxClaims: (json['max_claims'] as num?)?.toInt(),
      maxPerUser: (json['max_per_user'] as num?)?.toInt(),
      pointsRequired: (json['points_required'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      claimCount: (json['claim_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      audience: json['audience'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
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

  /// "2d : 14h", or "14h : 30m" inside the last day, as the cards print it.
  /// Null when the offer has no end date: the clock is left off rather than
  /// counting down to nothing.
  String? timeLeftLabel({required bool isHebrew}) {
    final left = timeLeft;
    if (left == null) return null;
    if (left == Duration.zero) return isHebrew ? 'הסתיים' : 'Ended';
    String two(int n) => n.toString().padLeft(2, '0');
    if (left.inDays >= 1) return '${left.inDays}d : ${two(left.inHours % 24)}h';
    return '${left.inHours}h : ${two(left.inMinutes % 60)}m';
  }

  /// The design's "Residents Only": an offer the admin has limited to
  /// verified residents (`profiles.is_verified`).
  bool get isResidentsOnly => audience == 'verified';

  /// The orange corner label — "20% OFF", "FLAT ₪300 OFF", "BUY 1 GET 1" —
  /// read out of the offer's own title.
  ///
  /// `offers` has no discount column. Every badge the design draws restates
  /// the headline beside it ("20% Off Your Dinner Bill" → "20% OFF"), so the
  /// badge is taken from the headline the same way, and is left off when the
  /// headline states no discount rather than being made up.
  String? get badge => offerBadge(name);

  /// The percentage off, where the title states one. The brand tiles use it
  /// for "Upto 30% Off" across a business's offers.
  int? get percentOff => _percentOf(name);
}

/// A percentage the title calls a discount: "20% off", "20% הנחה",
/// "הנחה של 20%". A bare "ב-50%" ("the second one at 50%") is not a
/// discount on the whole, and gets no badge rather than a wrong one.
final _percent = RegExp(r'(\d{1,3})\s?%\s*(?:off|הנחה)|הנחה\s+של\s+(\d{1,3})\s?%', caseSensitive: false);
final _flat = RegExp(r'(?:flat\s*)?(₪\s?[\d,]+|[\d,]+\s?₪)\s*(?:off|הנחה)', caseSensitive: false);
final _buyGet = RegExp(r'buy\s*(\d+)\s*get\s*(\d+)', caseSensitive: false);
final _plusOne = RegExp(r'(?<![\d.])(\d)\s?\+\s?(\d)(?![\d.])');
final _gift = RegExp(r'מתנה|\bfree\b', caseSensitive: false);

int? _percentOf(String title) {
  final m = _percent.firstMatch(title);
  if (m == null) return null;
  return int.tryParse(m.group(1) ?? m.group(2) ?? '');
}

/// See [Offer.badge]. Public so the mobile screen can use the same wording.
String? offerBadge(String title) {
  final t = title.trim();
  if (t.isEmpty) return null;
  final hebrew = RegExp(r'[֐-׿]').hasMatch(t);

  final buy = _buyGet.firstMatch(t);
  if (buy != null) return 'BUY ${buy.group(1)} GET ${buy.group(2)}';
  final plus = _plusOne.firstMatch(t);
  if (plus != null) return '${plus.group(1)}+${plus.group(2)}';

  final pct = _percentOf(t);
  if (pct != null) return hebrew ? '$pct% הנחה' : '$pct% OFF';

  final flat = _flat.firstMatch(t);
  if (flat != null) {
    final amount = flat.group(1)!;
    return hebrew ? '$amount הנחה' : 'FLAT ${amount.replaceAll(' ', '')} OFF';
  }

  if (_gift.hasMatch(t)) return hebrew ? 'מתנה' : 'FREE';
  return null;
}
