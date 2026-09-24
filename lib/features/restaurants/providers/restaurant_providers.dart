import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';

/// Every business category, keyed by slug, so screens can ask for one by name
/// instead of carrying ids around.
final categoriesBySlugProvider = FutureProvider<Map<String, BusinessCategory>>((
  ref,
) async {
  final rows = await ref.watch(businessRepositoryProvider).fetchCategories();
  return {
    for (final row in rows)
      (row['slug'] as String? ?? ''): BusinessCategory.fromJson(row),
  };
});

/// The cuisines shown across the top — the sub-categories of "restaurants", so
/// pizza, asian, meat and the rest come from the admin panel rather than from
/// a list written into the screen.
final cuisineCategoriesProvider = FutureProvider<List<BusinessCategory>>((
  ref,
) async {
  final all = await ref.watch(categoriesBySlugProvider.future);
  final parent = all['restaurants'];
  if (parent == null) return const [];

  return all.values.where((c) => c.parentId == parent.id).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Active businesses in one category, addressed by slug.
///
/// Empty until `entity_categories` links businesses to categories — see B4 in
/// the plan. Screens show their empty state rather than a wrong list.
final businessesBySlugProvider = FutureProvider.family<List<Business>, String>((
  ref,
  slug,
) async {
  final category = (await ref.watch(categoriesBySlugProvider.future))[slug];
  if (category == null) return const [];
  return ref.watch(businessesByCategoryProvider(category.id).future);
});

/// The best-rated businesses, for the "most loved" row. Rating and review
/// count are on every row already, so this needs no extra data.
final topRatedBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  final all = [...await ref.watch(businessesProvider.future)]
    ..sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
    });
  return all.where((b) => b.rating > 0).take(8).toList();
});

/// What the map's search box is narrowed to. Empty means every pin.
final restaurantMapSearchProvider = StateProvider<String>((ref) => '');

/// A place as the map needs it: a business that has a location, plus the food
/// category it sits in so the pin can be coloured and labelled.
class FoodPlace {
  final Business business;

  /// The most specific food category it belongs to — "פיצה" rather than
  /// "מסעדות" where both are linked.
  final String categoryName;

  /// That category's slug, so a cuisine filter can match on it.
  final String categorySlug;

  /// True for cafés and bakeries, which get their own pin colour.
  final bool isCafe;

  /// A place with no coordinates cannot be a pin, but still belongs in the
  /// list beside the map.
  bool get hasLocation => business.latitude != 0 && business.longitude != 0;

  const FoodPlace({
    required this.business,
    required this.categoryName,
    required this.categorySlug,
    required this.isCafe,
  });
}

/// Food businesses that have a location, for the restaurants map.
///
/// The map used to carry 24 places written into the screen — several of them
/// addressed in Tel Aviv and Jerusalem, all sharing a handful of copied
/// ratings, and every "View Full Details" pushing
/// `/business/restaurant_<hashCode>`, which matches no row and so opened
/// nothing. These are real rows, at their real coordinates, and the button
/// goes to the business it names.
final foodMapPlacesProvider = FutureProvider<List<FoodPlace>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final businesses = await ref.watch(businessesProvider.future);
  final categories = await ref.watch(categoriesBySlugProvider.future);
  final links = await repo.fetchCategoryLinks();

  final byId = {for (final c in categories.values) c.id: c};

  // `cafe-bakery` is a top-level category; the rest are `restaurants` and its
  // children. There is no bar category in the database, so the design's third
  // pin colour has no source and is not drawn.
  const cafeSlug = 'cafe-bakery';
  final restaurants = categories['restaurants'];
  final foodIds = <String, BusinessCategory>{};
  for (final c in categories.values) {
    final isFood =
        c.slug == cafeSlug ||
        c.slug == 'restaurants' ||
        (restaurants != null && c.parentId == restaurants.id);
    if (isFood) foodIds[c.id] = c;
  }

  // Which food categories each business is in.
  final perBusiness = <String, List<BusinessCategory>>{};
  for (final link in links) {
    final category = byId[link['category_id']];
    if (category == null || !foodIds.containsKey(category.id)) continue;
    perBusiness
        .putIfAbsent(link['entity_id'] as String, () => [])
        .add(category);
  }

  final places = <FoodPlace>[];
  for (final business in businesses) {
    final mine = perBusiness[business.id];
    if (mine == null || mine.isEmpty) continue;

    // Prefer a child category over "restaurants" itself, so a pizzeria reads
    // "פיצה".
    final specific = mine.firstWhere(
      (c) => c.slug != 'restaurants',
      orElse: () => mine.first,
    );
    places.add(
      FoodPlace(
        business: business,
        categoryName: specific.name,
        categorySlug: specific.slug,
        isCafe: mine.any((c) => c.slug == cafeSlug),
      ),
    );
  }
  return places;
});

/// The map's pins, narrowed by the search box.
final filteredFoodMapPlacesProvider = FutureProvider<List<FoodPlace>>((
  ref,
) async {
  final query = ref.watch(restaurantMapSearchProvider).trim().toLowerCase();
  final places = await ref.watch(foodMapPlacesProvider.future);
  if (query.isEmpty) return places;

  // In memory: the set is already loaded and small, so a query per keystroke
  // would only be slower.
  return places
      .where(
        (p) =>
            p.business.name.toLowerCase().contains(query) ||
            p.business.address.toLowerCase().contains(query) ||
            p.categoryName.toLowerCase().contains(query),
      )
      .toList();
});
