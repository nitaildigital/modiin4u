import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_media_provider.dart';
import '../providers/media_usage.dart';
import '../widgets/admin_load_error.dart';

// Sizes and dimensions are wrapped in a left-to-right isolate: inside a
// Hebrew line "548×364" read as "364×548" and "47.5 KB" as "KB 47.5".
String _ltr(String s) => '\u2066$s\u2069';

String _formatSize(int bytes) {
  if (bytes < 1024) return _ltr('$bytes B');
  if (bytes < 1024 * 1024) {
    return _ltr('${(bytes / 1024).toStringAsFixed(1)} KB');
  }
  return _ltr('${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB');
}

String _dateOf(Object? createdAt) {
  final d = DateTime.tryParse('${createdAt ?? ''}')?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

List<String> _galleriesOf(Map<String, dynamic> m) =>
    List<String>.from(m['gallery_names'] as List? ?? const []);

class AdminMediaScreen extends ConsumerStatefulWidget {
  const AdminMediaScreen({super.key});
  @override
  ConsumerState<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends ConsumerState<AdminMediaScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _mimeFilter = '';
  bool _gridView = true;
  bool _loadingMore = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setMime(String mime) {
    setState(() => _mimeFilter = mime);
    ref
        .read(adminMediaListProvider.notifier)
        .setMimeFilter(mime.isEmpty ? null : mime);
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminMediaListProvider.notifier).loadMore();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('הטעינה נכשלה: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminMediaListProvider);
    final notifier = ref.read(adminMediaListProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;
    // `valueOrNull`, not `whenData(...).value`: the latter throws when the
    // list failed to load, and took the whole section down with it.
    final loaded = asyncData.valueOrNull;
    final totals = notifier.totals;

    return Column(
      children: [
        // ─── Figures, for the whole table ───
        if (totals != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatChip('סה״כ קבצים', '${totals.files}', AppColors.turquoise),
                _StatChip('תמונות', '${totals.images}', AppColors.midBlue),
                _StatChip(
                  'נפח כולל',
                  _formatSize(totals.bytes),
                  AppColors.gold,
                ),
              ],
            ),
          ),

        // ─── Toolbar ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: isWide ? 280 : 140,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש לפי שם קובץ או טקסט חלופי',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grayLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.turquoise),
                    ),
                  ),
                  onChanged: (v) {
                    // One query when the typing stops, not one per letter.
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 350),
                      () => notifier.setSearch(v.trim().isEmpty ? null : v),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (isWide) ...[
                _FilterChip('הכל', _mimeFilter.isEmpty, () => _setMime('')),
                _FilterChip(
                  'JPEG',
                  _mimeFilter == 'image/jpeg',
                  () => _setMime('image/jpeg'),
                ),
                _FilterChip(
                  'PNG',
                  _mimeFilter == 'image/png',
                  () => _setMime('image/png'),
                ),
                _FilterChip(
                  'WebP',
                  _mimeFilter == 'image/webp',
                  () => _setMime('image/webp'),
                ),
              ],
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: loaded == null
                      ? null
                      : Text(
                          notifier.hasMore
                              ? (isWide
                                    ? '${loaded.length} מתוך ${notifier.totalCount} קבצים'
                                    : '${loaded.length} מתוך ${notifier.totalCount}')
                              : '${notifier.totalCount} קבצים',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _gridView ? Icons.view_list : Icons.grid_view,
                  size: 20,
                  color: AppColors.grayText,
                ),
                onPressed: () => setState(() => _gridView = !_gridView),
                tooltip: _gridView ? 'תצוגת רשימה' : 'תצוגת גריד',
              ),
              const SizedBox(width: 8),
              // The label goes on a phone, where the row has no room for it.
              ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const _UploadDialog(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 16 : 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload, size: 18),
                    if (isWide) ...[
                      const SizedBox(width: 8),
                      Text(
                        'העלאת קובץ',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ─── Content ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AdminLoadError(
              message: 'שגיאה בטעינת המדיה',
              error: e,
              onRetry: notifier.load,
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין קבצי מדיה',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final more = notifier.hasMore
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: _loadingMore ? null : _loadMore,
                          icon: _loadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more, size: 18),
                          label: Text(
                            'טען עוד (${notifier.totalCount - list.length} נותרו)',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null;

              if (_gridView) {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 210,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _MediaCard(
                          media: list[i],
                          onTap: () => _showDetails(list[i]),
                        ),
                      ),
                    ),
                    if (more != null) SliverToBoxAdapter(child: more),
                  ],
                );
              }
              return ListView.separated(
                itemCount: list.length + (more == null ? 0 : 1),
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) => i == list.length
                    ? more!
                    : _MediaRow(
                        media: list[i],
                        isWide: isWide,
                        onTap: () => _showDetails(list[i]),
                        onRemove: () => _confirmRemove(list[i]),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetails(Map<String, dynamic> media) {
    showDialog(
      context: context,
      builder: (_) =>
          _DetailsDialog(media: media, onRemove: () => _confirmRemove(media)),
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> media) async {
    final messenger = ScaffoldMessenger.of(context);
    final removed = await showDialog<bool>(
      context: context,
      builder: (_) => _RemoveDialog(media: media),
    );
    if (removed == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'הקובץ הוסר',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
        ),
      );
    }
  }
}

// ─── Upload ───

/// Picks an image, shows it, and uploads it with its facts read off the
/// file: name, type, size and dimensions.
class _UploadDialog extends ConsumerStatefulWidget {
  const _UploadDialog();
  @override
  ConsumerState<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<_UploadDialog> {
  final _alt = TextEditingController();
  Uint8List? _bytes;
  String _name = '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _alt.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _error = null);
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      setState(() => _error = 'לא ניתן לפתוח את בוחר הקבצים');
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    // The bucket refuses anything over 10 MB, and the refusal reads as a
    // failure rather than as "too big".
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      setState(() => _error = 'הקובץ גדול מ-10MB');
      return;
    }
    setState(() {
      _bytes = bytes;
      _name = picked!.name;
    });
  }

  Future<void> _upload() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminMediaListProvider.notifier)
          .upload(bytes: bytes, originalName: _name, altText: _alt.text);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'הקובץ הועלה',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'ההעלאה נכשלה: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'העלאת קובץ',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _busy ? null : _pick,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.surfaceLight,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.contain)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 36,
                                color: AppColors.grayLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'לחצו לבחירת תמונה (JPEG, PNG, WebP, GIF — עד 10MB)',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  color: AppColors.grayText,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              if (bytes != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_name · ${_formatSize(bytes.lengthInBytes)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _pick,
                      child: Text(
                        'בחירת תמונה אחרת',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _alt,
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                decoration: _inputDecoration('טקסט חלופי (Alt) — לא חובה'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(
              'ביטול',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.grayText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _busy || bytes == null ? null : _upload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('העלה', style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
        ],
      ),
    );
  }
}

// ─── Details ───

/// One file: the picture, its facts, its address to copy, its alt text, and
/// every place it is shown.
class _DetailsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> media;
  final VoidCallback onRemove;
  const _DetailsDialog({required this.media, required this.onRemove});
  @override
  ConsumerState<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends ConsumerState<_DetailsDialog> {
  late final TextEditingController _alt;
  late final Future<List<MediaUse>> _usage;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _alt = TextEditingController(
      text: widget.media['alt_text'] as String? ?? '',
    );
    _usage = ref.read(adminMediaListProvider.notifier).usageOf(widget.media);
  }

  @override
  void dispose() {
    _alt.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final alt = _alt.text.trim();
    if (alt == (widget.media['alt_text'] as String? ?? '').trim()) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminMediaListProvider.notifier)
          .updateAltText(
            widget.media['id'] as String,
            alt.isEmpty ? null : alt,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'השמירה נכשלה: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.media;
    final url = m['url'] as String? ?? '';
    final facts = [
      m['mime_type'] as String? ?? '',
      if (m['width'] != null && m['height'] != null)
        _ltr('${m['width']}×${m['height']}'),
      if (m['size_bytes'] != null)
        _formatSize((m['size_bytes'] as num).toInt()),
      _dateOf(m['created_at']),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          m['file_name'] as String? ?? '',
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.navy,
          ),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 260,
                  width: double.infinity,
                  color: AppColors.surfaceLight,
                  child: NetworkPhoto(
                    url: url,
                    fit: BoxFit.contain,
                    radius: BorderRadius.circular(8),
                    icon: Icons.image_outlined,
                    gradient: const [Color(0xFFF1F3F6), Color(0xFFE4E8EE)],
                    iconColor: AppColors.grayLight,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  facts,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        url,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: url));
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'הכתובת הועתקה',
                              style: TextStyle(fontFamily: AppFonts.rubik),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: Text(
                        'העתקת כתובת',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alt,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: _inputDecoration('טקסט חלופי (Alt)'),
                ),
                const SizedBox(height: 16),
                Text(
                  'בשימוש ב',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                FutureBuilder<List<MediaUse>>(
                  future: _usage,
                  builder: (_, snap) => _UsageList(snap: snap),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onRemove();
                  },
            icon: const Icon(
              Icons.delete_outline,
              size: 16,
              color: AppColors.error,
            ),
            label: Text(
              'הסרת הקובץ',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(
              'ביטול',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                color: AppColors.grayText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('שמור', style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
        ],
      ),
    );
  }
}

/// The places a file is shown, as the database reports them.
class _UsageList extends StatelessWidget {
  final AsyncSnapshot<List<MediaUse>> snap;
  const _UsageList({required this.snap});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.grayText,
    );
    if (snap.connectionState != ConnectionState.done) {
      return const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (snap.hasError) {
      return Text(
        'לא ניתן לבדוק איפה הקובץ בשימוש: ${snap.error}',
        style: style.copyWith(color: AppColors.error),
      );
    }
    final uses = snap.data ?? const [];
    if (uses.isEmpty) return Text('לא בשימוש באף מקום.', style: style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final u in uses)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: style),
                Expanded(child: Text(u.describe(), style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Removal ───

/// Asks the database where the file is used before anything is removed.
///
/// A file in use is not removed from here: every library row today is in a
/// business gallery on the public site, and removing the row takes the
/// photo off that page (`entity_media` cascades); an address copied into a
/// logo or an article would show a broken image. The dialog says where, so
/// it can be taken out there first. The table has no column to hide a row,
/// so a file nothing uses is removed for good — it shows nowhere.
class _RemoveDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> media;
  const _RemoveDialog({required this.media});
  @override
  ConsumerState<_RemoveDialog> createState() => _RemoveDialogState();
}

class _RemoveDialogState extends ConsumerState<_RemoveDialog> {
  late final Future<List<MediaUse>> _usage;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usage = ref.read(adminMediaListProvider.notifier).usageOf(widget.media);
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminMediaListProvider.notifier)
          .deleteUnused(widget.media);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'ההסרה נכשלה: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.media['file_name'] as String? ?? '';
    final body = TextStyle(fontFamily: AppFonts.rubik, fontSize: 13);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<MediaUse>>(
        future: _usage,
        builder: (context, snap) {
          final checked =
              snap.connectionState == ConnectionState.done && !snap.hasError;
          final uses = snap.data ?? const <MediaUse>[];
          final inUse = checked && uses.isNotEmpty;
          return AlertDialog(
            title: Text(
              inUse ? 'הקובץ בשימוש' : 'הסרת קובץ',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontWeight: FontWeight.w700,
                color: inUse ? AppColors.navy : AppColors.error,
              ),
            ),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!checked) ...[
                    Text('בודקים איפה "$name" בשימוש…', style: body),
                    const SizedBox(height: 10),
                    _UsageList(snap: snap),
                  ] else if (inUse) ...[
                    Text(
                      '"$name" מוצג באתר ובאפליקציה ולכן לא יוסר מכאן — '
                      'הסרה הייתה מורידה אותו מהמקומות האלה:',
                      style: body,
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: _UsageList(snap: snap),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'כדי להוריד תמונה מגלריה, פתחו את העסק או השכונה '
                      'ובלשונית ״גלריה״ הסירו אותה ושמרו.',
                      style: body.copyWith(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                  ] else
                    Text(
                      '"$name" אינו בשימוש באף מקום. ההסרה מוחקת את הקובץ '
                      'לצמיתות ואי אפשר לשחזר אותו.',
                      style: body,
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: body.copyWith(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context, false),
                child: Text(
                  inUse ? 'סגור' : 'ביטול',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    color: AppColors.grayText,
                  ),
                ),
              ),
              if (checked && !inUse)
                ElevatedButton(
                  onPressed: _busy ? null : _remove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'הסרה לצמיתות',
                    style: TextStyle(fontFamily: AppFonts.rubik),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Grid and list ───

class _MediaCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final VoidCallback onTap;
  const _MediaCard({required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final galleries = _galleriesOf(media);
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: NetworkPhoto(
                url: media['url'] as String?,
                icon: Icons.image_outlined,
                gradient: const [Color(0xFFF1F3F6), Color(0xFFE4E8EE)],
                iconColor: AppColors.grayLight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    galleries.isNotEmpty
                        ? galleries.join(', ')
                        : media['file_name'] as String? ?? '',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (galleries.isNotEmpty) 'גלריה',
                      if (media['size_bytes'] != null)
                        _formatSize((media['size_bytes'] as num).toInt()),
                      _dateOf(media['created_at']),
                    ].join(' · '),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 10,
                      color: AppColors.grayText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  final Map<String, dynamic> media;
  final bool isWide;
  final VoidCallback onTap, onRemove;
  const _MediaRow({
    required this.media,
    required this.isWide,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final galleries = _galleriesOf(media);
    final small = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.grayText,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            NetworkPhoto(
              url: media['url'] as String?,
              width: 56,
              height: 56,
              radius: BorderRadius.circular(6),
              icon: Icons.image_outlined,
              iconSize: 20,
              gradient: const [Color(0xFFF1F3F6), Color(0xFFE4E8EE)],
              iconColor: AppColors.grayLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media['file_name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.navy,
                    ),
                  ),
                  if (galleries.isNotEmpty)
                    Text(
                      'גלריה: ${galleries.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                ],
              ),
            ),
            if (isWide) ...[
              Expanded(
                child: Text(media['mime_type'] as String? ?? '', style: small),
              ),
              Expanded(
                child: Text(
                  media['size_bytes'] == null
                      ? ''
                      : _formatSize((media['size_bytes'] as num).toInt()),
                  style: small,
                ),
              ),
              Expanded(
                child: Text(
                  media['width'] == null
                      ? ''
                      : _ltr('${media['width']}×${media['height']}'),
                  style: small,
                ),
              ),
            ],
            // On a phone the date wrapped into two lines; it is in the
            // file's details.
            if (isWide)
              Expanded(child: Text(_dateOf(media['created_at']), style: small)),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              tooltip: 'הסרה',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: TextStyle(
    fontFamily: AppFonts.rubik,
    fontSize: 13,
    color: AppColors.grayText,
  ),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
);

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.grayText,
          ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.turquoise.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.turquoise : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.turquoise : AppColors.grayText,
          ),
        ),
      ),
    ),
  );
}
