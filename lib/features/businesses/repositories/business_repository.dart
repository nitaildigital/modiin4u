import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

class BusinessRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> fetchAll({
    String? search,
    String? status,
    String? categoryId,
    String? neighborhoodId,
    // The directory reads businesses; the Parks page asks for parks. Null
    // reads both, which search wants — a park is found by its name too.
    String? kind = 'business',
  }) async {
    // Categories live in `entity_categories`, so narrow to the ids in that
    // category first rather than trying to filter across the join.
    List<String>? ids;
    if (categoryId != null && categoryId.isNotEmpty) {
      ids = await fetchBusinessIdsInCategory(categoryId);
      if (ids.isEmpty) return const [];
    }

    var query = _client.from('businesses').select('''
      *,
      neighborhoods!businesses_neighborhood_id_fkey(id, name, name_en, slug)
    ''');

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (kind != null) {
      query = query.eq('kind', kind);
    }
    if (neighborhoodId != null && neighborhoodId.isNotEmpty) {
      query = query.eq('neighborhood_id', neighborhoodId);
    }
    if (ids != null) {
      query = query.inFilter('id', ids);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        // The English name too (00062 — run it before this is deployed).
        'name.ilike.%$search%,name_en.ilike.%$search%,short_description.ilike.%$search%',
      );
    }

    // A business with a promotion running stands first (00069 clears one
    // when it ends, so a plain descending order is enough). A database
    // without 00069 has no such column, and the list must still load.
    try {
      final data = await query
          .order('promoted_until', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      if (!e.message.contains('promoted_until')) rethrow;
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    }
  }

  /// Business ids linked to a category, named by its id or its slug — the
  /// site links Professionals as `/businesses/category/services`. A main
  /// category includes the businesses filed only under one of its
  /// sub-categories, as the old site's category pages did.
  Future<List<String>> fetchBusinessIdsInCategory(String categoryIdOrSlug) async {
    // A category the panel switched off lists nothing, by id or by address.
    final row = await _client
        .from('categories')
        .select('id')
        .eq('scope', 'business')
        .eq('is_active', true)
        .eq(_uuid.hasMatch(categoryIdOrSlug) ? 'id' : 'slug', categoryIdOrSlug)
        .maybeSingle();
    if (row == null) return const [];
    final categoryId = row['id'] as String;
    final children = await _client
        .from('categories')
        .select('id')
        .eq('parent_id', categoryId)
        .eq('is_active', true);
    final data = await _client
        .from('entity_categories')
        .select('entity_id')
        .eq('entity_type', 'business')
        .inFilter('category_id', [
          categoryId,
          for (final c in List<Map<String, dynamic>>.from(children)) c['id'] as String,
        ]);
    return {
      for (final r in List<Map<String, dynamic>>.from(data)) r['entity_id'] as String,
    }.toList();
  }

  /// How many businesses sit in each category, keyed by category id. A main
  /// category counts its sub-categories' businesses too, each once, so the
  /// number on its card matches the list it opens.
  Future<Map<String, int>> fetchCategoryCounts() async {
    final data = await _client
        .from('entity_categories')
        .select('entity_id, category_id')
        .eq('entity_type', 'business');
    final categories = await _client.from('categories').select('id, parent_id');
    final parentOf = {
      for (final c in List<Map<String, dynamic>>.from(categories))
        c['id'] as String: c['parent_id'] as String?,
    };

    final members = <String, Set<String>>{};
    for (final row in List<Map<String, dynamic>>.from(data)) {
      final business = row['entity_id'] as String;
      final id = row['category_id'] as String;
      members.putIfAbsent(id, () => {}).add(business);
      final parent = parentOf[id];
      if (parent != null) members.putIfAbsent(parent, () => {}).add(business);
    }
    return {for (final e in members.entries) e.key: e.value.length};
  }

  /// Every business-to-category link, as `{entity_id, category_id}`.
  ///
  /// One query rather than one per category: the map needs to know which
  /// category each pin belongs to, and there are only a couple of hundred
  /// links in total.
  Future<List<Map<String, dynamic>>> fetchCategoryLinks() async {
    final data = await _client
        .from('entity_categories')
        .select('entity_id, category_id')
        .eq('entity_type', 'business');
    return List<Map<String, dynamic>>.from(data);
  }

  /// One business, by its id or by its slug.
  ///
  /// Links reach the page both ways: the site's own cards use the id, and
  /// the articles brought over from WordPress link to `/business/<slug>/`,
  /// which is how the old site addressed a business. Throws
  /// [BusinessNotFound] when neither matches.
  Future<Map<String, dynamic>> fetchById(String idOrSlug) async {
    final key = Uri.decodeComponent(idOrSlug).trim().replaceAll(RegExp(r'/+$'), '');
    final isId = _uuid.hasMatch(key);
    final data = await _client
        .from('businesses')
        .select('''
      *,
      neighborhoods!businesses_neighborhood_id_fkey(id, name, name_en, slug),
      business_hours(*)
    ''')
        .eq(isId ? 'id' : 'slug', key)
        .limit(1)
        .maybeSingle();
    if (data == null) throw BusinessNotFound(idOrSlug);
    return data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> business) async {
    final data = await _client
        .from('businesses')
        .insert(business)
        .select()
        .single();
    return data;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final data = await _client
        .from('businesses')
        .update(fields)
        .eq('id', id)
        .select()
        .single();
    return data;
  }

  Future<void> delete(String id) async {
    await _client.from('businesses').delete().eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'active') {
      updates['approved_at'] = DateTime.now().toIso8601String();
    } else if (status == 'closed') {
      updates['closed_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('businesses').update(updates).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchNeighborhoods() async {
    final data = await _client
        .from('neighborhoods')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('scope', 'business')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  /// A business's menu, in the order the admin set.
  ///
  /// Empty for most of them: the Menu tab used to show the same invented
  /// menu on all 220 businesses, and the tab is now hidden when this comes
  /// back with nothing.
  Future<List<Map<String, dynamic>>> fetchMenuItems(String businessId) async {
    final data = await _client
        .from('business_menu_items')
        .select()
        .eq('business_id', businessId)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Writes a review.
  ///
  /// It arrives as `pending` — the column's own default — so it does not
  /// move the business's score until an administrator approves it. The
  /// rollup trigger from migration 00025 does that the moment they do.
  ///
  /// The unique constraint is on nothing, so a second review by the same
  /// person would be a second row; the screen only offers the form to
  /// someone who has not reviewed yet, and this checks again because the
  /// form can be reached twice.
  Future<void> addReview({
    required String businessId,
    required int rating,
    String? body,
    List<String> photos = const [],
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('A review can only be left by a signed-in account.');
    }

    final existing = await _client
        .from('reviews')
        .select('id')
        .eq('business_id', businessId)
        .eq('author_id', uid)
        .maybeSingle();
    if (existing != null) throw StateError('already-reviewed');

    await _client.from('reviews').insert({
      'business_id': businessId,
      'author_id': uid,
      'rating': rating,
      'body': (body ?? '').trim().isEmpty ? null : body!.trim(),
      if (photos.isNotEmpty) 'photos': photos,
    });
  }

  /// Whether this person agreed to show their profile photo next to what
  /// they write (true / false), or has not been asked (null) — and whether
  /// they have a photo at all.
  Future<({bool? consent, bool hasPhoto})> postPhotoConsent() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return (consent: null, hasPhoto: false);
    final row = await _client
        .from('profiles')
        .select('show_photo_on_posts, avatar_url')
        .eq('id', uid)
        .maybeSingle();
    return (
      consent: row?['show_photo_on_posts'] as bool?,
      hasPhoto: ((row?['avatar_url'] as String?) ?? '').isNotEmpty,
    );
  }

  Future<void> setPostPhotoConsent(bool show) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').update({'show_photo_on_posts': show}).eq('id', uid);
  }

  /// Whether this person has already reviewed this business, approved or
  /// not. The read policy lets an author see their own pending review.
  Future<bool> hasReviewed(String businessId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    final row = await _client
        .from('reviews')
        .select('id')
        .eq('business_id', businessId)
        .eq('author_id', uid)
        .maybeSingle();
    return row != null;
  }
}

/// No business has this id or slug — a link to one since removed, or a
/// mistyped address. Told apart from a failed connection, which a retry can
/// mend and this cannot.
class BusinessNotFound implements Exception {
  final String key;
  const BusinessNotFound(this.key);
  @override
  String toString() => 'No business "$key"';
}

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
