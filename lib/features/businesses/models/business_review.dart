/// A review someone wrote about a business.
class BusinessReview {
  final String id;

  /// Who wrote it, so their own review offers no "Report".
  final String? authorId;

  /// Empty when the review carries no name; the page then says "Resident"
  /// in the reader's language. It used to be filled with the Hebrew word
  /// here, which the English website printed as it was.
  final String authorName;
  /// The author's photo, only when they agreed to show it (00076).
  final String? authorAvatarUrl;

  /// Photographs the author attached, up to four (00076).
  final List<String> photos;
  final int rating;
  final String? title;
  final String body;
  final bool isVerified;
  final DateTime? createdAt;

  /// What the business wrote back, when it has.
  final String? adminResponse;
  final DateTime? respondedAt;

  /// False only for the signed-in writer's own review while the panel has
  /// not approved it: the list shows it to them, marked, and leaves it out
  /// of the average and the counts.
  final bool isApproved;

  /// Taken down by the team (hidden or rejected), as opposed to waiting:
  /// its writer is told so, not that it is pending.
  final bool isRemoved;

  const BusinessReview({
    required this.id,
    this.authorId,
    required this.authorName,
    required this.rating,
    required this.body,
    this.authorAvatarUrl,
    this.photos = const [],
    this.title,
    this.isVerified = false,
    this.createdAt,
    this.adminResponse,
    this.respondedAt,
    this.isApproved = true,
    this.isRemoved = false,
  });

  factory BusinessReview.fromJson(Map<String, dynamic> json) {
    // The join is named after its foreign key, so PostgREST returns it under
    // that name; `profiles` is the fallback for anything selecting it plainly.
    //
    // Profiles are private (00027), so that join is null for anybody but the
    // author and an admin. The review carries its author's name and avatar
    // itself since 00029; those come first.
    final author = json['profiles!reviews_author_id_fkey'] ?? json['profiles'];
    final name = (json['author_name'] as String?) ??
        (author is Map ? author['full_name'] as String? : null);
    // The review's own copy only: it is filled when the author agreed to
    // show their photo (00076). The profile's, through the join, would show
    // it to its author and to admins whatever they had answered.
    final avatar = json['author_avatar_url'] as String?;

    return BusinessReview(
      id: json['id'] as String,
      authorId: json['author_id'] as String?,
      authorName: name ?? '',
      authorAvatarUrl: avatar,
      photos: [
        for (final p in (json['photos'] as List?) ?? const [])
          if (p is String && p.isNotEmpty) p,
      ],
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      body: (json['body'] as String?) ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      adminResponse: json['admin_response'] as String?,
      respondedAt: DateTime.tryParse(json['responded_at'] as String? ?? ''),
      isApproved: (json['status'] as String? ?? 'approved') == 'approved',
      isRemoved: const {'hidden', 'rejected'}.contains(json['status']),
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

  factory ReviewSummary.of(List<BusinessReview> all) {
    // A review waiting for the panel is not part of the score yet.
    final reviews = [for (final r in all) if (r.isApproved) r];
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
