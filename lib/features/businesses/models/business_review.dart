/// A review someone wrote about a business.
class BusinessReview {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final int rating;
  final String? title;
  final String body;
  final bool isVerified;
  final DateTime? createdAt;

  /// What the business wrote back, when it has.
  final String? adminResponse;
  final DateTime? respondedAt;

  const BusinessReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.body,
    this.authorAvatarUrl,
    this.title,
    this.isVerified = false,
    this.createdAt,
    this.adminResponse,
    this.respondedAt,
  });

  factory BusinessReview.fromJson(Map<String, dynamic> json) {
    // The join is named after its foreign key, so PostgREST returns it under
    // that name; `profiles` is the fallback for anything selecting it plainly.
    final author = json['profiles!reviews_author_id_fkey'] ?? json['profiles'];
    final name = author is Map ? author['full_name'] as String? : null;

    return BusinessReview(
      id: json['id'] as String,
      authorName: (name == null || name.isEmpty) ? 'תושב' : name,
      authorAvatarUrl: author is Map ? author['avatar_url'] as String? : null,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      body: (json['body'] as String?) ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      adminResponse: json['admin_response'] as String?,
      respondedAt: DateTime.tryParse(json['responded_at'] as String? ?? ''),
    );
  }

  /// Two letters for the avatar circle, from whatever the name gives.
  String get initials {
    final parts = authorName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return authorName.isNotEmpty ? authorName[0] : '?';
  }
}

/// The numbers above the list: the average, the total, and how many gave each
/// score. Derived from the reviews rather than stored, so it cannot drift.
class ReviewSummary {
  final double average;
  final int total;

  /// Counts for 1..5, indexed by score - 1.
  final List<int> distribution;

  const ReviewSummary({
    required this.average,
    required this.total,
    required this.distribution,
  });

  static const empty = ReviewSummary(
    average: 0,
    total: 0,
    distribution: [0, 0, 0, 0, 0],
  );

  factory ReviewSummary.of(List<BusinessReview> reviews) {
    if (reviews.isEmpty) return empty;

    final counts = List<int>.filled(5, 0);
    var sum = 0;
    for (final r in reviews) {
      sum += r.rating;
      if (r.rating >= 1 && r.rating <= 5) counts[r.rating - 1]++;
    }
    return ReviewSummary(
      average: sum / reviews.length,
      total: reviews.length,
      distribution: counts,
    );
  }

  /// The share of reviews at [score], 0..1.
  double shareOf(int score) {
    if (total == 0) return 0;
    return distribution[score - 1] / total;
  }
}
