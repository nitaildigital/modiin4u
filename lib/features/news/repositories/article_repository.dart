import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';

class ArticleRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> fetchAll({
    String? search,
    String? status,
  }) async {
    var query = _client.from('articles').select();

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('title.ilike.%$search%,slug.ilike.%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> fetchById(String id) async {
    final data = await _client.from('articles').select().eq('id', id).single();
    return data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> article) async {
    final data = await _client.from('articles').insert(article).select().single();
    return data;
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> fields) async {
    final data = await _client.from('articles').update(fields).eq('id', id).select().single();
    return data;
  }

  Future<void> delete(String id) async {
    await _client.from('articles').delete().eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'published') {
      updates['published_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('articles').update(updates).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('scope', 'article')
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(data);
  }
}
