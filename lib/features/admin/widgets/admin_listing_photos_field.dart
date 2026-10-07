import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../admin_language.dart';

/// A listing's photos, in the order the listing page shows them.
///
/// A listing keeps its photos in two columns: `cover_url`, which every card
/// and the top of the listing page show, and `gallery`, the rest. The editor
/// had neither, so a listing entered in the panel had no picture at all. Here
/// they are one row of photos, and the first is the cover — which is how the
/// website lays them out (the cover, then the gallery) and how the app's own
/// "add apartment" form writes them.
///
/// Uploads go to `media/listings/admin/`, a folder only an administrator can
/// write. Every file uploaded here is reported through [onUploaded], so the
/// editor can remove the ones it does not end up saving.
class AdminListingPhotosField extends StatefulWidget {
  /// The photos as the editor holds them; the first is the cover.
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<String> onUploaded;

  const AdminListingPhotosField({
    super.key,
    required this.photos,
    required this.onChanged,
    required this.onUploaded,
  });

  /// Where in the `media` bucket the panel's listing photos land.
  static const folder = 'listings/admin';

  /// The storage path of a photo this panel uploaded, or null for anything
  /// else — a resident's upload, a sample photo, an address on another site.
  /// Only these are ever deleted from storage by the editor.
  static String? ownedPath(String url) {
    const marker = '/storage/v1/object/public/media/';
    final i = url.indexOf(marker);
    if (i == -1) return null;
    final path = Uri.decodeFull(
      url.substring(i + marker.length).split('?').first,
    );
    return path.startsWith('$folder/') ? path : null;
  }

  /// Removes photos this panel uploaded but nothing kept. Failures are left
  /// alone: an orphaned file costs a little storage, and an error here must
  /// not undo a save that already happened.
  static Future<void> discard(Iterable<String> urls) async {
    final paths = [for (final u in urls) ?ownedPath(u)];
    if (paths.isEmpty) return;
    try {
      await SupabaseConfig.client.storage.from('media').remove(paths);
    } catch (_) {}
  }

  @override
  State<AdminListingPhotosField> createState() =>
      _AdminListingPhotosFieldState();
}

class _AdminListingPhotosFieldState extends State<AdminListingPhotosField> {
  bool _busy = false;
  String? _error;
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  List<String> get _photos => widget.photos;

  void _set(List<String> photos) => widget.onChanged(List.unmodifiable(photos));

  void _move(int from, int to) {
    if (to < 0 || to >= _photos.length) return;
    final next = [..._photos];
    final item = next.removeAt(from);
    next.insert(to, item);
    _set(next);
  }

  void _remove(int i) => _set([..._photos]..removeAt(i));

  void _addUrl() {
    final url = _url.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      setState(() => _error = tr('כתובת לא תקינה', 'Invalid address'));
      return;
    }
    if (_photos.contains(url)) {
      setState(() => _error = tr('התמונה כבר ברשימה', 'The image is already in the list'));
      return;
    }
    setState(() => _error = null);
    _url.clear();
    _set([..._photos, url]);
  }

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);

    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        maxWidth: 2000,
        imageQuality: 85,
      );
    } catch (_) {
      setState(() => _error = tr('לא ניתן לפתוח את בוחר הקבצים', 'Could not open the file picker'));
      return;
    }
    if (picked.isEmpty) return;

    setState(() => _busy = true);
    final added = <String>[];
    var failed = 0;
    var tooBig = 0;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final (i, file) in picked.indexed) {
      try {
        final bytes = await file.readAsBytes();
        // The bucket rejects anything over 10MB, and a rejected upload reads
        // as a failure rather than as "too big", so it is counted apart.
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          tooBig++;
          continue;
        }
        final ext = _extensionOf(file.name);
        final path = '${AdminListingPhotosField.folder}/${stamp}_$i$ext';
        await SupabaseConfig.client.storage
            .from('media')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: _mimeOf(ext),
                upsert: false,
              ),
            );
        final url = SupabaseConfig.client.storage
            .from('media')
            .getPublicUrl(path);
        widget.onUploaded(url);
        added.add(url);
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = [
        if (tooBig > 0) tr('$tooBig קבצים גדולים מ-10MB ולא הועלו', '$tooBig files are larger than 10MB and were not uploaded'),
        if (failed > 0) tr('$failed העלאות נכשלו. נסו שוב.', '$failed uploads failed. Please try again.'),
      ].join(' · ');
      if (_error!.isEmpty) _error = null;
    });
    if (added.isNotEmpty) _set([..._photos, ...added]);
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

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontFamily: AppFonts.rubik, fontSize: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('תמונות (${_photos.length})', 'Photos (${_photos.length})'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('הראשונה היא תמונת השער — בכרטיס ובראש עמוד הנכס. החצים משנים את הסדר.', 'The first one is the cover photo — on the card and at the top of the property page. The arrows change the order.'),
          style: small.copyWith(fontSize: 11, color: AppColors.grayText),
        ),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          Container(
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              tr('אין תמונות', 'No photos'),
              style: small.copyWith(color: AppColors.grayLight),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final (i, url) in _photos.indexed) _tile(i, url)],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickAndUpload,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: Text(_busy ? tr('מעלה…', 'Uploading…') : tr('העלאת תמונות', 'Upload photos'), style: small),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _url,
                style: small,
                textDirection: TextDirection.ltr,
                onSubmitted: (_) => _addUrl(),
                decoration: InputDecoration(
                  hintText: tr('או הדביקו כתובת של תמונה', 'or paste an image address'),
                  hintStyle: small.copyWith(color: AppColors.adminTextLight),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _addUrl,
              child: Text(tr('הוספה', 'Add'), style: small),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _error!,
              style: small.copyWith(fontSize: 11, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _tile(int i, String url) {
    final isCover = i == 0;
    Widget action(IconData icon, String tip, VoidCallback? onTap) => Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? AppColors.grayLight : AppColors.navy,
          ),
        ),
      ),
    );

    return Container(
      width: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCover ? AppColors.midBlue : AppColors.border,
          width: isCover ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              NetworkPhoto(
                url: url,
                width: 130,
                height: 90,
                radius: const BorderRadius.vertical(top: Radius.circular(7)),
                icon: Icons.image_outlined,
                iconSize: 22,
              ),
              if (isCover)
                PositionedDirectional(
                  top: 4,
                  start: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.midBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tr('שער', 'Cover'),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // The chevrons follow the text direction, so "left" is drawn
              // pointing right in Hebrew: towards the start of the row, which
              // is where an earlier photo sits.
              action(
                Icons.chevron_left,
                tr('הזזה קדימה', 'Move earlier'),
                i == 0 ? null : () => _move(i, i - 1),
              ),
              action(
                Icons.star_outline,
                tr('קביעה כתמונת שער', 'Set as cover photo'),
                isCover ? null : () => _move(i, 0),
              ),
              action(Icons.delete_outline, tr('הסרה', 'Remove'), () => _remove(i)),
              action(
                Icons.chevron_right,
                tr('הזזה אחורה', 'Move later'),
                i == _photos.length - 1 ? null : () => _move(i, i + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
