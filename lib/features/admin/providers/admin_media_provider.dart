import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show CountOption, FileOptions;

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';
import 'media_usage.dart';

/// The media library, on the live table.
///
/// Each row is a file in the `media` bucket: the 513 business photographs
/// the WordPress import brought over (every one of them in a business
/// gallery through `entity_media`), the three sample neighbourhood photos,
/// and whatever is uploaded here.
///
/// This section read `filename` and `file_size`, which are not columns
/// (`file_name`, `size_bytes` are), so every name and size came out blank,
/// and its "upload" inserted a row of invented values — 800×600, 100 KB, a
/// person's name as the uploader — with no file behind it.
final adminMediaListProvider =
    StateNotifierProvider<
      AdminMediaListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminMediaListNotifier();
    });

/// The bucket folder the library's own uploads land in, beside the folders
/// the editors use (`businesses/gallery`, `articles/cover`, …).
const mediaLibraryFolder = 'library';

/// Figures for the whole table rather than the rows on screen.
class MediaTotals {
  final int files;
  final int images;
  final int bytes;
  const MediaTotals(this.files, this.images, this.bytes);
}

class AdminMediaListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  AdminMediaListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  /// A page of rows. `loadMore` widens the window by another, as the other
  /// sections do; the list is ordered and filtered by the database.
  static const _page = 200;
  int _window = _page;
  bool _loadingMore = false;

  /// Rows matching the search and type filter, which is not how many are
  /// loaded. The list said 500 when the table held 516, and the last 16
  /// could not be reached.
  int totalCount = 0;
  bool get hasMore => totalCount > (state.valueOrNull?.length ?? 0);

  /// Across the whole table, for the figures above the list.
  MediaTotals? totals;

  String? _search;
  String? _mime;

  Future<void> load() async {
    if (!_loadingMore) state = const AsyncValue.loading();
    try {
      // The galleries each file is in come along, so a photo imported
      // under a name like `00f2ff88a18e8e6e.jpeg` can be told by its
      // business.
      var query = SupabaseConfig.client
          .from('media')
          .select('*, entity_media(entity_type, entity_id)');
      final mime = _mime;
      if (mime != null && mime.isNotEmpty) query = query.eq('mime_type', mime);
      final search = _search;
      if (search != null && search.isNotEmpty) {
        // A comma separates the clauses in `or`.
        final q = search.replaceAll(',', ' ');
        query = query.or('file_name.ilike.%$q%,alt_text.ilike.%$q%');
      }
      final res = await query
          .order('created_at', ascending: false)
          .order('id')
          .limit(_window)
          .count(CountOption.exact);
      if (!mounted) return;
      final rows = List<Map<String, dynamic>>.from(res.data);
      await _nameGalleries(rows);
      if (!mounted) return;
      totalCount = res.count;
      state = AsyncValue.data(rows);
      _loadTotals();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Adds `gallery_names` to each row: the businesses and neighbourhoods
  /// whose galleries show it. `entity_media` points at either table by id
  /// alone, so the names are read in one query per table.
  Future<void> _nameGalleries(List<Map<String, dynamic>> rows) async {
    final ids = <String, Set<String>>{};
    for (final r in rows) {
      for (final l in List<Map<String, dynamic>>.from(
        r['entity_media'] as List? ?? const [],
      )) {
        ids
            .putIfAbsent(l['entity_type'] as String, () => {})
            .add(l['entity_id'] as String);
      }
    }
    final names = <String, String>{};
    for (final (type, table) in const [
      ('business', 'businesses'),
      ('neighborhood', 'neighborhoods'),
    ]) {
      final wanted = ids[type];
      if (wanted == null || wanted.isEmpty) continue;
      try {
        final found = await SupabaseConfig.client
            .from(table)
            .select('id, name')
            .inFilter('id', wanted.toList());
        for (final f in List<Map<String, dynamic>>.from(found)) {
          names[f['id'] as String] = f['name'] as String? ?? '';
        }
      } catch (_) {
        // Without the names the list still stands.
      }
    }
    for (final r in rows) {
      r['gallery_names'] = [
        for (final l in List<Map<String, dynamic>>.from(
          r['entity_media'] as List? ?? const [],
        ))
          names[l['entity_id']] ?? '',
      ].where((n) => n.isNotEmpty).toList();
    }
  }

  /// Counted from every row, a page at a time — PostgREST stops at 1000 and
  /// says nothing. Only the two small columns are read.
  Future<void> _loadTotals() async {
    try {
      var files = 0, images = 0, bytes = 0;
      const page = 1000;
      for (var from = 0; ; from += page) {
        final rows = List<Map<String, dynamic>>.from(
          await SupabaseConfig.client
              .from('media')
              .select('mime_type, size_bytes')
              .order('id')
              .range(from, from + page - 1),
        );
        for (final r in rows) {
          files++;
          if ((r['mime_type'] as String? ?? '').startsWith('image/')) images++;
          bytes += (r['size_bytes'] as num?)?.toInt() ?? 0;
        }
        if (rows.length < page) break;
      }
      totals = MediaTotals(files, images, bytes);
      // The figures hang off the notifier; hand the same rows back so the
      // screen rebuilds with them.
      if (mounted && state.hasValue) state = AsyncValue.data(state.value!);
    } catch (_) {
      // The figures are a convenience; the list is what matters.
    }
  }

  Future<void> loadMore() async {
    _window += _page;
    _loadingMore = true;
    try {
      await load();
    } finally {
      _loadingMore = false;
    }
  }

  void setSearch(String? search) {
    _search = search;
    _window = _page;
    load();
  }

  void setMimeFilter(String? mime) {
    _mime = mime;
    _window = _page;
    load();
  }

  /// Only the text the person can change here. The file's name, size and
  /// dimensions describe the file, and a rename would not move it.
  Future<void> updateAltText(String id, String? altText) async {
    final fields = {'alt_text': altText};
    await updateRow('media', id, fields);
    await recordAdminAction(
      action: 'update',
      table: 'media',
      rowId: id,
      fields: fields,
    );
    await load();
  }

  /// Uploads [bytes] to the bucket and records it, with the facts read off
  /// the file itself. Returns the new row.
  Future<Map<String, dynamic>> upload({
    required Uint8List bytes,
    required String originalName,
    String? altText,
  }) async {
    final client = SupabaseConfig.client;
    final ext = _extensionOf(originalName);
    final mime = _mimeOf(ext);

    // Time plus a random tail, as the gallery editor names its files: the
    // bucket refuses to overwrite, and a name typed by a person may clash.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final path = '$mediaLibraryFolder/${stamp}_$tail$ext';

    await client.storage
        .from('media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    final url = client.storage.from('media').getPublicUrl(path);
    final size = await _dimensionsOf(bytes);

    try {
      final row = await client
          .from('media')
          .insert({
            // The name it had on the person's computer, which is what they
            // will search for; the stored object has its own.
            'file_name': originalName.trim().isEmpty
                ? path.split('/').last
                : originalName.trim(),
            'file_path': path,
            'url': url,
            'mime_type': mime,
            'size_bytes': bytes.lengthInBytes,
            'width': size?.$1,
            'height': size?.$2,
            'alt_text': (altText ?? '').trim().isEmpty ? null : altText!.trim(),
            'folder': mediaLibraryFolder,
            'uploaded_by': client.auth.currentUser?.id,
          })
          .select()
          .single();
      await recordAdminAction(
        action: 'create',
        table: 'media',
        rowId: row['id'] as String?,
        fields: row,
        label: row['file_name'] as String?,
      );
      await load();
      return row;
    } catch (_) {
      // A file with no record is clutter nobody can see to clear.
      try {
        await client.storage.from('media').remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  /// Where the file is shown. Every row the library holds today is in a
  /// business gallery, and several addresses are copied into other rows.
  Future<List<MediaUse>> usageOf(Map<String, dynamic> media) {
    return mediaUsage(
      media['file_path'] as String? ?? '',
      mediaId: media['id'] as String?,
    );
  }

  /// Removes the file and its record — only when nothing uses it.
  ///
  /// The table has no column to hide a row, and removing a row that a
  /// gallery points at takes the photo off that business's public page
  /// (`entity_media` cascades). So a file in use is refused here, checked
  /// again at the moment of removal rather than trusted from the dialog; it
  /// comes out of a gallery through that business's editor. A file nothing
  /// uses shows nowhere, and removing it frees the space.
  Future<void> deleteUnused(Map<String, dynamic> media) async {
    final id = media['id'] as String;
    final uses = await usageOf(media);
    if (uses.isNotEmpty) throw MediaInUse(uses.length);
    final client = SupabaseConfig.client;
    // The file goes only once the record has: a delete the database refuses
    // removes no row and says nothing, and the file must not go without it.
    final deleted = await client
        .from('media')
        .delete()
        .eq('id', id)
        .select('id');
    if (deleted.isEmpty) throw const AdminWriteRefused();
    await recordAdminAction(
      action: 'delete',
      table: 'media',
      rowId: id,
      label: media['file_name'] as String?,
    );
    final path = media['file_path'] as String?;
    if (path != null && path.isNotEmpty) {
      try {
        await client.storage.from('media').remove([path]);
      } catch (_) {
        // The record is gone, which is what the list shows; a file left in
        // the bucket shows nowhere.
      }
    }
    await load();
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(ext)
        ? ext
        : '.jpg';
  }

  static String _mimeOf(String ext) => switch (ext) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    _ => 'image/jpeg',
  };

  static Future<(int, int)?> _dimensionsOf(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }
}

/// A removal refused because something still shows the file.
class MediaInUse implements Exception {
  final int uses;
  const MediaInUse(this.uses);

  @override
  String toString() => 'הקובץ בשימוש ($uses) ולא הוסר';
}
