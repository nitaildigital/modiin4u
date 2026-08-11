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

class Article {
  final String id;
  final String title;
  final String? subtitle;
  final String body;
  final String? imageUrl;
  final String author;
  final NewsCategory category;
  final DateTime publishedAt;
  final bool isBreaking;
  final List<String> relatedBusinessIds;

  const Article({
    required this.id,
    required this.title,
    this.subtitle,
    required this.body,
    this.imageUrl,
    required this.author,
    required this.category,
    required this.publishedAt,
    this.isBreaking = false,
    this.relatedBusinessIds = const [],
  });

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
