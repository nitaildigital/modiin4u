import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business.dart';
import '../repositories/business_repository.dart';

final businessRepositoryProvider =
    Provider<BusinessRepository>((ref) => BusinessRepository());

/// Every active business, newest first.
final businessesProvider = FutureProvider<List<Business>>((ref) async {
  final rows =
      await ref.watch(businessRepositoryProvider).fetchAll(status: 'active');
  return rows.map(Business.fromJson).toList();
});

/// Top-level business categories, in the order the admin set.
final businessCategoriesProvider =
    FutureProvider<List<BusinessCategory>>((ref) async {
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
final businessCountsByCategoryProvider =
    FutureProvider<Map<String, int>>((ref) async {
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
final businessByIdProvider =
    FutureProvider.family<Business, String>((ref, id) async {
  final row = await ref.watch(businessRepositoryProvider).fetchById(id);
  return Business.fromJson(row);
});

/// A category row from the `categories` table.
class BusinessCategory {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  const BusinessCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder = 0,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
