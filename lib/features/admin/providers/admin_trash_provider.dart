import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// What the panel has taken away, gathered from the tables themselves.
///
/// Removing anything in the panel marks the row rather than deleting it — the
/// client asked for a trash, not permanent removal — so an archived article,
/// a closed business, a switched-off category are all still in their tables.
/// This lists them in one place with a way back.
///
/// The `trash` table the panel was first built around is not used: nothing
/// ever wrote to it, and copying rows out of their tables would break the
/// links other rows keep to them. Nothing here expires or is purged.
final adminTrashListProvider =
    StateNotifierProvider<AdminTrashNotifier, AsyncValue<List<TrashItem>>>((
      ref,
    ) {
      return AdminTrashNotifier();
    });

/// One table the panel removes rows from, and how.
class TrashSource {
  /// The table.
  final String table;

  /// What one row is called, in Hebrew.
  final String kind;

  /// The column that names a row.
  final String titleColumn;

  /// The `status` values that mean "removed"; null when the table marks a
  /// row with `is_active = false` instead.
  final List<String>? removedStatuses;

  /// The status a restored row is given when the audit log does not say what
  /// it was before. Chosen so that a restore never puts something on the
  /// site by surprise where the table has a way to hold it back: articles,
  /// events and businesses come back as drafts to publish from their section.
  final String? restoreStatus;

  /// The column that says when the row last changed, for ordering.
  final String dateColumn;

  const TrashSource(
    this.table,
    this.kind,
    this.titleColumn, {
    this.removedStatuses,
    this.restoreStatus,
    this.dateColumn = 'updated_at',
  });

  bool get usesStatus => removedStatuses != null;
}

/// Every table whose removal in the panel is a mark, not a delete. Tags,
/// agents' links and challenges truly delete, so they have nothing here.
const trashSources = <TrashSource>[
  TrashSource(
    'articles',
    'כתבה',
    'title',
    removedStatuses: ['archived', 'trash'],
    restoreStatus: 'draft',
  ),
  TrashSource(
    'businesses',
    'עסק',
    'name',
    removedStatuses: ['closed'],
    restoreStatus: 'draft',
  ),
  TrashSource(
    'events',
    'אירוע',
    'title',
    removedStatuses: ['cancelled'],
    restoreStatus: 'draft',
  ),
  TrashSource(
    'offers',
    'הטבה',
    'name',
    removedStatuses: ['expired'],
    restoreStatus: 'draft',
  ),
  TrashSource(
    'listings',
    'מודעת נדל״ן',
    'title',
    removedStatuses: ['removed'],
    // Back into the approval queue rather than straight onto the site.
    restoreStatus: 'pending',
  ),
  TrashSource(
    'campaigns',
    'קמפיין',
    'name',
    removedStatuses: ['ended'],
    restoreStatus: 'paused',
  ),
  TrashSource(
    'commercial_agreements',
    'הסכם מסחרי',
    'name',
    removedStatuses: ['cancelled'],
    restoreStatus: 'paused',
  ),
  TrashSource(
    'reviews',
    'ביקורת',
    'title',
    removedStatuses: ['hidden', 'rejected'],
    restoreStatus: 'pending',
  ),
  TrashSource(
    'comments',
    'תגובה',
    'body',
    removedStatuses: ['hidden', 'rejected'],
    restoreStatus: 'pending',
  ),
  TrashSource('home_blocks', 'בלוק בדף הבית', 'title'),
  TrashSource('categories', 'קטגוריה', 'name'),
  TrashSource('neighborhoods', 'שכונה', 'name'),
  TrashSource(
    'ad_placements',
    'מיקום פרסום',
    'label',
    dateColumn: 'created_at',
  ),
  TrashSource('real_estate_agents', 'סוכן נדל״ן', 'name'),
  TrashSource('parking_lots', 'חניון', 'name'),
];

/// Hebrew for the states a row can be in — the removed ones, what a restore
/// returns a row to, and the rest the audit log shows.
const trashStateLabels = <String, String>{
  'archived': 'בארכיון',
  'trash': 'בפח',
  'closed': 'סגור',
  'cancelled': 'בוטל',
  'expired': 'פג תוקף',
  'removed': 'הוסר',
  'ended': 'הסתיים',
  'hidden': 'מוסתר',
  'rejected': 'נדחה',
  'inactive': 'מושבת',
  'draft': 'טיוטה',
  'pending': 'ממתין לאישור',
  'paused': 'מושהה',
  'active': 'פעיל',
  'published': 'מפורסם',
  'approved': 'מאושר',
  'open': 'פתוח',
  'reviewed': 'בטיפול',
  'resolved': 'נפתר',
  'dismissed': 'נדחה',
  'scheduled': 'מתוזמן',
  'sending': 'בשליחה',
  'sent': 'נשלח',
  'failed': 'נכשל',
  'suspended': 'מושעה',
  'sold': 'נמכר',
  'rented': 'הושכר',
  'past': 'עבר',
  'redeemed_out': 'מומש במלואו',
};

/// One removed row.
class TrashItem {
  final TrashSource source;
  final String id;
  final String title;

  /// The status it is in, or `inactive`.
  final String state;
  final DateTime? changedAt;

  const TrashItem({
    required this.source,
    required this.id,
    required this.title,
    required this.state,
    required this.changedAt,
  });
}

class AdminTrashNotifier extends StateNotifier<AsyncValue<List<TrashItem>>> {
  AdminTrashNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  /// How many rows each table may contribute; the page is a list, not an
  /// archive browser.
  static const _perTable = 200;

  String? _table;

  /// Tables that could not be read on the last load, with why — shown on the
  /// screen rather than passed off as "nothing removed".
  Map<String, String> failures = const {};

  void setTableFilter(String? table) {
    _table = (table == null || table.isEmpty) ? null : table;
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final sources = _table == null
        ? trashSources
        : trashSources.where((s) => s.table == _table).toList();
    final failed = <String, String>{};
    final results = await Future.wait(
      sources.map((s) async {
        try {
          return await _read(s);
        } on PostgrestException catch (e) {
          // A table this build knows about but the database does not have
          // yet (its migration not applied) has nothing removed in it; any
          // other failure is shown.
          if (e.code != 'PGRST205' && e.code != '42P01') {
            failed[s.table] = e.message;
          }
          return const <TrashItem>[];
        } catch (e) {
          failed[s.table] = '$e';
          return const <TrashItem>[];
        }
      }),
    );
    if (!mounted) return;
    failures = failed;
    final items = [for (final r in results) ...r]
      ..sort((a, b) {
        final da = a.changedAt, db = b.changedAt;
        if (da == null || db == null) return da == null ? 1 : -1;
        return db.compareTo(da);
      });
    state = AsyncValue.data(items);
  }

  Future<List<TrashItem>> _read(TrashSource s) async {
    final stateColumn = s.usesStatus ? 'status' : 'is_active';
    var query = SupabaseConfig.client
        .from(s.table)
        .select('id, ${s.titleColumn}, $stateColumn, ${s.dateColumn}');
    query = s.usesStatus
        ? query.inFilter('status', s.removedStatuses!)
        : query.eq('is_active', false);
    final rows = await query
        .order(s.dateColumn, ascending: false)
        .limit(_perTable);
    return [
      for (final r in List<Map<String, dynamic>>.from(rows))
        TrashItem(
          source: s,
          id: r['id'].toString(),
          title: (r[s.titleColumn] as String? ?? '').trim(),
          state: s.usesStatus ? r['status'] as String : 'inactive',
          changedAt: DateTime.tryParse(r[s.dateColumn] as String? ?? ''),
        ),
    ];
  }

  /// What [item] will be once restored: its state before it was removed
  /// when the audit log recorded one, otherwise the table's default.
  Future<String> restoreTarget(TrashItem item) async {
    if (!item.source.usesStatus) return 'active';
    final rows = await SupabaseConfig.client
        .from('audit_logs')
        .select('before_data')
        .eq('entity_type', item.source.table)
        .eq('entity_id', item.id)
        .order('created_at', ascending: false)
        .limit(20);
    for (final r in List<Map<String, dynamic>>.from(rows)) {
      final before = r['before_data'];
      final was = before is Map ? before['status'] : null;
      if (was is String && !item.source.removedStatuses!.contains(was)) {
        return was;
      }
    }
    return item.source.restoreStatus!;
  }

  /// Puts [item] back and records it in the audit log. Returns the state it
  /// was restored to.
  Future<String> restore(TrashItem item) async {
    final target = await restoreTarget(item);
    final fields = item.source.usesStatus
        ? <String, dynamic>{'status': target}
        : <String, dynamic>{'is_active': true};
    await updateRow(item.source.table, item.id, fields);
    await recordAdminAction(
      action: 'restore',
      table: item.source.table,
      rowId: item.id,
      fields: fields,
      before: item.source.usesStatus
          ? {'status': item.state}
          : {'is_active': false},
      label: item.source.table == 'comments' || item.title.isEmpty
          ? null
          : item.title,
    );
    await load();
    return target;
  }
}
