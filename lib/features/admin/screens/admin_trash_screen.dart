import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_trash_provider.dart';

class AdminTrashScreen extends ConsumerStatefulWidget {
  const AdminTrashScreen({super.key});

  @override
  ConsumerState<AdminTrashScreen> createState() => _AdminTrashScreenState();
}

class _AdminTrashScreenState extends ConsumerState<AdminTrashScreen> {
  String _entityFilter = '';

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminTrashListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats bar ───
      asyncData.whenData((list) {
        final byType = <String, int>{};
        for (final t in list) {
          final type = t['entity_type'] as String? ?? 'other';
          byType[type] = (byType[type] ?? 0) + 1;
        }
        final expiringSoon = list.where((t) {
          final exp = t['expires_at'] as String?;
          if (exp == null) return false;
          return ref.read(adminTrashListProvider.notifier).daysUntilExpiry(exp) <= 3;
        }).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            _StatChip('פריטים בסל', '${list.length}', AppColors.navy),
            const SizedBox(width: 16),
            _StatChip('עסקים', '${byType['business'] ?? 0}', AppColors.turquoise),
            const SizedBox(width: 16),
            _StatChip('כתבות', '${byType['article'] ?? 0}', AppColors.success),
            const SizedBox(width: 16),
            _StatChip('נמחקים בקרוב', '$expiringSoon', AppColors.error),
          ]),
        );
      }).value ?? const SizedBox.shrink(),

      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          Icon(Icons.delete_outline, size: 20, color: AppColors.error),
          const SizedBox(width: 8),
          Text('סל מחזור', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(width: 20),
          _FilterChip('הכל', _entityFilter.isEmpty, () { setState(() => _entityFilter = ''); ref.read(adminTrashListProvider.notifier).setEntityFilter(null); }),
          _FilterChip('עסקים', _entityFilter == 'business', () { setState(() => _entityFilter = 'business'); ref.read(adminTrashListProvider.notifier).setEntityFilter('business'); }),
          _FilterChip('כתבות', _entityFilter == 'article', () { setState(() => _entityFilter = 'article'); ref.read(adminTrashListProvider.notifier).setEntityFilter('article'); }),
          _FilterChip('ביקורות', _entityFilter == 'review', () { setState(() => _entityFilter = 'review'); ref.read(adminTrashListProvider.notifier).setEntityFilter('review'); }),
          _FilterChip('אירועים', _entityFilter == 'event', () { setState(() => _entityFilter = 'event'); ref.read(adminTrashListProvider.notifier).setEntityFilter('event'); }),
          const Spacer(),
          asyncData.whenData((list) => Text('${list.length} פריטים', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text('ריקון סל', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                content: Text('מחיקה לצמיתות של כל הפריטים?', style: GoogleFonts.rubik()),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik())),
                  FilledButton(
                    onPressed: () { ref.read(adminTrashListProvider.notifier).emptyTrash(); Navigator.pop(ctx); },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    child: Text('מחק הכל', style: GoogleFonts.rubik()),
                  ),
                ],
              ));
            },
            icon: const Icon(Icons.delete_forever, size: 16, color: AppColors.error),
            label: Text('ריקון סל', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),

      // ─── Warning ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.08)),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Text('פריטים נמחקים אוטומטית לאחר 30 יום', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.gold)),
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
                Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('הסל ריק 🎉', style: GoogleFonts.rubik(color: AppColors.grayText, fontSize: 16)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('פריט', flex: 3),
                  _Col('סוג', flex: 1),
                  if (isWide) _Col('נמחק ע"י', flex: 2),
                  if (isWide) _Col('תאריך מחיקה', flex: 2),
                  _Col('נמחק בעוד', flex: 1),
                  const SizedBox(width: 80),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final entityType = t['entity_type'] as String? ?? '';
                    final expiresAt = t['expires_at'] as String? ?? '';
                    final daysLeft = expiresAt.isNotEmpty
                      ? ref.read(adminTrashListProvider.notifier).daysUntilExpiry(expiresAt)
                      : 30;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: daysLeft <= 3 ? AppColors.error.withValues(alpha: 0.03) : null,
                      child: Row(children: [
                        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['entity_title'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                          if (t['entity_data'] != null && t['entity_data'] is Map)
                            Text(_entitySubtitle(entityType, t['entity_data'] as Map), style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                        ])),
                        Expanded(flex: 1, child: _EntityTypePill(entityType)),
                        if (isWide) Expanded(flex: 2, child: Text(t['deleted_by_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))),
                        if (isWide) Expanded(flex: 2, child: Text(_formatDate(t['deleted_at'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                        Expanded(flex: 1, child: Text(
                          daysLeft <= 0 ? 'היום!' : '$daysLeft ימים',
                          style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: daysLeft <= 3 ? AppColors.error : AppColors.grayText),
                        )),
                        SizedBox(
                          width: 80,
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            IconButton(
                              icon: const Icon(Icons.restore, size: 18, color: AppColors.success),
                              tooltip: 'שחזור',
                              onPressed: () => ref.read(adminTrashListProvider.notifier).restore(t['id'] as String),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.error),
                              tooltip: 'מחיקה לצמיתות',
                              onPressed: () => ref.read(adminTrashListProvider.notifier).permanentDelete(t['id'] as String),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  String _entitySubtitle(String type, Map data) {
    return switch (type) {
      'business' => '${data['category'] ?? ''} · ${data['address'] ?? ''}',
      'article' => data['slug'] as String? ?? '',
      'review' => '${data['user_name'] ?? ''} → ${data['business_name'] ?? ''}',
      'event' => '${data['date'] ?? ''} · ${data['location'] ?? ''}',
      _ => '',
    };
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Helper Widgets ───

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.rubik(fontSize: 12, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.grayText)),
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grayText)));
  }
}

class _EntityTypePill extends StatelessWidget {
  final String type;
  const _EntityTypePill(this.type);

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (type) {
      'business' => ('עסק', Icons.store, AppColors.turquoise),
      'article' => ('כתבה', Icons.article, AppColors.navy),
      'review' => ('ביקורת', Icons.rate_review, AppColors.gold),
      'event' => ('אירוע', Icons.event, AppColors.success),
      _ => (type, Icons.help_outline, AppColors.grayText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}
