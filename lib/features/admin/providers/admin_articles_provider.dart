import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

/// The news desk, on the live table.
///
/// This held six invented articles in memory. The site has 669, and they are
/// the client's largest body of content, so this is the screen he will spend
/// most of his time in.
final adminArticleListProvider =
    StateNotifierProvider<
      AdminArticleListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminArticleListNotifier();
    });

/// Article categories, from the table.
final articleCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('categories')
      .select('id, name, slug, scope, is_active, sort_order')
      .eq('scope', 'article')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});

/// The categories one article sits in.
final articleCategoryIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  articleId,
) async {
  final rows = await SupabaseConfig.client
      .from('entity_categories')
      .select('category_id')
      .eq('entity_type', 'article')
      .eq('entity_id', articleId);
  return List<Map<String, dynamic>>.from(
    rows,
  ).map((r) => r['category_id'] as String).toList();
});

class AdminArticleListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  String? _search;
  String? _status;

  AdminArticleListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      var query = SupabaseConfig.client.from('articles').select();

      if (_status != null && _status!.isNotEmpty) {
        query = query.eq('status', _status!);
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.replaceAll(',', ' ');
        query = query.or('title.ilike.%$q%,slug.ilike.%$q%');
      }

      final rows = await query
          .order('published_at', ascending: false, nullsFirst: false)
          .limit(500);

      if (mounted) {
        state = AsyncValue.data([
          for (final r in List<Map<String, dynamic>>.from(rows)) _toForm(r),
        ]);
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void setSearch(String? search) {
    _search = search;
    load();
  }

  void setStatusFilter(String? status) {
    _status = status;
    load();
  }

  // ── The editor and the table disagree on two names ──
  //
  // The form was written against a schema that was never deployed: it calls
  // the picture `cover_image_url` where the column is `featured_image`, and
  // carries a `category_id` where categories live in `entity_categories`.
  // Translating here keeps the screen as it is.

  Map<String, dynamic> _toForm(Map<String, dynamic> row) => {
    ...row,
    'cover_image_url': row['featured_image'],
  };

  /// Columns the form does not own: counts the database keeps, and the two
  /// names above.
  static const _notColumns = {
    'cover_image_url',
    'category_id',
    'id',
    'created_at',
    'updated_at',
    'view_count',
    'unique_views',
    'share_count',
    'save_count',
  };

  Map<String, dynamic> _toRow(Map<String, dynamic> fields) {
    final row = {
      for (final e in fields.entries)
        if (!_notColumns.contains(e.key)) e.key: e.value,
    };
    if (fields.containsKey('cover_image_url')) {
      row['featured_image'] = fields['cover_image_url'];
    }
    return row;
  }

  Future<void> createArticle(Map<String, dynamic> article) async {
    final row = _toRow(article);

    // Publishing without a date leaves the article out of every list the app
    // orders by it, which reads as the save having failed.
    if (row['status'] == 'published' && row['published_at'] == null) {
      row['published_at'] = DateTime.now().toIso8601String();
    }

    final inserted = await SupabaseConfig.client
        .from('articles')
        .insert(row)
        .select('id')
        .single();

    final id = inserted['id'] as String;
    final categoryId = article['category_id'] as String?;
    if (categoryId != null && categoryId.isNotEmpty) {
      await setCategories(id, [categoryId]);
    }
    await load();
  }

  Future<void> updateArticle(String id, Map<String, dynamic> fields) async {
    final row = _toRow(fields);
    if (row['status'] == 'published' && row['published_at'] == null) {
      row['published_at'] = DateTime.now().toIso8601String();
    }
    await SupabaseConfig.client.from('articles').update(row).eq('id', id);

    if (fields.containsKey('category_id')) {
      final categoryId = fields['category_id'] as String?;
      await setCategories(id, [
        if (categoryId != null && categoryId.isNotEmpty) categoryId,
      ]);
    }
    await load();
  }

  /// Archives rather than removes.
  ///
  /// Deleting would take the article's comments with it, and an article the
  /// client changes his mind about should be recoverable.
  Future<void> deleteArticle(String id) async {
    await updateStatus(id, 'archived');
  }

  Future<void> updateStatus(String id, String status) async {
    final patch = <String, dynamic>{'status': status};
    if (status == 'published') {
      patch['published_at'] = DateTime.now().toIso8601String();
    }
    await SupabaseConfig.client.from('articles').update(patch).eq('id', id);
    await load();
  }

  Future<void> setCategories(String articleId, List<String> categoryIds) async {
    final client = SupabaseConfig.client;
    await client
        .from('entity_categories')
        .delete()
        .eq('entity_type', 'article')
        .eq('entity_id', articleId);

    if (categoryIds.isEmpty) return;
    await client.from('entity_categories').insert([
      for (final id in categoryIds)
        {'entity_type': 'article', 'entity_id': articleId, 'category_id': id},
    ]);
  }
}
