import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
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

/// The three kinds of place the design tells apart, each with its own round
/// badge: green for a restaurant, blue for a café, red for a bar.
enum FoodKind { restaurant, cafe, bar }

/// The key a bar is filtered by, beside the category slugs. There is no bar
/// category in `categories`, so it cannot be one of them.
const kBarsKey = 'bars';

const _cafeSlug = 'cafe-bakery';

/// Whether a business calls itself a bar or a pub.
///
/// The directory has no bar category: the bars in it are filed under
/// "בידור ופנאי", under "מסעדות", or under nothing at all. What they do have is
/// their own one-line description, and a bar's opens with the word — "בר
/// קוקטיילים", "בר מסעדה", "פאב אירי", "wine & vibe | בר יין". A place that only
/// mentions a bar further in ("מסעדה אסייתית וסושי בר", "פסטה בר") is a
/// restaurant, and does not count. Each "|"-separated part of the line is read
/// on its own, since several put an English name first.
bool describesABar(String? description) {
  if (description == null) return false;
  for (final part in description.split('|')) {
    final first = part.trim().split(RegExp(r'[\s,\-–]+')).first.toLowerCase();
    if (const {'בר', 'פאב', 'bar', 'pub'}.contains(first)) return true;
  }
  return false;
}

/// A place as the restaurant pages need it: a business, the kind of place it
/// is, and the food categories it sits in.
class FoodPlace {
  final Business business;

  /// The most specific food category it belongs to — "פיצה" rather than
  /// "מסעדות" where both are linked. Empty for a bar filed under no food
  /// category.
  final String categoryName;

  /// That category's slug, so a cuisine filter can match on it.
  final String categorySlug;

  /// Every food category it is linked to, plus [kBarsKey] for a bar, so a
  /// filter on "מסעדות" also finds the pizzeria filed under פיצה.
  final Set<String> slugs;

  /// The sub-category of מסעדות it is filed under, if any — the cuisine the
  /// design prints on the card's pill ("Israeli Dining", "Asian").
  final String? cuisineName;

  final FoodKind kind;

  /// True for cafés and bakeries, which get their own pin colour.
  bool get isCafe => kind == FoodKind.cafe;

  /// A place with no coordinates cannot be a pin, but still belongs in the
  /// list beside the map.
  bool get hasLocation => business.latitude != 0 && business.longitude != 0;

  const FoodPlace({
    required this.business,
    required this.categoryName,
    required this.categorySlug,
    required this.slugs,
    required this.kind,
    this.cuisineName,
  });
}

/// The places to eat and drink, in the order the businesses arrive (newest
/// first). With [withBars], businesses that describe themselves as a bar are
/// included whether or not they are filed under a food category.
Future<List<FoodPlace>> _loadFoodPlaces(Ref ref, {required bool withBars}) async {
  final repo = ref.watch(businessRepositoryProvider);
  final businesses = await ref.watch(businessesProvider.future);
  final categories = await ref.watch(categoriesBySlugProvider.future);
  final links = await repo.fetchCategoryLinks();

  final byId = {for (final c in categories.values) c.id: c};

  // `cafe-bakery` is a top-level category; the rest are `restaurants` and its
  // children.
  final restaurants = categories['restaurants'];
  final foodIds = <String, BusinessCategory>{};
  for (final c in categories.values) {
    final isFood =
        c.slug == _cafeSlug ||
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
    final mine = perBusiness[business.id] ?? const <BusinessCategory>[];
    final isBar = withBars && describesABar(business.description);
    if (mine.isEmpty && !isBar) continue;

    // Prefer a child category over "restaurants" itself, so a pizzeria reads
    // "פיצה".
    final specific = mine.isEmpty
        ? null
        : mine.firstWhere(
            (c) => c.slug != 'restaurants',
            orElse: () => mine.first,
          );
    final cuisine = mine
        .where((c) => restaurants != null && c.parentId == restaurants.id)
        .firstOrNull;
    places.add(
      FoodPlace(
        business: business,
        categoryName: specific?.name ?? '',
        categorySlug: specific?.slug ?? (isBar ? kBarsKey : ''),
        // A place filed only under פיצה is a restaurant too: its parent's
        // slug goes in with its own, or "View all restaurants" and the
        // Restaurants chip left it out while the Popular row showed it.
        slugs: {
          for (final c in mine) ...[
            c.slug,
            if (c.parentId != null && byId[c.parentId] != null) byId[c.parentId]!.slug,
          ],
          if (isBar) kBarsKey,
        },
        cuisineName: cuisine?.name,
        // A place's own word for itself first: Portofino is filed under
        // קפה ומאפה and opens its line with "בר מסעדה".
        kind: isBar
            ? FoodKind.bar
            : mine.any((c) => c.slug == _cafeSlug)
            ? FoodKind.cafe
            : FoodKind.restaurant,
      ),
    );
  }
  return places;
}

/// Food businesses, for the app's restaurants map.
///
/// The map used to carry 24 places written into the screen — several of them
/// addressed in Tel Aviv and Jerusalem, all sharing a handful of copied
/// ratings, and every "View Full Details" pushing
/// `/business/restaurant_<hashCode>`, which matches no row and so opened
/// nothing. These are real rows, at their real coordinates, and the button
/// goes to the business it names.
final foodMapPlacesProvider = FutureProvider<List<FoodPlace>>(
  (ref) => _loadFoodPlaces(ref, withBars: false),
);

/// The same, with the bars — for the website's restaurants pages, whose
/// design has a "Bars in Modiin" row, a Bars quick pick and a red bar badge.
final webFoodPlacesProvider = FutureProvider<List<FoodPlace>>(
  (ref) => _loadFoodPlaces(ref, withBars: true),
);

/// The businesses that say they do takeaway.
///
/// `has_takeaway` is a column the app's model does not read, so it is asked
/// for on its own. It is false on every row today, which leaves the Takeaway
/// quick pick and checkbox out until the directory records one.
final takeawayBusinessIdsProvider = FutureProvider<Set<String>>((ref) async {
  try {
    final rows = await SupabaseConfig.client
        .from('businesses')
        .select('id')
        .eq('status', 'active')
        .eq('has_takeaway', true);
    return {for (final r in List<Map<String, dynamic>>.from(rows)) r['id'] as String};
  } catch (_) {
    return const {};
  }
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
