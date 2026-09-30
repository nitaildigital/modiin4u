import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../news/models/article.dart';
import '../../news/providers/news_providers.dart';

/// What the Community page links to, as the client sets it in the panel
/// (Remote Config): his Facebook group, his "share with us" form, and the
/// news category the page lists. All three come from his WordPress site
/// (`tool/seed_community_settings.py`); an empty or missing link hides its
/// card rather than pointing somewhere made up.
class CommunitySettings {
  final String? facebookUrl;
  final String? shareUrl;
  final String? newsCategorySlug;

  const CommunitySettings({this.facebookUrl, this.shareUrl, this.newsCategorySlug});
}

final communitySettingsProvider = FutureProvider<CommunitySettings>((ref) async {
  final rows = await SupabaseConfig.client
      .from('remote_config')
      .select('key, value')
      .inFilter('key', [
        'community_facebook_url',
        'community_share_url',
        'community_news_category',
      ]);
  final values = {
    for (final r in List<Map<String, dynamic>>.from(rows))
      r['key'] as String: (r['value'] as String? ?? '').trim(),
  };
  String? value(String key) =>
      (values[key] ?? '').isEmpty ? null : values[key];
  return CommunitySettings(
    facebookUrl: value('community_facebook_url'),
    shareUrl: value('community_share_url'),
    newsCategorySlug: value('community_news_category'),
  );
});

/// The chosen news category — its id, for "See all" — and its newest
/// stories. Null when no category is set or the slug matches none.
final communityNewsProvider =
    FutureProvider<({String categoryId, List<Article> articles})?>((ref) async {
      final slug = (await ref.watch(communitySettingsProvider.future))
          .newsCategorySlug;
      if (slug == null) return null;
      final rows = await SupabaseConfig.client
          .from('categories')
          .select('id')
          .eq('slug', slug)
          .eq('scope', 'article')
          .limit(1);
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty) return null;
      final id = list.first['id'] as String;
      final articles = await ref.watch(articlesByCategoryProvider(id).future);
      return (categoryId: id, articles: articles.take(8).toList());
    });
