import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_tags_provider.dart';

class AdminTagsScreen extends ConsumerStatefulWidget {
  const AdminTagsScreen({super.key});
  @override
  ConsumerState<AdminTagsScreen> createState() => _AdminTagsScreenState();
}

class _AdminTagsScreenState extends ConsumerState<AdminTagsScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'name';

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminTagListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
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
                hintText: 'חיפוש תגית...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => ref.read(adminTagListProvider.notifier).setSearch(v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(width: 12),
          _SortChip('שם', _sortBy == 'name', () { setState(() => _sortBy = 'name'); ref.read(adminTagListProvider.notifier).setSortBy('name'); }),
          _SortChip('שימוש', _sortBy == 'usage', () { setState(() => _sortBy = 'usage'); ref.read(adminTagListProvider.notifier).setSortBy('usage'); }),
          const Spacer(),
          asyncData.whenData((l) => Text('${l.length} תגיות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showEditor(context, null),
            icon: const Icon(Icons.add, size: 18),
            label: Text('תגית חדשה', style: GoogleFonts.rubik(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),

      // ─── Tags Grid ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.label_off, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין תגיות', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 10, runSpacing: 10,
                children: list.map((tag) => _TagChip(
                  tag: tag,
                  onEdit: () => _showEditor(context, tag),
                  onDelete: () => _confirmDelete(context, tag),
                )).toList(),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _showEditor(BuildContext context, Map<String, dynamic>? existing) {
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final slugC = TextEditingController(text: existing?['slug'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existing == null ? 'תגית חדשה' : 'עריכת תגית', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.navy)),
          content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(labelText: 'שם', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            const SizedBox(height: 14),
            TextField(controller: slugC, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(labelText: 'Slug', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik(color: AppColors.grayText))),
            ElevatedButton(
              onPressed: () {
                final data = {'name': nameC.text, 'slug': slugC.text.isEmpty ? nameC.text.toLowerCase().replaceAll(' ', '-') : slugC.text};
                if (existing != null) {
                  ref.read(adminTagListProvider.notifier).updateTag(existing['id'] as String, data);
                } else {
                  ref.read(adminTagListProvider.notifier).createTag(data);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(existing == null ? 'צור' : 'שמור', style: GoogleFonts.rubik()),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> tag) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('מחיקת תגית', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.error)),
          content: Text('למחוק את התגית "${tag['name']}"?', style: GoogleFonts.rubik()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik(color: AppColors.grayText))),
            ElevatedButton(
              onPressed: () { ref.read(adminTagListProvider.notifier).deleteTag(tag['id'] as String); Navigator.pop(ctx); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: Text('מחק', style: GoogleFonts.rubik()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Map<String, dynamic> tag;
  final VoidCallback onEdit, onDelete;
  const _TagChip({required this.tag, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final usage = tag['usage_count'] as int? ?? 0;
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: AppColors.turquoise.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onEdit, borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.label, size: 16, color: AppColors.turquoise),
            const SizedBox(width: 8),
            Text(tag['name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
              child: Text('$usage', style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayText)),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onDelete,
              child: Icon(Icons.close, size: 14, color: AppColors.grayLight.withValues(alpha: 0.6)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _SortChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 6), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: selected ? AppColors.turquoise : AppColors.border, width: 0.5)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.turquoise : AppColors.grayText)),
    )));
  }
}
