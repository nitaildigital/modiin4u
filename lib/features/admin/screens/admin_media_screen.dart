import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_media_provider.dart';

class AdminMediaScreen extends ConsumerStatefulWidget {
  const AdminMediaScreen({super.key});
  @override
  ConsumerState<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends ConsumerState<AdminMediaScreen> {
  final _searchController = TextEditingController();
  String _mimeFilter = '';
  bool _gridView = true;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminMediaListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats ───
      asyncData.whenData((list) {
        final totalSize = list.fold<int>(0, (s, m) => s + ((m['file_size'] as int?) ?? 0));
        final images = list.where((m) => (m['mime_type'] as String? ?? '').startsWith('image/')).length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
          child: Row(children: [
            _StatChip('סה"כ קבצים', '${list.length}', AppColors.turquoise),
            const SizedBox(width: 12),
            _StatChip('תמונות', '$images', AppColors.midBlue),
            const SizedBox(width: 12),
            _StatChip('נפח כולל', _formatSize(totalSize), AppColors.gold),
          ]),
        );
      }).value ?? const SizedBox.shrink(),

      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          SizedBox(
            width: isWide ? 280 : 180, height: 40,
            child: TextField(
              controller: _searchController, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש קובץ...', hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => ref.read(adminMediaListProvider.notifier).setSearch(v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _mimeFilter.isEmpty, () { setState(() => _mimeFilter = ''); ref.read(adminMediaListProvider.notifier).setMimeFilter(null); }),
          _FilterChip('JPEG', _mimeFilter == 'image/jpeg', () { setState(() => _mimeFilter = 'image/jpeg'); ref.read(adminMediaListProvider.notifier).setMimeFilter('image/jpeg'); }),
          _FilterChip('PNG', _mimeFilter == 'image/png', () { setState(() => _mimeFilter = 'image/png'); ref.read(adminMediaListProvider.notifier).setMimeFilter('image/png'); }),
          _FilterChip('WebP', _mimeFilter == 'image/webp', () { setState(() => _mimeFilter = 'image/webp'); ref.read(adminMediaListProvider.notifier).setMimeFilter('image/webp'); }),
          const Spacer(),
          IconButton(
            icon: Icon(_gridView ? Icons.grid_view : Icons.view_list, size: 20, color: AppColors.grayText),
            onPressed: () => setState(() => _gridView = !_gridView),
            tooltip: _gridView ? 'תצוגת רשימה' : 'תצוגת גריד',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showEditor(context, null),
            icon: const Icon(Icons.upload, size: 18),
            label: Text('העלאת קובץ', style: GoogleFonts.rubik(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),

      // ─── Content ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.photo_library_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין קבצי מדיה', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            if (_gridView) {
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 5 : 3, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _MediaCard(media: list[i], onTap: () => _showEditor(context, list[i]), onDelete: () => _confirmDelete(context, list[i])),
              );
            }
            return _MediaTable(list: list, isWide: isWide, onEdit: (m) => _showEditor(context, m), onDelete: (m) => _confirmDelete(context, m));
          },
        ),
      ),
    ]);
  }

  void _showEditor(BuildContext context, Map<String, dynamic>? existing) {
    final filenameC = TextEditingController(text: existing?['filename'] ?? '');
    final altC = TextEditingController(text: existing?['alt_text'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existing == null ? 'העלאת קובץ' : 'עריכת מדיה', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.navy)),
          content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (existing == null) Container(
              height: 120, width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8), color: AppColors.surfaceLight),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.grayLight),
                const SizedBox(height: 8),
                Text('גרור קובץ לכאן או לחץ לבחירה', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
              ])),
            ),
            const SizedBox(height: 14),
            TextField(controller: filenameC, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(labelText: 'שם קובץ', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            const SizedBox(height: 14),
            TextField(controller: altC, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(labelText: 'טקסט חלופי (Alt)', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            if (existing != null) ...[
              const SizedBox(height: 14),
              Row(children: [
                Text('${existing['width']}×${existing['height']}', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                const SizedBox(width: 12),
                Text(_formatSize(existing['file_size'] as int? ?? 0), style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                const SizedBox(width: 12),
                Text(existing['mime_type'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ]),
            ],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik(color: AppColors.grayText))),
            ElevatedButton(
              onPressed: () {
                final data = {'filename': filenameC.text, 'alt_text': altC.text, 'mime_type': 'image/jpeg', 'file_size': 100000, 'width': 800, 'height': 600, 'uploaded_by': 'ניתאי לוי'};
                if (existing != null) {
                  ref.read(adminMediaListProvider.notifier).updateMedia(existing['id'] as String, {'filename': filenameC.text, 'alt_text': altC.text});
                } else {
                  ref.read(adminMediaListProvider.notifier).createMedia(data);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(existing == null ? 'העלה' : 'שמור', style: GoogleFonts.rubik()),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> media) {
    showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: Text('מחיקת קובץ', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.error)),
      content: Text('למחוק את "${media['filename']}"?', style: GoogleFonts.rubik()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik(color: AppColors.grayText))),
        ElevatedButton(onPressed: () { ref.read(adminMediaListProvider.notifier).deleteMedia(media['id'] as String); Navigator.pop(ctx); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: Text('מחק', style: GoogleFonts.rubik())),
      ],
    )));
  }
}

class _MediaCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final VoidCallback onTap, onDelete;
  const _MediaCard({required this.media, required this.onTap, required this.onDelete});

  IconData _mimeIcon(String mime) => switch (mime) {
    'image/svg+xml' => Icons.draw,
    'image/webp' => Icons.image,
    'image/png' => Icons.image,
    _ => Icons.photo,
  };

  @override
  Widget build(BuildContext context) {
    final mime = media['mime_type'] as String? ?? '';
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Center(child: Icon(_mimeIcon(mime), size: 36, color: AppColors.grayLight)),
          )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(media['filename'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(media['alt_text'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayText), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MediaTable extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final bool isWide;
  final void Function(Map<String, dynamic>) onEdit, onDelete;
  const _MediaTable({required this.list, required this.isWide, required this.onEdit, required this.onDelete});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          _Col('שם קובץ', flex: 3),
          _Col('סוג', flex: 1),
          if (isWide) _Col('גודל', flex: 1),
          if (isWide) _Col('ממדים', flex: 1),
          _Col('הועלה ע"י', flex: 1),
          const SizedBox(width: 40),
        ]),
      ),
      Expanded(child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
        itemBuilder: (_, i) {
          final m = list[i];
          return ListTile(
            dense: true,
            title: Text(m['filename'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.navy)),
            subtitle: Text(m['alt_text'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 16, color: AppColors.grayLight), onPressed: () => onEdit(m)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), onPressed: () => onDelete(m)),
            ]),
          );
        },
      )),
    ]);
  }
}

class _Col extends StatelessWidget {
  final String label; final int flex; const _Col(this.label, {this.flex = 1});
  @override Widget build(BuildContext context) => Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)));
}

class _StatChip extends StatelessWidget {
  final String label, value; final Color color;
  const _StatChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 6), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: selected ? AppColors.turquoise : AppColors.border, width: 0.5)),
    child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.turquoise : AppColors.grayText)),
  )));
}
