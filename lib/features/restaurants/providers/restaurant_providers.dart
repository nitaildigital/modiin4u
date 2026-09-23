import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';

/// Every business category, keyed by slug, so screens can ask for one by name
/// instead of carrying ids around.
final categoriesBySlugProvider =
    FutureProvider<Map<String, BusinessCategory>>((ref) async {
  final rows = await ref.watch(businessRepositoryProvider).fetchCategories();
  return {
    for (final row in rows)
      (row['slug'] as String? ?? ''): BusinessCategory.fromJson(row),
  };
});

/// The cuisines shown across the top — the sub-categories of "restaurants", so
/// pizza, asian, meat and the rest come from the admin panel rather than from
/// a list written into the screen.
final cuisineCategoriesProvider =
    FutureProvider<List<BusinessCategory>>((ref) async {
  final parent = (await ref.watch(categoriesBySlugProvider.future))['restaurants'];
  if (parent == null) return const [];

  final rows = await ref.watch(businessRepositoryProvider).fetchCategories();
  return rows
      .where((r) => r['parent_id'] == parent.id)
      .map(BusinessCategory.fromJson)
      .toList();
});

/// Active businesses in one category, addressed by slug.
///
/// Empty until `entity_categories` links businesses to categories — see B4 in
/// the plan. Screens show their empty state rather than a wrong list.
final businessesBySlugProvider =
    FutureProvider.family<List<Business>, String>((ref, slug) async {
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
