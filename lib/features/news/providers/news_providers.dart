import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

import '../models/article.dart';
import '../repositories/article_repository.dart';
import '../../../shared/providers/nav_categories_provider.dart';

final articleRepositoryProvider =
    Provider<ArticleRepository>((ref) => ArticleRepository());

/// Published articles, newest first.
final publishedArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final rows =
      await ref.watch(articleRepositoryProvider).fetchAll(status: 'published');
  return rows.map(Article.fromJson).toList();
});

/// The articles filed under one category.
///
/// `entity_categories` is a polymorphic link table: `entity_id` carries an
/// article, a business or an event depending on `entity_type`, so there is no
/// foreign key to `articles` and PostgREST cannot join the two. It answers
/// PGRST200 if asked. So the ids are fetched on their own and matched against
/// the articles the page has already loaded — which costs one small query
/// rather than a second copy of 667 rows.
final _articleIdsInCategoryProvider =
    FutureProvider.family<Set<String>, String>((ref, categoryId) async {
      final rows = await SupabaseConfig.client
          .from('entity_categories')
          .select('entity_id')
          .eq('entity_type', 'article')
          .eq('category_id', categoryId);
      return {
        for (final r in List<Map<String, dynamic>>.from(rows))
          r['entity_id'] as String,
      };
    });

/// Published articles in one category, newest first.
///
/// The import carried the articles and left their filing behind, so this had
/// nothing to read until the categories were brought across from the client's
/// site. See `tool/import_article_categories.py`.
final articlesByCategoryProvider =
    FutureProvider.family<List<Article>, String>((ref, categoryId) async {
      final ids = await ref.watch(
        _articleIdsInCategoryProvider(categoryId).future,
      );
      final all = await ref.watch(publishedArticlesProvider.future);
      return all.where((a) => ids.contains(a.id)).toList();
    });

/// The category each article is filed under, by article id — the name the
/// design prints in a turquoise chip on the front of the news page.
///
/// One read of the links with the category's name joined on; the link table
/// has a real foreign key to `categories`, so this embed works where the one
/// to `articles` could not. An article filed twice keeps the link marked
/// primary, or the first.
final articleCategoryNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final filed = await ref.watch(articleFilingProvider.future);
  return {for (final e in filed.entries) e.key: e.value.name};
});

/// The category each article is filed under — its id and its name — by
/// article id. The article page's chip leads to the category, and its "More
/// Related News" are the category's other stories, so both need the id.
final articleFilingProvider =
    FutureProvider<Map<String, NavCategory>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('entity_categories')
          .select('entity_id, category_id, is_primary, categories(*)')
          .eq('entity_type', 'article');
      final filed = <String, NavCategory>{};
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        final category = r['categories'] as Map?;
        final he = category?['name'] as String?;
        if (he == null || he.isEmpty) continue;
        final id = r['entity_id'] as String;
        if (!filed.containsKey(id) || r['is_primary'] == true) {
          // Its name is read in the language on screen at the time.
          filed[id] = NavCategory(
            id: r['category_id'] as String,
            name: he,
            nameEn: category?['name_en'] as String?,
            count: 1,
          );
        }
      }
      return filed;
    });

/// "More Related News" beside an article: the newest stories filed under
/// the same category, topped up with the newest of all when the category has
/// fewer than four others. The article itself is never among them.
///
/// Newest by `published_at`: every imported row carries the same
/// `created_at`, so the order the rows come back in says nothing.
final relatedArticlesProvider =
    FutureProvider.family<List<Article>, String>((ref, articleId) async {
      const count = 4;
      final all = [...await ref.watch(publishedArticlesProvider.future)]
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      final category =
          (await ref.watch(articleFilingProvider.future))[articleId];

      final picked = <Article>[];
      if (category != null) {
        final same = await ref.watch(
          articlesByCategoryProvider(category.id).future,
        );
        final ids = {for (final a in same) a.id};
        picked.addAll(
          all.where((a) => a.id != articleId && ids.contains(a.id)).take(count),
        );
      }
      final shown = {articleId, for (final a in picked) a.id};
      picked.addAll(
        all.where((a) => !shown.contains(a.id)).take(count - picked.length),
      );
      return picked;
    });

/// The article shown in the hero slot.
///
/// The hero is a large picture with the headline across it, so an article
/// with no `featured_image` leaves the slot as a grey placeholder — which is
/// what the front page was showing, because both articles flagged featured
/// happen to carry no image. Twenty-five published articles have none.
///
/// Which article is featured is the client's to decide in the admin panel, so
/// this does not override him: it prefers a featured article that can
/// actually fill the slot, and only falls back to a featured one without a
/// picture if that is all there is.
final featuredArticleProvider = FutureProvider<Article?>((ref) async {
  final articles = await ref.watch(publishedArticlesProvider.future);
  return articles.isEmpty ? null : pickHeroArticle(articles);
});

/// The rule itself, in one place. The phone's list built its own copy of it
/// and the two would drift apart, which is how the web and the phone came to
/// disagree elsewhere in this app.
Article pickHeroArticle(List<Article> articles) {
  bool hasPicture(Article a) => (a.imageUrl ?? '').isNotEmpty;

  return articles.firstWhere(
    (a) => a.isFeatured && hasPicture(a),
    orElse: () => articles.firstWhere(
      (a) => a.isFeatured,
      orElse: () =>
          articles.firstWhere(hasPicture, orElse: () => articles.first),
    ),
  );
}

/// Every published article except the one in the hero slot.
final restOfArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final articles = await ref.watch(publishedArticlesProvider.future);
  final featured = await ref.watch(featuredArticleProvider.future);
  return articles.where((a) => a.id != featured?.id).toList();
});

/// A single article by id.
final articleByIdProvider =
    FutureProvider.family<Article, String>((ref, id) async {
  final row = await ref.watch(articleRepositoryProvider).fetchById(id);
  return Article.fromJson(row);
});
