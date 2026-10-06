import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_providers.dart';
import '../models/my_claim.dart';
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

/// This person's claims, keyed by deal: their vouchers, used or not. Empty
/// when signed out, so the screen can offer to sign in rather than fail.
final myClaimsProvider = FutureProvider<Map<String, MyClaim>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const {};
  return ref.watch(offerRepositoryProvider).fetchMyClaimList(user.id);
});

/// Offers this person has claimed.
final myClaimedOfferIdsProvider = FutureProvider<Set<String>>((ref) async {
  return (await ref.watch(myClaimsProvider.future)).keys.toSet();
});

/// Every active offer, unfiltered. The desktop page draws its category
/// circles, its carousel and its brand tiles from this one list, and narrows
/// it on the page rather than asking again for each filter.
final activeOffersProvider = FutureProvider<List<Offer>>(
  (ref) => ref.watch(offerRepositoryProvider).fetchActive(),
);

/// For each business with an active offer, the categories it is filed under
/// and the ones above them. `offers` has no category column; a deal is in
/// whatever category its business is in.
final offerBusinessCategoriesProvider =
    FutureProvider<Map<String, Set<String>>>((ref) async {
      final offers = await ref.watch(activeOffersProvider.future);
      return ref
          .watch(offerRepositoryProvider)
          .fetchCategoriesOfBusinesses(
            offers.map((o) => o.businessId).whereType<String>(),
          );
    });
