/// A resident's reply to a review — a row in `comments` with entity_type
/// 'review' (migration 00039). Approved replies are public; a pending one is
/// seen only by its author, marked as waiting for approval.
class ReviewReply {
  final String id;
  final String reviewId;
  final String authorId;
  final String authorName;
  final String body;
  final bool isApproved;

  /// Hidden or rejected by the team; its writer is told so.
  final bool isRemoved;
  final DateTime createdAt;

  const ReviewReply({
    required this.id,
    required this.reviewId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.isApproved,
    this.isRemoved = false,
    required this.createdAt,
  });

  /// As a review's: the first letters of the first two names.
  String get initials {
    final parts = authorName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return authorName.isNotEmpty ? authorName[0] : '?';
  }

  factory ReviewReply.fromJson(Map<String, dynamic> json) => ReviewReply(
    id: json['id'] as String,
    reviewId: json['entity_id'] as String,
    authorId: json['author_id'] as String,
    authorName: (json['author_name'] as String?)?.trim().isNotEmpty ?? false
        ? (json['author_name'] as String).trim()
        : '',
    body: (json['body'] as String? ?? '').trim(),
    isApproved: json['status'] == 'approved',
    isRemoved: const {'hidden', 'rejected'}.contains(json['status']),
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}
