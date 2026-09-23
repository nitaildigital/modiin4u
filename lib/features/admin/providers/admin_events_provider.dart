import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Events, on the live table.
///
/// All ten rows are ones we seeded: the client's site has no events section
/// at all, so this is where real ones will be entered first.
final adminEventListProvider =
    StateNotifierProvider<
      AdminEventListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminEventListNotifier();
    });

class AdminEventListNotifier extends AdminTableNotifier {
  AdminEventListNotifier()
    : super(
        table: 'events',
        searchColumns: const ['title', 'slug', 'venue_name'],
        orderBy: 'start_date',
        // Soonest first: what is coming is what needs attention.
        ascending: true,
        softDeleteStatus: 'cancelled',
      );

  Future<void> createEvent(Map<String, dynamic> e) => create(_withSlug(e));
  Future<void> updateEvent(String id, Map<String, dynamic> f) => update(id, f);
  Future<void> deleteEvent(String id) => remove(id);

  /// The column is NOT NULL and the form does not always offer it, so one is
  /// derived rather than letting the insert fail.
  Map<String, dynamic> _withSlug(Map<String, dynamic> e) {
    final slug = (e['slug'] as String?)?.trim();
    if (slug != null && slug.isNotEmpty) return e;

    final title = (e['title'] as String? ?? 'event').trim();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return {
      ...e,
      'slug': '${_slugify(title)}-$stamp',
    };
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

/// Businesses that can host an event, for the venue picker.
final eventVenuesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('businesses')
      .select('id, name, address, latitude, longitude')
      .eq('status', 'active')
      .order('name');
  return List<Map<String, dynamic>>.from(rows);
});
