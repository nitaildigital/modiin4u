import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';

class ArticleRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// What a list or a card draws, and nothing more: not the body, nor the
  /// SEO fields. The news list read every column of every article — 1.8 MB
  /// of bodies alone, on every open and every return to the app (9 Oct).
  /// The article page reads its own row in full ([fetchById]).
  static const listColumns = 'id,title,subtitle,slug,excerpt,featured_image,mobile_image,og_image,credit,'
      'status,is_breaking,is_featured,view_count,share_count,published_at,updated_at,created_at';

  /// Every published article for the lists, newest first, a thousand rows
  /// a request — the most the database returns at once, which would
  /// otherwise cut the list without saying so.
  Future<List<Map<String, dynamic>>> fetchPublishedList() async {
    final out = <Map<String, dynamic>>[];
    for (var from = 0;; from += 1000) {
      final page = await _client
          .from('articles')
          .select(listColumns)
          .eq('status', 'published')
          .order('published_at', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false)
          .order('id')
          .range(from, from + 999);
      out.addAll(List<Map<String, dynamic>>.from(page));
      if (page.length < 1000) break;
    }
    return out;
  }

  /// The search's article hits: the card columns, the newest [limit].
  Future<List<Map<String, dynamic>>> search(String q, {int limit = 30}) async {
    final data = await _client
        .from('articles')
        .select(listColumns)
        .eq('status', 'published')
        .or('title.ilike.%$q%,slug.ilike.%$q%')
        .order('published_at', ascending: false, nullsFirst: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

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

    // `published_at`, not `created_at`. Every one of the 669 imported
    // articles carries the same `created_at` — 23 September 2026, the day
    // of the import — so ordering by it put the feed in no order at all,
    // and the "latest" articles on the home page came out from 2024.
    final data = await query
        .order('published_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false);
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
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }
}
