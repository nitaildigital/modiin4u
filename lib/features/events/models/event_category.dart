/// One row of `categories` with `scope = 'event'`.
///
/// An event has no category column. It is filed through `entity_categories`
/// (`entity_type = 'event'`), the same way businesses and articles are, so
/// the website's category circles, card pills and filters read the links.
class EventCategory {
  final String id;

  /// As the editor wrote it, in Hebrew.
  final String name;
  final String slug;
  final String? imageUrl;
  final int sortOrder;

  const EventCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
