/// A resident's comment on an article — a row in `comments` with
/// entity_type 'article' (00071). It goes live at once unless the panel's
/// Settings ask for comments to be approved first; a waiting or removed one
/// is seen only by its writer, who is told which it is.
class ArticleComment {
  final String id;
  final String articleId;
  final String authorId;

  /// The comment this one answers, as written. The page shows one level of
  /// replies, so a reply to a reply is drawn under the comment that opened
  /// the thread (see [ArticleCommentThread]).
  final String? parentId;
  final String authorName;
  final String? avatarUrl;
  final String body;
  final bool isApproved;

  /// Hidden or rejected by the team.
  final bool isRemoved;
  final DateTime createdAt;

  const ArticleComment({
    required this.id,
    required this.articleId,
    required this.authorId,
    this.parentId,
    required this.authorName,
    this.avatarUrl,
    required this.body,
    required this.isApproved,
    this.isRemoved = false,
    required this.createdAt,
  });

  /// The first letter of the name, for a writer with no photograph.
  String get initial {
    final name = authorName.trim();
    // By code point, so a name that starts outside the basic plane is not
    // cut in half.
    return name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
  }

  factory ArticleComment.fromJson(Map<String, dynamic> json) {
    final name = (json['author_name'] as String?)?.trim() ?? '';
    final avatar = (json['author_avatar_url'] as String?)?.trim() ?? '';
    return ArticleComment(
      id: json['id'] as String,
      articleId: json['entity_id'] as String,
      authorId: json['author_id'] as String,
      parentId: json['parent_id'] as String?,
      authorName: name,
      avatarUrl: avatar.isEmpty ? null : avatar,
      body: (json['body'] as String? ?? '').trim(),
      isApproved: json['status'] == 'approved',
      isRemoved: const {'hidden', 'rejected'}.contains(json['status']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// A comment that opened a thread, with every reply under it, oldest first.
class ArticleCommentThread {
  final ArticleComment comment;
  final List<ArticleComment> replies;

  const ArticleCommentThread({required this.comment, required this.replies});
}
