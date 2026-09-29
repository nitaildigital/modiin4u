import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Events, on the live table.
///
/// The editor used to read and write `date`, `time`, `location`,
/// `description`, `organizer`, `category` and `max_capacity` — none of them
/// columns — so every save came back 400, and the list stopped at the first
/// row with a price because it read the numeric `price` as a string. This
/// writes the table's own columns, and files the event under its categories
/// in `entity_categories`, which is where the website reads them.
final adminEventListProvider =
    StateNotifierProvider<
      AdminEventListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminEventListNotifier(ref);
    });

class AdminEventListNotifier extends AdminTableNotifier {
  final Ref _ref;

  AdminEventListNotifier(this._ref)
    : super(
        table: 'events',
        searchColumns: const ['title', 'slug', 'venue_name'],
        orderBy: 'start_date',
        // Soonest first: what is coming is what needs attention.
        ascending: true,
        softDeleteStatus: 'cancelled',
        // The counters are kept by triggers and by the site itself; a form
        // that carried them back would overwrite a newer count with the one it
        // opened with.
        readOnlyColumns: const {
          'id',
          'created_at',
          'updated_at',
          'view_count',
          'rsvp_count',
          'calendar_adds',
          'share_count',
        },
      );

  /// Creates or updates the event and its categories, and returns its id.
  ///
  /// [categoryIds] is in the editor's order; the first is marked primary,
  /// which is the one the website's card pill shows. Null leaves the links as
  /// they are — an edit that did not touch the categories should not rewrite
  /// them.
  ///
  /// [onCreated] hears the new id as soon as the row exists, before the
  /// categories are written, so a failure there can be retried as an update
  /// rather than inserting the event twice.
  Future<String> saveEvent({
    String? id,
    required Map<String, dynamic> fields,
    List<String>? categoryIds,
    void Function(String id)? onCreated,
  }) async {
    final client = SupabaseConfig.client;
    final row = {
      for (final e in fields.entries)
        if (!readOnlyColumns.contains(e.key)) e.key: e.value,
    };

    String eventId;
    if (id == null) {
      final created = await client
          .from('events')
          .insert(_withSlug(row))
          .select('id')
          .single();
      eventId = created['id'] as String;
      onCreated?.call(eventId);
    } else {
      await client.from('events').update(row).eq('id', id);
      eventId = id;
    }

    if (categoryIds != null) await setCategories(eventId, categoryIds);
    await load();
    _ref.invalidate(adminEventCategoryLinksProvider);
    return eventId;
  }

  /// Replaces the categories an event is filed under.
  Future<void> setCategories(String eventId, List<String> categoryIds) async {
    final client = SupabaseConfig.client;
    await client
        .from('entity_categories')
        .delete()
        .eq('entity_type', 'event')
        .eq('entity_id', eventId);

    if (categoryIds.isEmpty) return;
    await client.from('entity_categories').insert([
      for (var i = 0; i < categoryIds.length; i++)
        {
          'entity_type': 'event',
          'entity_id': eventId,
          'category_id': categoryIds[i],
          'is_primary': i == 0,
        },
    ]);
  }

  /// Publishes, stamping `published_at` the first time only.
  ///
  /// The website's "Newest" sort reads it. Resetting it on every publish
  /// would move an old event to the top each time it was touched — which is
  /// what happened to articles.
  Future<void> publish(String id, {Object? publishedAt}) async {
    await SupabaseConfig.client
        .from('events')
        .update({
          'status': 'published',
          if (publishedAt == null)
            'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    await load();
  }

  /// Marks the event cancelled rather than removing it (`softDeleteStatus`):
  /// it leaves the site and comes back by changing its status.
  Future<void> deleteEvent(String id) => remove(id);

  /// The column is NOT NULL and the form does not always offer it, so one is
  /// derived rather than letting the insert fail.
  Map<String, dynamic> _withSlug(Map<String, dynamic> e) {
    final slug = (e['slug'] as String?)?.trim();
    if (slug != null && slug.isNotEmpty) return e;

    final title = (e['title'] as String? ?? 'event').trim();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return {...e, 'slug': '${_slugify(title)}-$stamp'};
  }

  /// Hebrew titles leave nothing behind when only latin letters are kept, so
  /// anything that is not a separator is allowed through.
  static String _slugify(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[\s/\\]+'), '-')
        .replaceAll(RegExp(r'[^\w֐-׿-]'), '');
    return cleaned.isEmpty ? 'event' : cleaned;
  }
}

/// One event category, for the editor's chips and the list's column.
class AdminEventCategory {
  final String id;
  final String name;
  final bool isActive;
  const AdminEventCategory(this.id, this.name, this.isActive);
}

/// Every category with `scope = 'event'`, in the editor's order.
///
/// Inactive ones are included so an event already filed under one keeps it
/// on save instead of losing it silently; the editor marks them.
final adminEventCategoriesProvider =
    FutureProvider.autoDispose<List<AdminEventCategory>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('categories')
          .select('id, name, is_active, sort_order')
          .eq('scope', 'event')
          .order('sort_order', ascending: true);
      return [
        for (final r in List<Map<String, dynamic>>.from(rows))
          AdminEventCategory(
            r['id'] as String,
            (r['name'] as String?) ?? '',
            r['is_active'] as bool? ?? true,
          ),
      ];
    });

/// Each event's category ids, keyed by event id, the primary one first.
final adminEventCategoryLinksProvider =
    FutureProvider.autoDispose<Map<String, List<String>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('entity_categories')
          .select('entity_id, category_id, is_primary')
          .eq('entity_type', 'event');
      final links = List<Map<String, dynamic>>.from(rows)
        ..sort((a, b) {
          final pa = a['is_primary'] == true ? 0 : 1;
          final pb = b['is_primary'] == true ? 0 : 1;
          return pa.compareTo(pb);
        });
      final out = <String, List<String>>{};
      for (final l in links) {
        out
            .putIfAbsent(l['entity_id'] as String, () => [])
            .add(l['category_id'] as String);
      }
      return out;
    });
