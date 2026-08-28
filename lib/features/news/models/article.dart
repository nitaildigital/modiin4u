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
  final String? metaDescription;
  final String? metaKeywords;
  final ArticleStatus status;
  final int viewCount;

  const Article({
    required this.id,
    required this.title,
    this.subtitle,
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
    this.metaDescription,
    this.metaKeywords,
    this.status = ArticleStatus.published,
    this.viewCount = 0,
  });

  Article copyWith({
    String? title,
    String? subtitle,
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

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String,
      category: NewsCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NewsCategory.municipal,
      ),
      publishedAt: DateTime.parse(json['published_at'] as String),
      isBreaking: json['is_breaking'] as bool? ?? false,
      relatedBusinessIds:
          (json['related_business_ids'] as List<dynamic>?)?.cast<String>() ??
              [],
    );
  }
}
