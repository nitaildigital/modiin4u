import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/business.dart';
import '../models/business_review.dart';
import '../models/review_reply.dart';
import '../models/menu_item.dart' as menu;
import '../repositories/business_repository.dart';
import '../../../core/providers/content_language.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(),
);

/// A business with an approved promotion running (00069) before one without:
/// the client's promise is the top of the list for the days he approved,
/// whatever order the list is otherwise in.
int promotedFirst(Business a, Business b) =>
    (b.isPromoted ? 1 : 0).compareTo(a.isPromoted ? 1 : 0);

/// Every active business, newest first.
final businessesProvider = FutureProvider<List<Business>>((ref) async {
  final rows = await ref
      .watch(businessRepositoryProvider)
      .fetchAll(status: 'active');
  return rows.map(Business.fromJson).toList();
});

/// The city's parks: rows the client files as a park in the panel, shown on
/// the Municipal page's Parks tile. Best rated first, then by name.
final parksProvider = FutureProvider<List<Business>>((ref) async {
  final rows = await ref
      .watch(businessRepositoryProvider)
      .fetchAll(status: 'active', kind: 'park');
  return rows.map(Business.fromJson).toList()..sort((a, b) {
    final byPromotion = promotedFirst(a, b);
    if (byPromotion != 0) return byPromotion;
    final byRating = b.rating.compareTo(a.rating);
    return byRating != 0 ? byRating : a.name.compareTo(b.name);
  });
});

/// Whether this device can be asked where it is at all.
///
/// A browser only answers on a secure page. The site is on plain
/// `http://45.93.94.49` until the domain and its certificate arrive, and on
/// such a page the browser refuses without asking — so offering "show what
/// is near me" there would be a button that does nothing. It appears by
/// itself once the site is on https.
bool get locationIsAskable =>
    !kIsWeb || Uri.base.scheme == 'https' || Uri.base.host == 'localhost';

/// Businesses for the home page's first row, and whether they are in order of
/// distance.
///
/// The row was headed "Popular near you" and drew every business in whatever
/// order the table returned them — no location read, no popularity measured.
/// The client opened it and saw businesses nowhere near him. Now: if this
/// device has already allowed location, the businesses that carry
/// coordinates are sorted by how far they are. If not, the list comes back as
/// it was and the heading stops claiming anything about distance.
///
/// Permission is checked, never requested, here — nobody should get a
/// location prompt for opening the home page. Asking is a separate tap.
final nearbyBusinessesProvider =
    FutureProvider<({List<Business> businesses, bool byDistance})>((ref) async {
      final all = await ref.watch(businessesProvider.future);
      if (!locationIsAskable) return (businesses: all, byDistance: false);

      Position? here;
      try {
        final allowed = await Geolocator.checkPermission();
        if (allowed == LocationPermission.always ||
            allowed == LocationPermission.whileInUse) {
          here = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
        }
      } catch (_) {
        // No fix in time, or services off. Fall through to the plain list.
      }
      final origin = here;
      if (origin == null) return (businesses: all, byDistance: false);

      double away(Business b) => Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        b.latitude,
        b.longitude,
      );
      // A business with no coordinates has no distance; it cannot be "near".
      final placed =
          all.where((b) => b.latitude != 0 && b.longitude != 0).toList()
            ..sort((a, b) {
              final byPromotion = promotedFirst(a, b);
              return byPromotion != 0 ? byPromotion : away(a).compareTo(away(b));
            });
      return (businesses: placed, byDistance: true);
    });

/// The same list, in the shape the home page's rows take.
final nearbyBusinessListProvider = FutureProvider<List<Business>>(
  (ref) async => (await ref.watch(nearbyBusinessesProvider.future)).businesses,
);

/// Restaurants and cafés for the app's home row, and whether they are in
/// order of distance.
///
/// The client (1 Oct): the home screen "shows businesses that are a bit
/// irrelevant; it would be better to prioritize showing restaurants". The
/// row drew the whole directory — electricians, banks, lawyers. It is the
/// food places now (the restaurants category, its cuisines and cafés),
/// those with a photograph first and then the best rated; nearest first
/// once this device has allowed location, as [nearbyBusinessesProvider].
final nearbyRestaurantsProvider =
    FutureProvider<({List<Business> businesses, bool byDistance})>((ref) async {
      final food = await ref.watch(foodPlaceBusinessesProvider.future);
      final near = await ref.watch(nearbyBusinessesProvider.future);
      final ids = {for (final b in food) b.id};
      if (near.byDistance) {
        return (
          businesses: near.businesses.where((b) => ids.contains(b.id)).toList(),
          byDistance: true,
        );
      }
      int photo(Business b) => (b.imageUrl ?? '').isEmpty ? 1 : 0;
      final sorted = [...food]
        ..sort((a, b) {
          final byPromotion = promotedFirst(a, b);
          if (byPromotion != 0) return byPromotion;
          final byPhoto = photo(a).compareTo(photo(b));
          if (byPhoto != 0) return byPhoto;
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
        });
      return (businesses: sorted, byDistance: false);
    });

/// The same list, in the shape the home page's rows take.
final nearbyRestaurantListProvider = FutureProvider<List<Business>>(
  (ref) async => (await ref.watch(nearbyRestaurantsProvider.future)).businesses,
);

/// The businesses filed under a food category — restaurants, its cuisines,
/// or cafés — read through the same links the Restaurants page uses.
final foodPlaceBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final all = await ref.watch(businessesProvider.future);
  final categories = await repo.fetchCategories();
  final restaurants =
      categories.where((c) => c['slug'] == 'restaurants').firstOrNull?['id'];
  final food = {
    for (final c in categories)
      if (c['slug'] == 'restaurants' ||
          c['slug'] == 'cafe-bakery' ||
          (restaurants != null && c['parent_id'] == restaurants))
        c['id'],
  };
  final links = await repo.fetchCategoryLinks();
  final ids = {
    for (final l in links)
      if (food.contains(l['category_id'])) l['entity_id'],
  };
  return all.where((b) => ids.contains(b.id)).toList();
});

/// Asks for location, then works the row out again.
Future<void> askForNearby(WidgetRef ref) async {
  try {
    await Geolocator.requestPermission();
  } catch (_) {}
  ref.invalidate(nearbyBusinessesProvider);
}

/// Settings → Location turned on: asks the phone, as the home row's "show
/// what is near me" does, and says whether it was allowed. The switch was
/// saved and read by nothing.
Future<bool> enableLocation(WidgetRef ref) async {
  if (!locationIsAskable) return false;
  var allowed = LocationPermission.denied;
  try {
    allowed = await Geolocator.requestPermission();
  } catch (_) {}
  ref.invalidate(nearbyBusinessesProvider);
  return allowed == LocationPermission.always ||
      allowed == LocationPermission.whileInUse;
}

/// Top-level business categories, in the order the admin set — those that
/// belong in the menus.
final businessCategoriesProvider = FutureProvider<List<BusinessCategory>>((
  ref,
) async {
  final rows = await ref.watch(businessRepositoryProvider).fetchCategories();
  return rows
      .where((r) => r['parent_id'] == null && r['in_menus'] != false)
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

/// The category a card names for each business, keyed by business id, with
/// the slug of the top of its branch.
///
/// `businesses` has no category column — `Business.category` is always empty
/// — so a card that wants to say "פיצה" beside a pizzeria has to read the
/// links. The most specific one wins: a pizzeria is filed under both מסעדות
/// and its child פיצה, and "פיצה" is the one that says something. The root
/// slug is what decides the badge: `restaurants` or `cafe-bakery`.
final businessPrimaryCategoryProvider =
    FutureProvider<Map<String, ({BusinessCategory category, String rootSlug})>>(
      (ref) async {
        final repo = ref.watch(businessRepositoryProvider);
        final rows = await repo.fetchCategories();
        final byId = {
          for (final r in rows)
            r['id'] as String: BusinessCategory.fromJson(r),
        };
        final links = await repo.fetchCategoryLinks();

        final chosen = <String, BusinessCategory>{};
        for (final link in links) {
          final category = byId[link['category_id']];
          // The old site's lists kept out of the menus ("עסקים באתר",
          // "פתוח בשבת") are not what a business is; they never label it.
          if (category == null || !category.inMenus) continue;
          final id = link['entity_id'] as String;
          final have = chosen[id];
          if (have == null || (have.parentId == null && category.parentId != null)) {
            chosen[id] = category;
          }
        }

        String rootOf(BusinessCategory c) {
          var at = c;
          for (var depth = 0; depth < 5 && at.parentId != null; depth++) {
            final parent = byId[at.parentId];
            if (parent == null) break;
            at = parent;
          }
          return at.slug;
        }

        return {
          for (final e in chosen.entries)
            e.key: (category: e.value, rootSlug: rootOf(e.value)),
        };
      },
    );

/// The kind of place a phone card names under a business: its category from
/// [businessPrimaryCategoryProvider], in the reader's language (00062), or
/// its short description when it is filed nowhere — which is what every card
/// showed before, Hebrew even with the app in English.
String businessKind(
  Business b,
  Map<String, ({BusinessCategory category, String rootSlug})>? kinds,
) =>
    kinds?[b.id]?.category.name ?? b.description ?? '';

/// A category row from the `categories` table.
class BusinessCategory {
  final String id;

  /// Hebrew, and English where the panel has one (00062); [name] is the
  /// reader's.
  final String nameHe;
  final String? nameEn;
  String get name => localName(nameHe, nameEn);
  final String slug;

  /// The category this one sits under, or null for a top-level one. Kept on
  /// the model so callers can walk the tree without going back to the raw row.
  final String? parentId;
  final int sortOrder;
  final String? imageUrl;

  /// Off for the old site's lists that came back as categories — "עסקים
  /// באתר", the wartime lists, "פתוח בשבת" (migration 00047): their pages
  /// keep their old addresses, but they are not categories to browse by.
  final bool inMenus;

  const BusinessCategory({
    required this.id,
    required String name,
    this.nameEn,
    required this.slug,
    this.parentId,
    this.sortOrder = 0,
    this.imageUrl,
    this.inMenus = true,
  }) : nameHe = name;

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      nameEn: json['name_en'] as String?,
      slug: (json['slug'] as String?) ?? '',
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      // Absent before 00047 runs: every category was in the menus then.
      inMenus: json['in_menus'] as bool? ?? true,
    );
  }
}

/// Approved reviews for one business, newest first.
///
/// The page used to carry four invented reviews, with invented names, under a
/// real business — and a summary saying "based on 0 reviews" beside a 4.6
/// score. This reads the `reviews` table instead, so an empty table shows an
/// empty state rather than fiction.
///
/// Dropped when the business page closes, so reopening it reads the reviews
/// again: kept for the whole session, a review the panel approved — or a
/// reply it hid — showed as it was when the page first opened, until the app
/// restarted (as replies already are, below).
final businessReviewsProvider =
    FutureProvider.autoDispose.family<List<BusinessReview>, String>((
      ref,
      businessId,
    ) async {
      // The approved reviews, and the signed-in person's own whatever its
      // state, so a review just sent shows as waiting instead of the page
      // saying "No reviews yet". Row security would also hand an admin
      // everyone's pending ones, hence the filter rather than none.
      final me = ref.watch(authProvider)?.id;
      final query = SupabaseConfig.client
          .from('reviews')
          // Two foreign keys run from `reviews` to `profiles` — the author and
          // whoever replied — so the join has to say which one it means.
          .select('*, profiles!reviews_author_id_fkey(full_name, avatar_url)')
          .eq('business_id', businessId);
      final rows = await (me == null
              ? query.eq('status', 'approved')
              : query.or('status.eq.approved,author_id.eq.$me'))
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(
        rows,
      ).map(BusinessReview.fromJson).toList();
    });

/// Residents' replies to one business's reviews, by review id, oldest first
/// so a thread reads down. Row security returns the approved replies and the
/// signed-in person's own, whatever their state. Dropped when the page
/// closes, so reopening it shows a reply the panel has approved since.
final reviewRepliesProvider =
    FutureProvider.autoDispose.family<Map<String, List<ReviewReply>>, String>((
      ref,
      businessId,
    ) async {
      final me = ref.watch(authProvider)?.id;
      final reviews = await ref.watch(
        businessReviewsProvider(businessId).future,
      );
      if (reviews.isEmpty) return const {};
      final query = SupabaseConfig.client
          .from('comments')
          .select(
            'id, entity_id, author_id, author_name, body, status, created_at',
          )
          .eq('entity_type', 'review')
          .inFilter('entity_id', [for (final r in reviews) r.id]);
      // Approved and pending ones, and the writer's own whatever its state,
      // so a reply the team hid says so to its writer rather than vanishing.
      final rows = await (me == null
              ? query.inFilter('status', ['approved', 'pending'])
              : query.or('status.in.(approved,pending),author_id.eq.$me'))
          .order('created_at', ascending: true);
      final byReview = <String, List<ReviewReply>>{};
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        final reply = ReviewReply.fromJson(r);
        byReview.putIfAbsent(reply.reviewId, () => []).add(reply);
      }
      return byReview;
    });

/// Writes a reply to a review.
///
/// True when it is live at once — the default since 00063; false when the
/// panel's Settings ask for replies to be approved first. The database
/// decides, so the app reports what it did rather than guessing.
Future<bool> addReviewReply({
  required String reviewId,
  required String body,
}) async {
  final uid = SupabaseConfig.client.auth.currentUser?.id;
  if (uid == null) throw StateError('signed-out');
  final row = await SupabaseConfig.client
      .from('comments')
      .insert({
        'entity_type': 'review',
        'entity_id': reviewId,
        'author_id': uid,
        'body': body.trim(),
      })
      .select('status')
      .single();
  return row['status'] == 'approved';
}

/// Removes the signed-in person's own reply.
Future<void> deleteReviewReply(String replyId) async {
  await SupabaseConfig.client.from('comments').delete().eq('id', replyId);
}

/// The numbers above the list, derived from the reviews themselves.
// Auto-disposed with the reviews it reads: a provider kept for the session
// kept them alive too, and the page showed them as first loaded.
final businessReviewSummaryProvider = Provider.autoDispose.family<ReviewSummary, String>((
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

/// Whether the signed-in person has already reviewed this business.
///
/// The form is hidden once they have — the old one let anyone submit
/// repeatedly into a list held in memory.
final hasReviewedProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  businessId,
) async {
  final user = ref.watch(authProvider);
  if (user == null) return false;
  return ref.watch(businessRepositoryProvider).hasReviewed(businessId);
});

/// A business's photographs, in the order WordPress had them.
///
/// These were in the export all along — 513 photographs across 108
/// businesses — and nothing loaded them, so every business page showed its
/// cover and the Photos tab said there was nothing to see. They are in the
/// `media` bucket now, not on modiin4u.co.il, because that site sends no CORS
/// header and a browser will not draw its images. See
/// `tool/import_business_galleries.py`.
final businessGalleryProvider =
    FutureProvider.family<List<String>, String>((ref, businessId) async {
      final rows = await SupabaseConfig.client
          .from('entity_media')
          .select('sort_order, media(url)')
          .eq('entity_type', 'business')
          .eq('entity_id', businessId)
          .eq('role', 'gallery')
          .order('sort_order', ascending: true);
      return [
        for (final r in List<Map<String, dynamic>>.from(rows))
          if ((r['media'] as Map?)?['url'] is String)
            (r['media'] as Map)['url'] as String,
      ];
    });
