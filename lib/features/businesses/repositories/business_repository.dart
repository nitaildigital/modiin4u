import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

class BusinessRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> fetchAll({
    String? search,
    String? status,
    String? categoryId,
    String? neighborhoodId,
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
      neighborhoods!businesses_neighborhood_id_fkey(id, name, slug)
    ''');

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (neighborhoodId != null && neighborhoodId.isNotEmpty) {
      query = query.eq('neighborhood_id', neighborhoodId);
    }
    if (ids != null) {
      query = query.inFilter('id', ids);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,short_description.ilike.%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Business ids linked to a category.
  Future<List<String>> fetchBusinessIdsInCategory(String categoryId) async {
    final data = await _client
        .from('entity_categories')
        .select('entity_id')
        .eq('entity_type', 'business')
        .eq('category_id', categoryId);
    return List<Map<String, dynamic>>.from(data).map((r) => r['entity_id'] as String).toList();
  }

  /// How many businesses sit in each category, keyed by category id.
  Future<Map<String, int>> fetchCategoryCounts() async {
    final data = await _client.from('entity_categories').select('category_id').eq('entity_type', 'business');

    final counts = <String, int>{};
    for (final row in List<Map<String, dynamic>>.from(data)) {
      final id = row['category_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<String, dynamic>> fetchById(String id) async {
    final data = await _client
        .from('businesses')
        .select('''
      *,
      neighborhoods!businesses_neighborhood_id_fkey(id, name, slug),
      business_hours(*)
    ''')
        .eq('id', id)
        .single();
    return data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> business) async {
    final data = await _client.from('businesses').insert(business).select().single();
    return data;
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> fields) async {
    final data = await _client.from('businesses').update(fields).eq('id', id).select().single();
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
    final data = await _client.from('neighborhoods').select().eq('is_active', true).order('sort_order');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('scope', 'business')
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(data);
  }
}
