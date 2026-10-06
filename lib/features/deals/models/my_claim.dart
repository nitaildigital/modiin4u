/// One deal this person has claimed: their voucher.
///
/// `code` is the claim's own short code (00056), shown at the till; null on a
/// database where 00056 has not run, and the voucher falls back to the deal's
/// code. `redeemed` is set once, by "Use now" (`redeem_my_claim`) or by the
/// panel.
class MyClaim {
  final String id;
  final String offerId;
  final String? code;
  final bool redeemed;
  final DateTime? redeemedAt;
  final DateTime createdAt;

  const MyClaim({
    required this.id,
    required this.offerId,
    required this.code,
    required this.redeemed,
    required this.redeemedAt,
    required this.createdAt,
  });

  factory MyClaim.fromJson(Map<String, dynamic> json) => MyClaim(
    id: json['id'] as String,
    offerId: json['offer_id'] as String,
    code: (json['code'] as String?)?.trim(),
    redeemed: json['redeemed'] as bool? ?? false,
    redeemedAt: DateTime.tryParse(json['redeemed_at'] as String? ?? '')?.toLocal(),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );
}
