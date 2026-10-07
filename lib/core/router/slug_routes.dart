import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../supabase/supabase_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../../shared/widgets/web_chrome.dart' show webIsHebrew;
import '../providers/content_language.dart';

/// The old WordPress site's addresses, served as they were.
///
/// The client (1 Oct): preserving the SEO "is critical" — the site's search
/// traffic is its strongest income source. Google knows the site by
/// addresses like `/news/modiin-news-523/` and `/business/<hebrew-name>/`, and
/// an address that keeps working keeps its ranking with nothing to
/// transfer. So the new site answers them: each looks its row up by the
/// slug — which the import kept as WordPress had it — and shows the page
/// the app would show for its id.
///
/// tool/seo_inventory.py checked all 979 addresses in the old sitemaps
/// against the database; the few with no row here are redirected by nginx
/// (deploy/nginx/seo-redirects.conf) rather than reaching this.
enum SlugKind {
  article('articles', 'id, title', null),
  // `*` for the English name, which a database without 00062 lacks.
  business('businesses', '*', null),
  businessCategory('categories', '*', 'business'),
  articleCategory('categories', '*', 'article');

  const SlugKind(this.table, this.columns, this.scope);
  final String table;
  final String columns;
  final String? scope;
}

typedef SlugRow = ({String id, String name});

final slugRowProvider =
    FutureProvider.family<SlugRow?, ({SlugKind kind, String slug})>((
      ref,
      key,
    ) async {
      var query = SupabaseConfig.client
          .from(key.kind.table)
          .select(key.kind.columns)
          .eq('slug', key.slug);
      // A category the panel removed (switched off) is gone from the site,
      // its old address included.
      if (key.kind.scope != null) {
        query = query.eq('scope', key.kind.scope!).eq('is_active', true);
      }
      final rows = List<Map<String, dynamic>>.from(await query.limit(1));
      if (rows.isEmpty) return null;
      final r = rows.first;
      return (
        id: r['id'] as String,
        name: r['title'] as String? ??
            localName((r['name'] as String?) ?? '', r['name_en'] as String?),
      );
    });

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Whether a path parameter is a row id rather than a slug.
bool isRowId(String value) => _uuid.hasMatch(value);

/// Looks [slug] up, then builds the page for the row it names.
class SlugPage extends ConsumerWidget {
  final SlugKind kind;
  final String slug;
  final Widget Function(SlugRow row) builder;

  const SlugPage({
    super.key,
    required this.kind,
    required this.slug,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(slugRowProvider((kind: kind, slug: slug)));
    return row.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const PageNotFound(),
      data: (r) => r == null ? const PageNotFound() : builder(r),
    );
  }
}

/// "Page not found", with the way home: for a slug no row has, and for any
/// address the site has no page for (the router's error page), which showed
/// go_router's own grey error text.
class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    // The desktop site's language is the navbar's; the phone layout's is
    // the app's locale.
    final hebrew = MediaQuery.sizeOf(context).width > 1100
        ? webIsHebrew.value
        : Localizations.localeOf(context).languageCode == 'he';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hebrew ? 'הדף לא נמצא' : 'Page not found',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                ),
                onPressed: () => context.go('/'),
                child: Text(hebrew ? 'לדף הבית' : 'Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
