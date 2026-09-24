import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/offer.dart';

/// Reads `offers`, and records a claim against one.
///
/// The read policy returns only `active` rows to anyone who is not an
/// administrator, so the list needs no status filter of its own to be safe —
/// it passes one anyway, to say what it means.
class OfferRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  static const _select = '''
    *,
    businesses(id, name, address, logo_url, cover_url)
  ''';

  Future<List<Offer>> fetchActive({String? categoryId, int limit = 60}) async {
    var query = _client.from('offers').select(_select).eq('status', 'active');

    // A deal belongs to a business, and a business belongs to a category, so
    // narrowing by category means narrowing by the businesses in it.
    if (categoryId != null && categoryId.isNotEmpty) {
      final ids = await _businessIdsInCategory(categoryId);
      if (ids.isEmpty) return const [];
      query = query.inFilter('business_id', ids);
    }

    final rows = await query
        .order('is_featured', ascending: false)
        .order('end_at', ascending: true, nullsFirst: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows).map(Offer.fromJson).toList();
  }

  Future<List<String>> _businessIdsInCategory(String categoryId) async {
    final rows = await _client
        .from('entity_categories')
        .select('entity_id')
        .eq('entity_type', 'business')
        .eq('category_id', categoryId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['entity_id'] as String).toList();
  }

  Future<Offer?> fetchById(String id) async {
    final row = await _client
        .from('offers')
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Offer.fromJson(row);
  }

  /// How many active offers sit in each category, keyed by category id.
  ///
  /// The category row used to carry fixed counts — 62, 48, 31 — written into
  /// the screen. This counts them.
  Future<Map<String, int>> fetchCountsByCategory() async {
    final offers = await _client
        .from('offers')
        .select('business_id')
        .eq('status', 'active');

    final businessIds = List<Map<String, dynamic>>.from(
      offers,
    ).map((r) => r['business_id'] as String?).whereType<String>().toSet();
    if (businessIds.isEmpty) return const {};

    final links = await _client
        .from('entity_categories')
        .select('category_id, entity_id')
        .eq('entity_type', 'business')
        .inFilter('entity_id', businessIds.toList());

    final counts = <String, int>{};
    for (final row in List<Map<String, dynamic>>.from(links)) {
      final id = row['category_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// The offers this person has already claimed, as offer ids.
  Future<Set<String>> fetchMyClaims(String profileId) async {
    final rows = await _client
        .from('offer_claims')
        .select('offer_id')
        .eq('profile_id', profileId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['offer_id'] as String).toSet();
  }

  /// Takes the offer. Returns the claim row so the screen can show the code.
  ///
  /// `max_per_user` is enforced here rather than trusted from the button
  /// being hidden, because the button can be reached again from a link.
  Future<Map<String, dynamic>> claim(Offer offer) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('An offer can only be claimed by a signed-in account.');
    }

    final mine = await _client
        .from('offer_claims')
        .select('id')
        .eq('offer_id', offer.id)
        .eq('profile_id', uid);
    final already = List<Map<String, dynamic>>.from(mine).length;
    if (already >= (offer.maxPerUser ?? 1)) {
      throw StateError('already-claimed');
    }

    return await _client
        .from('offer_claims')
        .insert({'offer_id': offer.id, 'profile_id': uid})
        .select()
        .single();
  }
}
