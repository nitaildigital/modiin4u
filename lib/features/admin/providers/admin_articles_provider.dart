import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show CountOption;

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart' show auditActionFor, recordAdminAction;

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
///
/// Inactive ones are fetched too. The picker offers only the active ones, but
/// an article already filed under one that was since switched off must still
/// show it — otherwise the link is invisible in the editor, and the list's
/// category column would name a category the editor seems not to have.
final articleCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('categories')
      .select('id, name, slug, scope, is_active, sort_order')
      .eq('scope', 'article')
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});

/// Now, as the database should store it.
///
/// `DateTime.now().toIso8601String()` has no zone on it, and the column reads
/// a zoneless time as UTC — so an article saved at 12:00 in Modiin was stamped
/// 12:00 UTC, three hours ahead, and sat at the top of the feed dated in the
/// future. Converted to UTC first, the string ends in `Z` and means what it
/// says.
String nowForDatabase() => DateTime.now().toUtc().toIso8601String();

class AdminArticleListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  static const _pageSize = 500;

  String? _search;
  String? _status;

  /// How many rows the table holds, which is not how many were fetched.
  int totalCount = 0;

  int _window = _pageSize;

  bool get hasMore => totalCount > _window;

  /// Set while widening the window, so the rows already on screen stay put
  /// instead of being replaced by a spinner.
  bool _loadingMore = false;

  AdminArticleListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> loadMore() async {
    _window += _pageSize;
    _loadingMore = true;
    try {
      await load();
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> load() async {
    if (!_loadingMore) state = const AsyncValue.loading();
    try {
      var query = SupabaseConfig.client.from('articles').select();

      if (_status != null && _status!.isNotEmpty) {
        query = query.eq('status', _status!);
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.replaceAll(',', ' ');
        query = query.or('title.ilike.%$q%,slug.ilike.%$q%');
      }

      // The count is asked for separately from the rows: there are 669
      // articles against a 500 limit, so the panel reported "500 articles"
      // and the oldest 169 could neither be seen nor edited.
      final rows = await query
          .order('published_at', ascending: false, nullsFirst: false)
          .limit(_window)
          .count(CountOption.exact);

      final list = List<Map<String, dynamic>>.from(rows.data);
      final names = await _categoryNamesOf([
        for (final r in list) r['id'] as String,
      ]);

      if (mounted) {
        totalCount = rows.count;
        state = AsyncValue.data([
          for (final r in list)
            {
              ..._toForm(r),
              if (names != null)
                'category_names': names[r['id']] ?? const <String>[],
            },
        ]);
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// The names of the categories each article is filed under, for the list.
  ///
  /// The list's category column read a `category_name` nothing ever set, so
  /// it was blank on all 669 rows. The links are asked for a hundred articles
  /// at a time: the ids go into the address, and five hundred of them would
  /// make one too long to send.
  ///
  /// Null when the lookup fails — the column then stays empty rather than
  /// claiming every article is unfiled.
  Future<Map<String, List<String>>?> _categoryNamesOf(List<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final chunks = [
        for (var i = 0; i < ids.length; i += 100)
          ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100),
      ];
      final results = await Future.wait([
        for (final chunk in chunks)
          SupabaseConfig.client
              .from('entity_categories')
              .select('entity_id, categories(name, sort_order)')
              .eq('entity_type', 'article')
              .inFilter('entity_id', chunk),
      ]);
      final byArticle = <String, List<(int, String)>>{};
      for (final rows in results) {
        for (final r in List<Map<String, dynamic>>.from(rows)) {
          final cat = r['categories'] as Map?;
          final name = cat?['name'] as String?;
          if (name == null) continue;
          (byArticle[r['entity_id'] as String] ??= []).add((
            (cat?['sort_order'] as num?)?.toInt() ?? 0,
            name,
          ));
        }
      }
      return {
        for (final e in byArticle.entries)
          e.key: ([
            ...e.value,
          ]..sort((a, b) => a.$1.compareTo(b.$1))).map((c) => c.$2).toList(),
      };
    } catch (_) {
      return null;
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

  // ── The editor and the table disagree on a name ──
  //
  // The form was written against a schema that was never deployed: it calls
  // the picture `cover_image_url` where the column is `featured_image`.
  // Translating here keeps the screen as it is. Categories are not a column
  // at all — they live in `entity_categories` and travel separately.

  Map<String, dynamic> _toForm(Map<String, dynamic> row) => {
    ...row,
    'cover_image_url': row['featured_image'],
  };

  /// Columns the form does not own: counts the database keeps, and the
  /// form's own names.
  static const _notColumns = {
    'cover_image_url',
    'category_id',
    'category_names',
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

  /// The categories an article is filed under, read fresh for the editor.
  ///
  /// Not taken from the list: the editor compares against this to work out
  /// what the person changed, so it has to be what the table holds now.
  Future<Set<String>> categoryIdsOf(String articleId) async {
    final rows = await SupabaseConfig.client
        .from('entity_categories')
        .select('category_id')
        .eq('entity_type', 'article')
        .eq('entity_id', articleId);
    return {
      for (final r in List<Map<String, dynamic>>.from(rows))
        r['category_id'] as String,
    };
  }

  Future<void> createArticle(
    Map<String, dynamic> article, {
    Set<String> categoryIds = const {},
  }) async {
    final row = _toRow(article);

    // Publishing without a date leaves the article out of every list the app
    // orders by it, which reads as the save having failed.
    if (row['status'] == 'published' && row['published_at'] == null) {
      row['published_at'] = nowForDatabase();
    }

    final inserted = await SupabaseConfig.client
        .from('articles')
        .insert(row)
        .select('id')
        .single();

    await changeCategories(inserted['id'] as String, add: categoryIds);
    // Articles saved straight to the table and left no trace in the audit
    // log, which every other section writes; now they do, as businesses do.
    await recordAdminAction(
      action: 'create',
      table: 'articles',
      rowId: inserted['id'] as String,
      fields: row,
      label: row['title'] as String?,
    );
    await load();
  }

  /// The row as it was loaded, for the audit log's "before".
  Map<String, dynamic>? _rowById(String id) {
    for (final r in state.valueOrNull ?? const <Map<String, dynamic>>[]) {
      if (r['id'] == id) return r;
    }
    return null;
  }

  /// Writes the columns in [fields] and nothing else, and moves only the
  /// category links in [addCategories] and [removeCategories].
  ///
  /// The editor used to send every field it had and a single `category_id`,
  /// and this replaced all of the article's links with that one. The editor
  /// never loaded the links in the first place, so opening an article and
  /// pressing save stripped its categories — 70 articles are filed under two
  /// or three. The editor now sends what changed and nothing more.
  Future<void> updateArticle(
    String id,
    Map<String, dynamic> fields, {
    Set<String> addCategories = const {},
    Set<String> removeCategories = const {},
  }) async {
    final row = _toRow(fields);
    final before = _rowById(id);
    if (row.isNotEmpty) {
      await SupabaseConfig.client.from('articles').update(row).eq('id', id);
    }
    if (row['status'] == 'published' && !row.containsKey('published_at')) {
      await _stampFirstPublication(id);
    }
    await changeCategories(id, add: addCategories, remove: removeCategories);
    if (row.isNotEmpty ||
        addCategories.isNotEmpty ||
        removeCategories.isNotEmpty) {
      await recordAdminAction(
        action: auditActionFor(row),
        table: 'articles',
        rowId: id,
        fields: {
          ...row,
          if (addCategories.isNotEmpty || removeCategories.isNotEmpty)
            'categories': true,
        },
        before: before,
        label: (row['title'] ?? before?['title']) as String?,
      );
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
    final before = _rowById(id);
    await SupabaseConfig.client
        .from('articles')
        .update({'status': status})
        .eq('id', id);
    if (status == 'published') await _stampFirstPublication(id);
    await recordAdminAction(
      action: auditActionFor({'status': status}),
      table: 'articles',
      rowId: id,
      fields: {'status': status},
      before: before,
      label: before?['title'] as String?,
    );
    await load();
  }

  /// Dates an article the first time it is published, and never again.
  ///
  /// Every save of a published article used to set `published_at` to now,
  /// so correcting a typo in a story from 2019 moved it to the top of the
  /// feed as today's news. The date is filled only where there is none; an
  /// article taken back to draft and published again keeps its original
  /// date, and the editor has a field for changing it on purpose.
  Future<void> _stampFirstPublication(String id) async {
    await SupabaseConfig.client
        .from('articles')
        .update({'published_at': nowForDatabase()})
        .eq('id', id)
        .isFilter('published_at', null);
  }

  /// Adds and removes individual category links, leaving the rest alone.
  Future<void> changeCategories(
    String articleId, {
    Set<String> add = const {},
    Set<String> remove = const {},
  }) async {
    final client = SupabaseConfig.client;
    if (remove.isNotEmpty) {
      await client
          .from('entity_categories')
          .delete()
          .eq('entity_type', 'article')
          .eq('entity_id', articleId)
          .inFilter('category_id', remove.toList());
    }
    if (add.isNotEmpty) {
      // Upserted with duplicates ignored, so a link someone else added in the
      // meantime is not an error and keeps its `is_primary`.
      await client
          .from('entity_categories')
          .upsert(
            [
              for (final c in add)
                {
                  'entity_type': 'article',
                  'entity_id': articleId,
                  'category_id': c,
                },
            ],
            onConflict: 'entity_type,entity_id,category_id',
            ignoreDuplicates: true,
          );
    }
  }
}
