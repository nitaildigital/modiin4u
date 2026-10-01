import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/media_usage.dart';

/// One photo in a gallery: either a row already stored, or a file picked in
/// this session that has not been uploaded yet.
class AdminGalleryPhoto {
  /// The `entity_media` row, once there is one.
  String? entityMediaId;

  /// The `media` row it points at.
  String? mediaId;

  /// The public address, once uploaded.
  String? url;

  /// Where the file sits in the `media` bucket.
  String? filePath;

  /// The order as stored, so a save only rewrites rows that moved.
  int? storedOrder;

  /// The picked file, until it is uploaded.
  Uint8List? bytes;
  String? fileName;

  AdminGalleryPhoto.stored({
    required this.entityMediaId,
    required this.mediaId,
    required this.url,
    required this.filePath,
    required this.storedOrder,
  });

  AdminGalleryPhoto.picked({required this.bytes, required this.fileName});

  bool get isNew => entityMediaId == null;
}

/// A photo gallery for one row — a business, a neighbourhood — held as the
/// `entity_media` rows that point at it with `role = 'gallery'`, each naming
/// a `media` row whose file is in the `media` bucket.
///
/// That is the shape the site reads (`businessGalleryProvider`,
/// `neighborhoodPhotosProvider`) and the one the WordPress import wrote its
/// 513 business photographs into, so a photo added here appears on the page
/// with nothing else to change.
///
/// Nothing is written while the editor is open. Picking, reordering and
/// removing change this list; [save] writes the difference when the form
/// around it is saved. That way the dialog's "cancel" means what it says, and
/// a new business can be given photos before it has an id — the form saves
/// the row first and then hands the id to [save].
class AdminGalleryController extends ChangeNotifier {
  /// `entity_media.entity_type` — 'business', 'neighborhood'.
  final String entityType;

  /// `entity_media.role`. The site reads 'gallery'.
  final String role;

  /// The bucket folder new files go into, e.g. `businesses/gallery` — the
  /// folder the import used, so every business photo is in one place.
  final String folder;

  AdminGalleryController({
    required this.entityType,
    required this.folder,
    this.role = 'gallery',
  });

  final List<AdminGalleryPhoto> photos = [];
  final List<AdminGalleryPhoto> _removed = [];

  bool loading = false;
  String? loadError;

  /// Set by anything the person does. An untouched gallery is never written,
  /// so opening and saving a business cannot renumber its photographs.
  bool _dirty = false;
  bool get isDirty => _dirty;

  /// Reads the gallery of an existing row, in the order the site shows it.
  Future<void> load(String entityId) async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final rows = await SupabaseConfig.client
          .from('entity_media')
          .select('id, sort_order, media_id, media(url, file_path)')
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .eq('role', role)
          .order('sort_order', ascending: true);
      photos
        ..clear()
        ..addAll([
          for (final r in List<Map<String, dynamic>>.from(rows))
            AdminGalleryPhoto.stored(
              entityMediaId: r['id'] as String,
              mediaId: r['media_id'] as String?,
              url: (r['media'] as Map?)?['url'] as String?,
              filePath: (r['media'] as Map?)?['file_path'] as String?,
              storedOrder: (r['sort_order'] as num?)?.toInt(),
            ),
        ]);
      _removed.clear();
      _dirty = false;
    } catch (e) {
      loadError = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void addPicked(List<AdminGalleryPhoto> picked) {
    if (picked.isEmpty) return;
    photos.addAll(picked);
    _dirty = true;
    notifyListeners();
  }

  void move(int from, int to) {
    if (to < 0 || to >= photos.length || from == to) return;
    final p = photos.removeAt(from);
    photos.insert(to, p);
    _dirty = true;
    notifyListeners();
  }

  void removeAt(int index) {
    final p = photos.removeAt(index);
    // A picked file that was never uploaded leaves nothing behind.
    if (!p.isNew) _removed.add(p);
    _dirty = true;
    notifyListeners();
  }

  /// Writes what changed for the row [entityId]: removals first, then new
  /// uploads, then the order of whatever moved.
  ///
  /// Each photo is marked stored as soon as it is, so a save that fails part
  /// way can be retried without uploading the same file twice.
  Future<void> save(String entityId) async {
    if (!_dirty) return;
    final client = SupabaseConfig.client;

    // ── Removed ──
    while (_removed.isNotEmpty) {
      final p = _removed.first;
      await client.from('entity_media').delete().eq('id', p.entityMediaId!);
      await _dropMediaIfUnused(p);
      _removed.removeAt(0);
    }

    // ── New ──
    for (var i = 0; i < photos.length; i++) {
      final p = photos[i];
      if (!p.isNew) continue;
      await _upload(p, entityId, i);
      notifyListeners();
    }

    // ── Moved ──
    for (var i = 0; i < photos.length; i++) {
      final p = photos[i];
      if (p.storedOrder == i) continue;
      await client
          .from('entity_media')
          .update({'sort_order': i})
          .eq('id', p.entityMediaId!);
      p.storedOrder = i;
    }

    _dirty = false;
    notifyListeners();
  }

  /// The `media` row and its file go too, unless something else still points
  /// at them — the table is shared, and a photo can hang off more than one
  /// row.
  ///
  /// Other galleries were the only check, so a file that was also a
  /// business's logo or cover, an article's picture or a banner was deleted
  /// with the gallery photo and those showed a broken image. The database's
  /// `media_usage` (00034), which the media library already asks before a
  /// delete, searches every table for the address; anything it finds keeps
  /// the file and its library row. When it cannot be asked, the file stays —
  /// a spare file costs nothing, a missing one breaks a page.
  Future<void> _dropMediaIfUnused(AdminGalleryPhoto p) async {
    final mediaId = p.mediaId;
    if (mediaId == null) return;
    final client = SupabaseConfig.client;

    final others = await client
        .from('entity_media')
        .select('id')
        .eq('media_id', mediaId)
        .limit(1);
    if (List<dynamic>.from(others).isNotEmpty) return;

    final path = p.filePath;
    if (path != null && path.isNotEmpty) {
      try {
        if ((await mediaUsage(path, mediaId: mediaId)).isNotEmpty) return;
      } catch (_) {
        return;
      }
    }
    if (path != null && path.isNotEmpty) {
      try {
        await client.storage.from('media').remove([path]);
      } catch (_) {
        // A file already gone should not keep the record alive.
      }
    }
    await client.from('media').delete().eq('id', mediaId);
  }

  Future<void> _upload(AdminGalleryPhoto p, String entityId, int order) async {
    final client = SupabaseConfig.client;
    final bytes = p.bytes!;
    final ext = _extensionOf(p.fileName ?? '');
    final mime = _mimeOf(ext);

    // Time plus a random tail: two photos picked together land in the same
    // millisecond, and the bucket refuses to overwrite.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final name = '${stamp}_$tail$ext';
    final path = '$folder/$name';

    await client.storage
        .from('media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    final url = client.storage.from('media').getPublicUrl(path);
    final size = await _dimensionsOf(bytes);

    String? mediaId;
    try {
      final media = await client
          .from('media')
          .insert({
            'file_name': name,
            'file_path': path,
            'url': url,
            'mime_type': mime,
            'size_bytes': bytes.lengthInBytes,
            'width': size?.$1,
            'height': size?.$2,
            'folder': folder,
            'uploaded_by': client.auth.currentUser?.id,
          })
          .select('id')
          .single();
      mediaId = media['id'] as String;

      final link = await client
          .from('entity_media')
          .insert({
            'media_id': mediaId,
            'entity_type': entityType,
            'entity_id': entityId,
            'role': role,
            'sort_order': order,
          })
          .select('id')
          .single();

      p
        ..entityMediaId = link['id'] as String
        ..mediaId = mediaId
        ..url = url
        ..filePath = path
        ..storedOrder = order
        ..bytes = null;
    } catch (_) {
      // Leave nothing half-made behind: a file with no record, or a record
      // nothing shows, is clutter nobody can see to clear.
      try {
        if (mediaId != null) {
          await client.from('media').delete().eq('id', mediaId);
        }
        await client.storage.from('media').remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

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
}

/// The gallery as the admin sees it: thumbnails in the order the site shows
/// them, each with a move and a remove, and a button that adds several at
/// once.
class AdminGalleryEditor extends StatefulWidget {
  final AdminGalleryController controller;
  final String title;

  const AdminGalleryEditor({
    super.key,
    required this.controller,
    this.title = 'גלריית תמונות',
  });

  @override
  State<AdminGalleryEditor> createState() => _AdminGalleryEditorState();
}

class _AdminGalleryEditorState extends State<AdminGalleryEditor> {
  bool _picking = false;
  String? _error;

  AdminGalleryController get _c => widget.controller;

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _picking = true;
    });
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2000,
        imageQuality: 85,
      );
      final picked = <AdminGalleryPhoto>[];
      var tooBig = 0;
      for (final f in files) {
        final bytes = await f.readAsBytes();
        // The bucket refuses anything over 10MB, and says so as a failure
        // rather than as "too big".
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          tooBig++;
          continue;
        }
        picked.add(AdminGalleryPhoto.picked(bytes: bytes, fileName: f.name));
      }
      _c.addPicked(picked);
      if (tooBig > 0 && mounted) {
        setState(() => _error = '$tooBig קבצים גדולים מ-10MB ולא נוספו');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'לא ניתן לפתוח את בוחר הקבצים');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_c.loading)
                  Text(
                    '${_c.photos.length} תמונות',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.adminTextLight,
                    ),
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _picking || _c.loading ? null : _pick,
                  icon: _picking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                  label: Text(
                    'הוספת תמונות',
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'התמונות נשמרות יחד עם הטופס. הראשונה מוצגת ראשונה באתר; '
              'החצים משנים את הסדר.',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                color: AppColors.adminTextLight,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_c.loading)
              const LinearProgressIndicator()
            else if (_c.loadError != null)
              Text(
                'לא ניתן לטעון את הגלריה: ${_c.loadError}',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.error,
                ),
              )
            else if (_c.photos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.adminContentBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.adminCardBorder),
                ),
                child: Text(
                  'אין תמונות בגלריה',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _c.photos.length; i++)
                    _Thumb(
                      key: ObjectKey(_c.photos[i]),
                      photo: _c.photos[i],
                      index: i,
                      isFirst: i == 0,
                      isLast: i == _c.photos.length - 1,
                      onEarlier: () => _c.move(i, i - 1),
                      onLater: () => _c.move(i, i + 1),
                      onRemove: () => _c.removeAt(i),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  final AdminGalleryPhoto photo;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEarlier;
  final VoidCallback onLater;
  final VoidCallback onRemove;

  const _Thumb({
    super.key,
    required this.photo,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onEarlier,
    required this.onLater,
    required this.onRemove,
  });

  static const _w = 132.0;
  static const _h = 96.0;

  @override
  Widget build(BuildContext context) {
    final image = photo.bytes != null
        ? Image.memory(photo.bytes!, width: _w, height: _h, fit: BoxFit.cover)
        : NetworkPhoto(
            url: photo.url,
            width: _w,
            height: _h,
            icon: Icons.image_outlined,
            iconSize: 22,
          );

    return Container(
      width: _w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: photo.isNew ? AppColors.turquoise : AppColors.adminCardBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              image,
              PositionedDirectional(
                top: 4,
                start: 4,
                child: _Badge(
                  photo.isNew ? '${index + 1} · חדשה' : '${index + 1}',
                  photo.isNew ? AppColors.turquoise : AppColors.navy,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                // The chevrons mirror in right-to-left text, so "left" here
                // is drawn pointing right: towards the start of the row,
                // which is where "earlier" moves a photo.
                _IconBtn(
                  icon: Icons.chevron_left,
                  tooltip: 'הקדמה',
                  onTap: isFirst ? null : onEarlier,
                ),
                _IconBtn(
                  icon: Icons.chevron_right,
                  tooltip: 'הזזה אחורה',
                  onTap: isLast ? null : onLater,
                ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.delete_outline,
                  tooltip: 'הסרה מהגלריה',
                  color: AppColors.error,
                  onTap: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? AppColors.border
                : (color ?? AppColors.adminTextMedium),
          ),
        ),
      ),
    );
  }
}
