import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../repositories/article_repository.dart';

final articleRepositoryProvider =
    Provider<ArticleRepository>((ref) => ArticleRepository());

/// Published articles, newest first.
final publishedArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final rows =
      await ref.watch(articleRepositoryProvider).fetchAll(status: 'published');
  return rows.map(Article.fromJson).toList();
});

/// The article shown in the hero slot — the featured one if there is a
/// featured article, otherwise the most recent.
final featuredArticleProvider = FutureProvider<Article?>((ref) async {
  final articles = await ref.watch(publishedArticlesProvider.future);
  if (articles.isEmpty) return null;
  return articles.firstWhere((a) => a.isFeatured, orElse: () => articles.first);
});

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
