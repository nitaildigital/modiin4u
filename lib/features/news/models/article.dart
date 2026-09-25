enum NewsCategory {
  municipal('עירייה'),
  business('עסקים'),
  realEstate('נדל"ן'),
  sports('ספורט'),
  people('אנשים'),
  food('קולינריה'),
  attractions('אטרקציות'),
  safety('ביטחון');

  final String label;
  const NewsCategory(this.label);
}

enum ArticleStatus { draft, published, archived }

class Article {
  final String id;
  final String title;
  final String? subtitle;
  final String? excerpt;
  final String slug;
  final String body;
  final String? imageUrl;
  final String author;
  final NewsCategory category;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final bool isBreaking;
  final bool isFeatured;
  final List<String> relatedBusinessIds;
  final List<String> tags;
  /// Where the story lives on the existing site. 390 of the 669 imported
  /// rows carry one; it is what a share link points at, since the app's own
  /// web build is not published yet.
  final String? canonicalUrl;
  final String? metaDescription;
  final String? metaKeywords;
  final ArticleStatus status;
  final int viewCount;

  const Article({
    required this.id,
    required this.title,
    this.subtitle,
    this.excerpt,
    this.slug = '',
    required this.body,
    this.imageUrl,
    required this.author,
    required this.category,
    required this.publishedAt,
    this.updatedAt,
    this.isBreaking = false,
    this.isFeatured = false,
    this.relatedBusinessIds = const [],
    this.tags = const [],
    this.canonicalUrl,
    this.metaDescription,
    this.metaKeywords,
    this.status = ArticleStatus.published,
    this.viewCount = 0,
  });

  Article copyWith({
    String? title,
    String? subtitle,
    String? excerpt,
    String? slug,
    String? body,
    String? imageUrl,
    String? author,
    NewsCategory? category,
    DateTime? publishedAt,
    DateTime? updatedAt,
    bool? isBreaking,
    bool? isFeatured,
    List<String>? relatedBusinessIds,
    List<String>? tags,
    String? metaDescription,
    String? metaKeywords,
    ArticleStatus? status,
    int? viewCount,
  }) {
    return Article(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      excerpt: excerpt ?? this.excerpt,
      slug: slug ?? this.slug,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBreaking: isBreaking ?? this.isBreaking,
      isFeatured: isFeatured ?? this.isFeatured,
      relatedBusinessIds: relatedBusinessIds ?? this.relatedBusinessIds,
      tags: tags ?? this.tags,
      metaDescription: metaDescription ?? this.metaDescription,
      metaKeywords: metaKeywords ?? this.metaKeywords,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  /// Maps a row of the live `articles` table.
  ///
  /// The table has no `category` column — categories are linked through
  /// `entity_categories` — and `author_id` is a uuid rather than a name,
  /// so both fall back to a default until those joins are wired in.
  factory Article.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(Object? v) =>
        v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();

    return Article(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      excerpt: json['excerpt'] as String?,
      slug: (json['slug'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      imageUrl: (json['featured_image'] ??
              json['mobile_image'] ??
              json['og_image']) as String?,
      author: (json['author_name'] as String?) ?? '',
      category: NewsCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NewsCategory.municipal,
      ),
      publishedAt: parseDate(json['published_at'] ?? json['created_at']),
      updatedAt:
          json['updated_at'] is String ? parseDate(json['updated_at']) : null,
      isBreaking: json['is_breaking'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      canonicalUrl: json['canonical_url'] as String?,
      metaDescription: json['meta_description'] as String?,
      metaKeywords: json['meta_keywords'] as String?,
      status: ArticleStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ArticleStatus.published,
      ),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    );
  }
}
