import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// עמודי מידע (migration 00037) — About Us and the Accessibility Statement,
/// the pages the website's footer links to. The text is the client's to
/// write; the panel edits and publishes them.
final adminSitePagesProvider =
    StateNotifierProvider<
      AdminSitePagesNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => AdminSitePagesNotifier());

class AdminSitePagesNotifier extends AdminTableNotifier {
  AdminSitePagesNotifier()
    : super(
        table: 'site_pages',
        searchColumns: const ['slug', 'title_he', 'title_en'],
        orderBy: 'slug',
        ascending: true,
        hasStatus: false,
        // The slug is the page's address and the rest is stamped by the
        // database, so the form never writes them.
        readOnlyColumns: const {
          'id',
          'slug',
          'created_at',
          'updated_at',
          'updated_by',
        },
      );

  /// The pages are fixed — there is no adding or deleting one. Taking a page
  /// down is unpublishing it, which the same switch undoes.
  Future<void> setPublished(String id, bool published) =>
      update(id, {'is_published': published});
}
