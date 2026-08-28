import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_comments_provider.dart';

class AdminCommentsScreen extends ConsumerStatefulWidget {
  const AdminCommentsScreen({super.key});
  @override
  ConsumerState<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends ConsumerState<AdminCommentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = '';
  String _entityFilter = '';

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminCommentsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats ───
      asyncData.whenData((list) {
        final pending = list.where((c) => c['status'] == 'pending').length;
        final approved = list.where((c) => c['status'] == 'approved').length;
        final flagged = list.where((c) => c['is_flagged'] == true).length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
          child: Row(children: [
            _StatChip('ממתינות', '$pending', AppColors.gold),
            const SizedBox(width: 12),
            _StatChip('מאושרות', '$approved', AppColors.success),
            const SizedBox(width: 12),
            _StatChip('מסומנות', '$flagged', AppColors.error),
            const SizedBox(width: 12),
            _StatChip('סה"כ', '${list.length}', AppColors.turquoise),
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
                hintText: 'חיפוש תגובה...', hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => ref.read(adminCommentsProvider.notifier).setSearch(v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () { setState(() => _statusFilter = ''); ref.read(adminCommentsProvider.notifier).setStatusFilter(null); }),
          _FilterChip('ממתין', _statusFilter == 'pending', () { setState(() => _statusFilter = 'pending'); ref.read(adminCommentsProvider.notifier).setStatusFilter('pending'); }),
          _FilterChip('מאושר', _statusFilter == 'approved', () { setState(() => _statusFilter = 'approved'); ref.read(adminCommentsProvider.notifier).setStatusFilter('approved'); }),
          _FilterChip('נדחה', _statusFilter == 'rejected', () { setState(() => _statusFilter = 'rejected'); ref.read(adminCommentsProvider.notifier).setStatusFilter('rejected'); }),
          if (isWide) ...[
            const SizedBox(width: 12),
            _FilterChip('עסקים', _entityFilter == 'business', () { setState(() => _entityFilter = _entityFilter == 'business' ? '' : 'business'); ref.read(adminCommentsProvider.notifier).setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter); }),
            _FilterChip('כתבות', _entityFilter == 'article', () { setState(() => _entityFilter = _entityFilter == 'article' ? '' : 'article'); ref.read(adminCommentsProvider.notifier).setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter); }),
          ],
          const Spacer(),
          asyncData.whenData((l) => Text('${l.length} תגובות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
        ]),
      ),

      // ─── List ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.forum_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין תגובות', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
              itemBuilder: (_, i) {
                final c = list[i];
                final status = c['status'] as String? ?? 'pending';
                final isFlagged = c['is_flagged'] as bool? ?? false;
                final isPinned = c['is_pinned'] as bool? ?? false;

                return Container(
                  color: isFlagged ? AppColors.error.withValues(alpha: 0.04) : (status == 'pending' ? AppColors.gold.withValues(alpha: 0.04) : null),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(radius: 18, backgroundColor: AppColors.turquoise.withValues(alpha: 0.1),
                      child: Text((c['user_name'] as String? ?? '?')[0], style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.turquoise))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(c['user_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                        const SizedBox(width: 8),
                        Text(_entityLabel(c['entity_type'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                        const SizedBox(width: 4),
                        Flexible(child: Text(c['entity_title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const Spacer(),
                        _StatusPill(status),
                        if (isFlagged) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.flag, size: 14, color: AppColors.error),
                        ],
                      ]),
                      const SizedBox(height: 6),
                      Text(c['body'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.navy, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text(_shortDate(c['created_at'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => ref.read(adminCommentsProvider.notifier).toggleVisibility(c['id'] as String),
                          icon: Icon(status == 'visible' ? Icons.visibility_off : Icons.visibility, size: 14),
                          label: Text(status == 'visible' ? 'הסתר' : 'הצג', style: GoogleFonts.rubik(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.turquoise, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                        TextButton.icon(
                          onPressed: () => ref.read(adminCommentsProvider.notifier).togglePin(c['id'] as String),
                          icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 14),
                          label: Text(isPinned ? 'בטל הצמדה' : 'הצמד', style: GoogleFonts.rubik(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                          onPressed: () => ref.read(adminCommentsProvider.notifier).deleteComment(c['id'] as String),
                          tooltip: 'מחק',
                        ),
                      ]),
                    ])),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  String _entityLabel(String t) => switch (t) { 'business' => 'עסק:', 'article' => 'כתבה:', 'event' => 'אירוע:', _ => '$t:' };
  String _shortDate(String iso) { try { final d = DateTime.parse(iso); return '${d.day}/${d.month}/${d.year}'; } catch (_) { return iso; } }
}

class _StatusPill extends StatelessWidget {
  final String status; const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) { 'approved' => ('מאושר', AppColors.success), 'pending' => ('ממתין', AppColors.gold), 'rejected' => ('נדחה', AppColors.error), _ => (status, AppColors.grayLight) };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w600, color: color)));
  }
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
