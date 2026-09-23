import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// The media library, on the live table.
///
/// Rows are records of files in the `media` storage bucket. The table is
/// empty because every picture the app shows still points at the WordPress
/// site — moving them here is what makes the photography ours.
final adminMediaListProvider =
    StateNotifierProvider<
      AdminMediaListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminMediaListNotifier();
    });

class AdminMediaListNotifier extends AdminTableNotifier {
  AdminMediaListNotifier()
    : super(
        table: 'media',
        searchColumns: const ['file_name', 'alt_text'],
        orderBy: 'created_at',
        hasStatus: false,
      );

  String? _mime;

  void setMimeFilter(String? mime) {
    _mime = mime;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final mime = _mime;
    if (mime == null || mime.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows
            .where((r) => (r['mime_type'] as String? ?? '').startsWith(mime))
            .toList(),
      );
    });
  }

  Future<void> createMedia(Map<String, dynamic> m) => create(m);
  Future<void> updateMedia(String id, Map<String, dynamic> f) => update(id, f);

  /// Removes the file as well as the record, so the bucket does not fill with
  /// things nothing points at.
  Future<void> deleteMedia(String id) async {
    final client = SupabaseConfig.client;
    final row = await client
        .from('media')
        .select('file_path')
        .eq('id', id)
        .maybeSingle();

    final path = row?['file_path'] as String?;
    if (path != null && path.isNotEmpty) {
      try {
        await client.storage.from('media').remove([path]);
      } catch (_) {
        // A file already gone should not stop the record going too.
      }
    }
    await client.from('media').delete().eq('id', id);
    await load();
  }
}
