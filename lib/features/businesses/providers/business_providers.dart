import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/business.dart';
import '../models/business_review.dart';
import '../models/menu_item.dart' as menu;
import '../repositories/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(),
);

/// Every active business, newest first.
final businessesProvider = FutureProvider<List<Business>>((ref) async {
  final rows = await ref
      .watch(businessRepositoryProvider)
      .fetchAll(status: 'active');
  return rows.map(Business.fromJson).toList();
});

/// Top-level business categories, in the order the admin set.
final businessCategoriesProvider = FutureProvider<List<BusinessCategory>>((
  ref,
) async {
  final rows = await ref.watch(businessRepositoryProvider).fetchCategories();
  return rows
      .where((r) => r['parent_id'] == null)
      .map(BusinessCategory.fromJson)
      .toList();
});

/// How many active businesses sit in each category, keyed by category id.
///
/// Comes from `entity_categories`, which is empty until the content load
/// writes the links, so this is `{}` for now and the UI hides the counts.
final businessCountsByCategoryProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  return ref.watch(businessRepositoryProvider).fetchCategoryCounts();
});

/// Active businesses in one category. Pass `null` for all of them.
final businessesByCategoryProvider =
    FutureProvider.family<List<Business>, String?>((ref, categoryId) async {
      if (categoryId == null) return ref.watch(businessesProvider.future);
      final rows = await ref
          .watch(businessRepositoryProvider)
          .fetchAll(status: 'active', categoryId: categoryId);
      return rows.map(Business.fromJson).toList();
    });

/// One business by id.
final businessByIdProvider = FutureProvider.family<Business, String>((
  ref,
  id,
) async {
  final row = await ref.watch(businessRepositoryProvider).fetchById(id);
  return Business.fromJson(row);
});

/// A category row from the `categories` table.
class BusinessCategory {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;
  final String? imageUrl;

  const BusinessCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder = 0,
    this.imageUrl,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }
}

/// Approved reviews for one business, newest first.
///
/// The page used to carry four invented reviews, with invented names, under a
/// real business — and a summary saying "based on 0 reviews" beside a 4.6
/// score. This reads the `reviews` table instead, so an empty table shows an
/// empty state rather than fiction.
final businessReviewsProvider =
    FutureProvider.family<List<BusinessReview>, String>((
      ref,
      businessId,
    ) async {
      final rows = await SupabaseConfig.client
          .from('reviews')
          // Two foreign keys run from `reviews` to `profiles` — the author and
          // whoever replied — so the join has to say which one it means.
          .select('*, profiles!reviews_author_id_fkey(full_name, avatar_url)')
          .eq('business_id', businessId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(
        rows,
      ).map(BusinessReview.fromJson).toList();
    });

/// The numbers above the list, derived from the reviews themselves.
final businessReviewSummaryProvider = Provider.family<ReviewSummary, String>((
  ref,
  businessId,
) {
  final reviews = ref.watch(businessReviewsProvider(businessId)).valueOrNull;
  return reviews == null ? ReviewSummary.empty : ReviewSummary.of(reviews);
});

/// One business's menu. Empty when it has none, which is most of them.
final businessMenuProvider = FutureProvider.family<List<menu.MenuItem>, String>(
  (ref, businessId) async {
    final rows = await ref
        .watch(businessRepositoryProvider)
        .fetchMenuItems(businessId);
    return rows.map(menu.MenuItem.fromJson).toList();
  },
);
