class Review {
  final String id;
  final String businessId;
  final String userId;
  final String userName;
  final bool isVerifiedResident;
  final double rating;
  final String? text;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String? ownerReply;
  final DateTime? ownerReplyAt;

  const Review({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.userName,
    this.isVerifiedResident = false,
    required this.rating,
    this.text,
    this.imageUrls = const [],
    required this.createdAt,
    this.ownerReply,
    this.ownerReplyAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      isVerifiedResident: json['is_verified_resident'] as bool? ?? false,
      rating: (json['rating'] as num).toDouble(),
      text: json['text'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerReply: json['owner_reply'] as String?,
      ownerReplyAt: json['owner_reply_at'] != null
          ? DateTime.parse(json['owner_reply_at'] as String)
          : null,
    );
  }
}
