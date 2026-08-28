import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_reports_provider.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _statusFilter = '';
  String _entityFilter = '';

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminReportsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats ───
      asyncData.whenData((list) {
        final open = list.where((r) => r['status'] == 'open').length;
        final investigating = list.where((r) => r['status'] == 'investigating').length;
        final resolved = list.where((r) => r['status'] == 'resolved').length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
          child: Row(children: [
            _StatChip('פתוחים', '$open', AppColors.error),
            const SizedBox(width: 12),
            _StatChip('בטיפול', '$investigating', AppColors.gold),
            const SizedBox(width: 12),
            _StatChip('נפתרו', '$resolved', AppColors.success),
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
          _FilterChip('הכל', _statusFilter.isEmpty, () { setState(() => _statusFilter = ''); ref.read(adminReportsProvider.notifier).setStatusFilter(null); }),
          _FilterChip('פתוח', _statusFilter == 'open', () { setState(() => _statusFilter = 'open'); ref.read(adminReportsProvider.notifier).setStatusFilter('open'); }),
          _FilterChip('בטיפול', _statusFilter == 'investigating', () { setState(() => _statusFilter = 'investigating'); ref.read(adminReportsProvider.notifier).setStatusFilter('investigating'); }),
          _FilterChip('נפתר', _statusFilter == 'resolved', () { setState(() => _statusFilter = 'resolved'); ref.read(adminReportsProvider.notifier).setStatusFilter('resolved'); }),
          _FilterChip('נדחה', _statusFilter == 'dismissed', () { setState(() => _statusFilter = 'dismissed'); ref.read(adminReportsProvider.notifier).setStatusFilter('dismissed'); }),
          if (isWide) ...[
            const SizedBox(width: 16),
            _FilterChip('עסקים', _entityFilter == 'business', () { setState(() => _entityFilter = _entityFilter == 'business' ? '' : 'business'); ref.read(adminReportsProvider.notifier).setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter); }),
            _FilterChip('ביקורות', _entityFilter == 'review', () { setState(() => _entityFilter = _entityFilter == 'review' ? '' : 'review'); ref.read(adminReportsProvider.notifier).setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter); }),
            _FilterChip('תגובות', _entityFilter == 'comment', () { setState(() => _entityFilter = _entityFilter == 'comment' ? '' : 'comment'); ref.read(adminReportsProvider.notifier).setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter); }),
          ],
          const Spacer(),
          asyncData.whenData((l) => Text('${l.length} דיווחים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
        ]),
      ),

      // ─── Table ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין דיווחים', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('סיבה', flex: 2),
                  _Col('פריט', flex: 3),
                  _Col('מדווח', flex: 2),
                  _Col('סטטוס', flex: 1),
                  if (isWide) _Col('תאריך', flex: 1),
                  const SizedBox(width: 80),
                ]),
              ),
              Expanded(child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                itemBuilder: (_, i) {
                  final r = list[i];
                  final status = r['status'] as String? ?? 'open';
                  final isOpen = status == 'open';
                  final reason = _reasonLabel(r['reason'] as String? ?? '');
                  final entityIcon = _entityIcon(r['entity_type'] as String? ?? '');

                  return Container(
                    color: isOpen ? AppColors.error.withValues(alpha: 0.03) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(children: [
                      Expanded(flex: 2, child: Row(children: [
                        Icon(_reasonIcon(r['reason'] as String? ?? ''), size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Flexible(child: Text(reason, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.navy))),
                      ])),
                      Expanded(flex: 3, child: Row(children: [
                        Icon(entityIcon, size: 14, color: AppColors.grayLight),
                        const SizedBox(width: 6),
                        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['entity_title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (r['details'] != null && (r['details'] as String).isNotEmpty)
                            Text(r['details'] as String, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                      ])),
                      Expanded(flex: 2, child: Text(r['reporter_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                      Expanded(flex: 1, child: _StatusPill(status)),
                      if (isWide) Expanded(flex: 1, child: Text(_shortDate(r['created_at'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                      SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        if (status == 'pending') ...[
                          IconButton(icon: const Icon(Icons.search, size: 16, color: AppColors.gold), tooltip: 'בדוק',
                            onPressed: () => ref.read(adminReportsProvider.notifier).markReviewed(r['id'] as String)),
                          IconButton(icon: const Icon(Icons.check, size: 16, color: AppColors.success), tooltip: 'טפל',
                            onPressed: () => ref.read(adminReportsProvider.notifier).resolve(r['id'] as String, 'טופל')),
                          IconButton(icon: const Icon(Icons.close, size: 16, color: AppColors.grayLight), tooltip: 'דחה',
                            onPressed: () => ref.read(adminReportsProvider.notifier).dismiss(r['id'] as String)),
                        ],
                        if (status == 'reviewed')
                          IconButton(icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success), tooltip: 'נפתר',
                            onPressed: () => ref.read(adminReportsProvider.notifier).resolve(r['id'] as String, 'טופל')),
                      ])),
                    ]),
                  );
                },
              )),
            ]);
          },
        ),
      ),
    ]);
  }

  String _reasonLabel(String r) => switch (r) { 'spam' => 'ספאם', 'inappropriate' => 'תוכן לא הולם', 'fake' => 'תוכן מזויף', 'harassment' => 'הטרדה', 'copyright' => 'הפרת זכויות יוצרים', 'other' => 'אחר', _ => r };
  IconData _reasonIcon(String r) => switch (r) { 'spam' => Icons.report, 'inappropriate' => Icons.warning, 'fake' => Icons.error_outline, 'harassment' => Icons.person_off, 'copyright' => Icons.copyright, _ => Icons.flag };
  IconData _entityIcon(String t) => switch (t) { 'business' => Icons.store, 'review' => Icons.rate_review, 'comment' => Icons.comment, 'article' => Icons.article, 'user' => Icons.person, _ => Icons.help_outline };
  String _shortDate(String iso) { try { final d = DateTime.parse(iso); return '${d.day}/${d.month}/${d.year}'; } catch (_) { return iso; } }
}

class _StatusPill extends StatelessWidget {
  final String status; const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) { 'open' => ('פתוח', AppColors.error), 'investigating' => ('בטיפול', AppColors.gold), 'resolved' => ('נפתר', AppColors.success), 'dismissed' => ('נדחה', AppColors.grayLight), _ => (status, AppColors.grayLight) };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w600, color: color)));
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
