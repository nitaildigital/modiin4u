import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// The rows on the home screen, in the order they appear.
///
/// Of these, the website reads one kind today: the `alert` — the notice bar
/// under the home page's hero (`homeNoticeProvider` in
/// `home_web_providers.dart`). The other kinds are arranged and stored here,
/// but no screen draws from them yet; their rows are fixed in the screens.
final adminHomeBuilderProvider =
    StateNotifierProvider<
      AdminHomeBuilderNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminHomeBuilderNotifier();
    });

/// The kinds of block the `block_type` enum allows (migration 00001), with
/// the name the panel shows. The form used to offer eight invented ones —
/// `hero_banner`, `deals`, `stats_bar` … — that the database refused, and
/// left out `alert`, the one the website reads.
const homeBlockTypes = <String, String>{
  'alert': 'הודעה באתר (מתחת לתמונה הראשית)',
  'hero': 'תמונה ראשית',
  'news_grid': 'חדשות',
  'event_carousel': 'אירועים',
  'business_carousel': 'עסקים',
  'restaurant_carousel': 'מסעדות',
  'banner': 'באנר',
  'offers': 'הטבות',
  'game': 'משחק',
  'ai_search': 'חיפוש AI',
  'map_preview': 'מפה',
  'real_estate': 'נדל״ן',
  'steps_challenge': 'אתגר צעדים',
  'custom_promo': 'קידום מותאם',
  'weather': 'מזג אוויר',
};

class AdminHomeBuilderNotifier extends AdminTableNotifier {
  AdminHomeBuilderNotifier()
    : super(
        table: 'home_blocks',
        searchColumns: const ['title'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  /// Writes [b] as given, `config` included.
  ///
  /// The shared [create] drops every map from the row it is handed — that is
  /// how joined rows are kept out of a write — and `config` is a map, so the
  /// notice's text and link never reached the table. This writes the block
  /// directly instead.
  Future<void> createBlock(Map<String, dynamic> b) async {
    await SupabaseConfig.client.from('home_blocks').insert(_columns(b));
    await load();
  }

  /// See [createBlock]: the same, for an existing row.
  Future<void> updateBlock(String id, Map<String, dynamic> f) async {
    await SupabaseConfig.client
        .from('home_blocks')
        .update(_columns(f))
        .eq('id', id);
    await load();
  }

  /// Takes the block off the home page and keeps it, to switch back on.
  ///
  /// This is what removing a block means: the client asked for nothing to be
  /// deleted outright, and a switched-off block is one flick from coming back.
  Future<void> deactivateBlock(String id) => setActive(id, false);

  /// The fields a form may write: the table's own columns, which keeps out
  /// the keys the database owns.
  static Map<String, dynamic> _columns(Map<String, dynamic> row) => {
    for (final e in row.entries)
      if (const {
        'block_type',
        'title',
        'config',
        'sort_order',
        'is_active',
        'audience',
        'start_at',
        'end_at',
        'published',
        'published_at',
        'published_by',
      }.contains(e.key))
        e.key: e.value,
  };

  /// The `admin_users` row for whoever is signed in — what `published_by`
  /// points at. Null when it cannot be found; the column is optional.
  Future<String?> currentAdminId() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await SupabaseConfig.client
          .from('admin_users')
          .select('id')
          .eq('profile_id', uid)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (b) => b['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }

  /// Moves one block to position [newIndex] in the list and renumbers the
  /// rest, because the order is a column rather than the row's place in the
  /// list.
  Future<void> reorder(String id, int newIndex) async {
    final rows = [...(state.valueOrNull ?? const <Map<String, dynamic>>[])];
    final from = rows.indexWhere((b) => b['id'] == id);
    if (from == -1) return;

    final moved = rows.removeAt(from);
    rows.insert(newIndex.clamp(0, rows.length), moved);

    final client = SupabaseConfig.client;
    try {
      for (var i = 0; i < rows.length; i++) {
        if (rows[i]['sort_order'] == i) continue;
        await client
            .from('home_blocks')
            .update({'sort_order': i})
            .eq('id', rows[i]['id'] as String);
      }
    } finally {
      await load();
    }
  }

  /// Publishes every active block at once.
  ///
  /// Blocks are edited as drafts and only reach the site once published, so
  /// the home page never shows a half-finished arrangement. Each block can
  /// also be published on its own from its editor.
  Future<void> publishAll() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await SupabaseConfig.client
        .from('home_blocks')
        .update({'published': true, 'published_at': now})
        .eq('is_active', true)
        .eq('published', false);
    await load();
  }
}
