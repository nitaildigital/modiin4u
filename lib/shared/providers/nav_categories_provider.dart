import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';

/// One entry in a navbar menu.
class NavCategory {
  final String id;
  final String name;
  final int count;

  const NavCategory({required this.id, required this.name, required this.count});
}

/// The categories a navbar menu offers, for one scope — `article` or
/// `business`.
///
/// **Only the ones with something in them.** The chevrons beside "Modiin
/// News" and "Businesses" drew an arrow and opened nothing, and the obvious
/// fix — list every category — would have been worse: five of the article
/// categories are left over from an early guess at the taxonomy and hold no
/// articles at all, so half the menu would have led to an empty page.
///
/// The count comes back from the link table in the same request; `count` on
/// an embedded table is what PostgREST answers with rather than the rows.
final navCategoriesProvider =
    FutureProvider.family<List<NavCategory>, String>((ref, scope) async {
      // `*` rather than naming `in_menus`, which a database without 00047
      // does not have.
      final rows = await SupabaseConfig.client
          .from('categories')
          .select('*, entity_categories(count)')
          .eq('scope', scope)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final out = <NavCategory>[];
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        // Businesses: the main categories only. With the old site's 63
        // categories back (5 Oct) the menu listed some 80 names in columns
        // with no end, running off the screen; the sub-categories are a
        // click further, on each one's page and in the directory.
        if (scope == 'business' &&
            (r['parent_id'] != null || r['in_menus'] == false)) {
          continue;
        }
        final embed = r['entity_categories'];
        final count = embed is List && embed.isNotEmpty
            ? (embed.first['count'] as int? ?? 0)
            : 0;
        if (count == 0) continue;
        out.add(
          NavCategory(
            id: r['id'] as String,
            name: (r['name'] as String?) ?? '',
            count: count,
          ),
        );
      }
      return out;
    });

/// The people the Professionals menu lists.
///
/// A professional is a business filed under Services — the client's
/// WordPress professionals were imported that way, with their trades as
/// Services' children — the same rule the home page's "Find a Professional"
/// row uses. So the menu names those businesses, and each leads to its page.
///
/// Two requests, not three: the links are read through the category's slug
/// in one go. The menu opened empty for a second or two while three ran one
/// after another.
final navProfessionalsProvider = FutureProvider<List<NavCategory>>((ref) async {
  final client = SupabaseConfig.client;
  final links = await client
      .from('entity_categories')
      .select('entity_id, categories!inner(slug, scope)')
      .eq('entity_type', 'business')
      .eq('categories.slug', 'services')
      .eq('categories.scope', 'business');
  final ids = [
    for (final l in List<Map<String, dynamic>>.from(links))
      l['entity_id'] as String,
  ];
  if (ids.isEmpty) return const [];

  final rows = await client
      .from('businesses')
      .select('id, name')
      .inFilter('id', ids)
      .eq('status', 'active')
      .order('name', ascending: true);
  return [
    for (final r in List<Map<String, dynamic>>.from(rows))
      NavCategory(
        id: r['id'] as String,
        name: (r['name'] as String?) ?? '',
        count: 1,
      ),
  ];
});

/// One category's name, by id — or by slug, as `/businesses/category/services`
/// names Professionals.
///
/// The business category page took its heading from a `?title=` on the URL
/// and fell back to the word "עסקים" — so every category read "Businesses",
/// and a shared link without the query string lost the name entirely. The
/// name belongs to the row, not to the link.
final categoryNameProvider =
    FutureProvider.family<String?, String>((ref, categoryId) async {
      final isId = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(categoryId);
      final row = await SupabaseConfig.client
          .from('categories')
          .select('name')
          .eq(isId ? 'id' : 'slug', categoryId)
          .limit(1)
          .maybeSingle();
      return row?['name'] as String?;
    });
