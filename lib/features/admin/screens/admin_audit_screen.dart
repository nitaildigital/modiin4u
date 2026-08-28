import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_audit_provider.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});
  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final _searchController = TextEditingController();
  String _actionFilter = '';

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminAuditProvider);
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
                hintText: 'חיפוש ביומן...', hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => ref.read(adminAuditProvider.notifier).setSearch(v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _actionFilter.isEmpty, () { setState(() => _actionFilter = ''); ref.read(adminAuditProvider.notifier).setActionFilter(null); }),
          _FilterChip('יצירה', _actionFilter == 'create', () { setState(() => _actionFilter = 'create'); ref.read(adminAuditProvider.notifier).setActionFilter('create'); }),
          _FilterChip('עריכה', _actionFilter == 'update', () { setState(() => _actionFilter = 'update'); ref.read(adminAuditProvider.notifier).setActionFilter('update'); }),
          _FilterChip('מחיקה', _actionFilter == 'delete', () { setState(() => _actionFilter = 'delete'); ref.read(adminAuditProvider.notifier).setActionFilter('delete'); }),
          _FilterChip('אישור', _actionFilter == 'approve', () { setState(() => _actionFilter = 'approve'); ref.read(adminAuditProvider.notifier).setActionFilter('approve'); }),
          const Spacer(),
          asyncData.whenData((l) => Text('${l.length} רשומות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
        ]),
      ),

      // ─── Timeline ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.history_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין רשומות ביומן', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final action = e['action'] as String? ?? '';
                final isLast = i == list.length - 1;

                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Timeline rail
                    SizedBox(width: 40, child: Column(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _actionColor(action))),
                      if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border.withValues(alpha: 0.3))),
                    ])),
                    // Content
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(_actionIcon(action), size: 16, color: _actionColor(action)),
                            const SizedBox(width: 8),
                            Text(_actionLabel(action), style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: _actionColor(action))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4)),
                              child: Text(_entityLabel(e['entity_type'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayText)),
                            ),
                            const Spacer(),
                            Text(_timeAgo(e['created_at'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                          ]),
                          const SizedBox(height: 8),
                          Text(e['entity_title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
                          const SizedBox(height: 4),
                          Row(children: [
                            CircleAvatar(radius: 10, backgroundColor: AppColors.turquoise.withValues(alpha: 0.1),
                              child: Text((e['admin_name'] as String? ?? '?')[0], style: GoogleFonts.rubik(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.turquoise))),
                            const SizedBox(width: 6),
                            Text(e['admin_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                            if (isWide && e['ip_address'] != null) ...[
                              const SizedBox(width: 12),
                              Text(e['ip_address'] as String, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight, fontFeatures: [const FontFeature.tabularFigures()])),
                            ],
                          ]),
                          if (e['changes'] != null && (e['changes'] as Map).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('שינויים:', style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grayText)),
                                const SizedBox(height: 4),
                                ...(e['changes'] as Map).entries.take(3).map((entry) =>
                                  Padding(padding: const EdgeInsets.only(bottom: 2), child: RichText(text: TextSpan(style: GoogleFonts.rubik(fontSize: 11, color: AppColors.navy), children: [
                                    TextSpan(text: '${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (entry.value is Map) ...[
                                      TextSpan(text: '${(entry.value as Map)['old'] ?? ''} → ', style: TextStyle(color: AppColors.error.withValues(alpha: 0.7), decoration: TextDecoration.lineThrough)),
                                      TextSpan(text: '${(entry.value as Map)['new'] ?? ''}', style: const TextStyle(color: AppColors.success)),
                                    ] else TextSpan(text: '${entry.value}'),
                                  ])))),
                              ]),
                            ),
                          ],
                        ]),
                      ),
                    )),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Color _actionColor(String a) => switch (a) { 'create' => AppColors.success, 'update' => AppColors.turquoise, 'delete' => AppColors.error, 'approve' => AppColors.gold, 'reject' => AppColors.error, 'login' => AppColors.midBlue, _ => AppColors.grayLight };
  IconData _actionIcon(String a) => switch (a) { 'create' => Icons.add_circle_outline, 'update' => Icons.edit, 'delete' => Icons.delete_outline, 'approve' => Icons.check_circle_outline, 'reject' => Icons.cancel_outlined, 'login' => Icons.login, _ => Icons.info_outline };
  String _actionLabel(String a) => switch (a) { 'create' => 'יצירה', 'update' => 'עריכה', 'delete' => 'מחיקה', 'approve' => 'אישור', 'reject' => 'דחייה', 'login' => 'כניסה', _ => a };
  String _entityLabel(String t) => switch (t) { 'business' => 'עסק', 'article' => 'כתבה', 'event' => 'אירוע', 'review' => 'ביקורת', 'user' => 'משתמש', 'category' => 'קטגוריה', 'campaign' => 'קמפיין', 'offer' => 'מבצע', _ => t };

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
      if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
      if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }
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
