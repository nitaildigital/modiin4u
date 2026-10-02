import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';
import '../admin_language.dart';

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
Map<String, String> get homeBlockTypes => <String, String>{
  'alert': tr('הודעה באתר (מתחת לתמונה הראשית)', 'Site notice (below the main image)'),
  'hero': tr('תמונה ראשית', 'Main image'),
  'news_grid': tr('חדשות', 'News'),
  'event_carousel': tr('אירועים', 'Events'),
  'business_carousel': tr('עסקים', 'Businesses'),
  'restaurant_carousel': tr('מסעדות', 'Restaurants'),
  'banner': tr('באנר', 'Banner'),
  'offers': tr('הטבות', 'Benefits'),
  'game': tr('משחק', 'Game'),
  'ai_search': tr('חיפוש AI', 'AI search'),
  'map_preview': tr('מפה', 'Map'),
  'real_estate': tr('נדל״ן', 'Real estate'),
  'steps_challenge': tr('אתגר צעדים', 'Step challenge'),
  'custom_promo': tr('קידום מותאם', 'Custom promotion'),
  'weather': tr('מזג אוויר', 'Weather'),
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
    final fields = _columns(b);
    final row = await SupabaseConfig.client
        .from('home_blocks')
        .insert(fields)
        .select('id')
        .maybeSingle();
    await recordAdminAction(
      action: 'create',
      table: 'home_blocks',
      rowId: row?['id']?.toString(),
      fields: fields,
      label: _label(fields),
    );
    await load();
  }

  /// See [createBlock]: the same, for an existing row.
  Future<void> updateBlock(String id, Map<String, dynamic> f) async {
    final fields = _columns(f);
    final before = state.valueOrNull?.where((b) => b['id'] == id).firstOrNull;
    await updateRow('home_blocks', id, fields);
    await recordAdminAction(
      action: auditActionFor(fields),
      table: 'home_blocks',
      rowId: id,
      fields: fields,
      before: before,
      label: _label(fields) ?? _label(before),
    );
    await load();
  }

  /// A block's name for the audit log: its title, or its kind when it has
  /// none (the hero and banner rows are untitled).
  static String? _label(Map<String, dynamic>? b) {
    if (b == null) return null;
    final title = (b['title'] as String? ?? '').trim();
    if (title.isNotEmpty) return title;
    return homeBlockTypes[b['block_type']];
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
      // One entry for the block that was moved; the others only shifted.
      await recordAdminAction(
        action: 'update',
        table: 'home_blocks',
        rowId: id,
        fields: const {'sort_order': null},
        label: _label(moved),
      );
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
    final fields = {'published': true, 'published_at': now};
    final published = await SupabaseConfig.client
        .from('home_blocks')
        .update(fields)
        .eq('is_active', true)
        .eq('published', false)
        .select('id, title, block_type');
    for (final b in List<Map<String, dynamic>>.from(published)) {
      await recordAdminAction(
        action: 'publish',
        table: 'home_blocks',
        rowId: b['id'] as String?,
        fields: fields,
        before: const {'published': false},
        label: _label(b),
      );
    }
    await load();
  }
}
