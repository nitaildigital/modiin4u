/// One line on a business's menu.
class MenuItem {
  final String id;
  final String? section;
  final String name;
  final String? description;

  /// Agorot, so 3250 is ₪32.50. Null when the dish carries no fixed price —
  /// market price, or priced in person.
  final int? priceAgorot;

  final bool isAvailable;

  const MenuItem({
    required this.id,
    this.section,
    required this.name,
    this.description,
    this.priceAgorot,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    section: json['section'] as String?,
    name: (json['name'] as String?) ?? '',
    description: json['description'] as String?,
    priceAgorot: (json['price_agorot'] as num?)?.toInt(),
    isAvailable: json['is_available'] as bool? ?? true,
  );

  /// "₪32" when the price is whole shekels, "₪32.50" when it is not.
  String? get priceLabel {
    final a = priceAgorot;
    if (a == null) return null;
    return a % 100 == 0 ? '₪${a ~/ 100}' : '₪${(a / 100).toStringAsFixed(2)}';
  }
}
