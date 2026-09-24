import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_providers.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

final offerRepositoryProvider = Provider<OfferRepository>(
  (ref) => OfferRepository(),
);

/// Which category the list is narrowed to. Null is all of them.
final offerCategoryFilterProvider = StateProvider<String?>((ref) => null);

final offersProvider = FutureProvider<List<Offer>>((ref) async {
  final categoryId = ref.watch(offerCategoryFilterProvider);
  return ref.watch(offerRepositoryProvider).fetchActive(categoryId: categoryId);
});

final offerByIdProvider = FutureProvider.family<Offer?, String>(
  (ref, id) => ref.watch(offerRepositoryProvider).fetchById(id),
);

/// How many active offers each category has. The screen hides a category
/// with none rather than showing a zero.
final offerCountsByCategoryProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.watch(offerRepositoryProvider).fetchCountsByCategory(),
);

/// Categories that actually have an offer in them, in the admin's order.
final offerCategoriesProvider = FutureProvider<List<BusinessCategory>>((
  ref,
) async {
  final all = await ref.watch(businessCategoriesProvider.future);
  final counts = await ref.watch(offerCountsByCategoryProvider.future);
  return all.where((c) => (counts[c.id] ?? 0) > 0).toList();
});

/// Offers this person has claimed. Empty when signed out, so the screen can
/// offer to sign in rather than show a failure.
final myClaimedOfferIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const {};
  return ref.watch(offerRepositoryProvider).fetchMyClaims(user.id);
});
