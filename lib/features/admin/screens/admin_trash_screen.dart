import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_trash_provider.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminTrashScreen extends ConsumerStatefulWidget {
  const AdminTrashScreen({super.key});

  @override
  ConsumerState<AdminTrashScreen> createState() => _AdminTrashScreenState();
}

class _AdminTrashScreenState extends ConsumerState<AdminTrashScreen> {
  String _tableFilter = '';

  /// The row whose restore is under way, so its button can't be pressed
  /// twice.
  String? _restoring;

  void _setTable(String table) {
    setState(() => _tableFilter = table);
    ref.read(adminTrashListProvider.notifier).setTableFilter(table);
  }

  Future<void> _restore(TrashItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _restoring = item.id);
    try {
      final target = await ref
          .read(adminTrashListProvider.notifier)
          .restore(item);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr('"${_title(item)}" שוחזר — ${trashStateLabels[target] ?? target}', '"${_title(item)}" restored — ${trashStateLabels[target] ?? target}'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr('השחזור נכשל: $e', 'Restoring failed: $e'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _restoring = null);
    }
  }

  String _title(TrashItem item) {
    if (item.title.isEmpty) return item.source.kind;
    final t = item.title.replaceAll(RegExp(r'\s+'), ' ');
    return t.length > 80 ? '${t.substring(0, 80)}…' : t;
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminTrashListProvider);
    final notifier = ref.read(adminTrashListProvider.notifier);
    final list = asyncData.valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    final byTable = <String, int>{};
    for (final t in list ?? const <TrashItem>[]) {
      byTable[t.source.table] = (byTable[t.source.table] ?? 0) + 1;
    }

    return Column(
      children: [
        const _HowThisWorksNote(),

        // ─── Toolbar ───
        AdminListToolbar(
          search: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restore_from_trash, size: 20, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                tr('סל מחזור', 'Trash'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          filters: [
            AdminFilterChip(
              tr('הכל', 'All'),
              _tableFilter.isEmpty,
              () => _setTable(''),
            ),
            // Once filtered, the other tables were not read, so every chip
            // stays offered; unfiltered, only the tables that have something
            // removed.
            for (final s in trashSources)
              if (_tableFilter.isNotEmpty || (byTable[s.table] ?? 0) > 0)
                AdminFilterChip(
                  byTable[s.table] == null
                      ? s.kind
                      : '${s.kind} (${byTable[s.table]})',
                  _tableFilter == s.table,
                  () => _setTable(s.table),
                ),
          ],
          count: list == null ? null : tr('${list.length} פריטים', '${list.length} items'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: tr('רענון', 'Refresh'),
              onPressed: notifier.load,
            ),
          ],
        ),

        // Tables that could not be read are named, not passed off as empty.
        if (asyncData.hasValue && notifier.failures.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppColors.error.withValues(alpha: 0.06),
            child: Text(
              tr('לא ניתן היה לקרוא: ${notifier.failures.keys.map((t) => trashSources.firstWhere((s) => s.table == t).kind).join(', ')}', 'Could not read: ${notifier.failures.keys.map((t) => trashSources.firstWhere((s) => s.table == t).kind).join(', ')}'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),

        // ─── Table ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                tr('שגיאה: $e', 'Error: $e'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.success.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין פריטים שהוסרו', 'No removed items'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _Col(tr('פריט', 'Item'), flex: 4),
                        _Col(tr('סוג', 'Type'), flex: 2),
                        _Col(tr('מצב', 'Status'), flex: 1),
                        if (isWide) _Col(tr('שינוי אחרון', 'Last change'), flex: 2),
                        SizedBox(width: adminEnglish.value ? 112 : 96),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) {
                        final t = list[i];
                        final busy = _restoring == t.id;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  _title(t),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: AdminPill(t.source.kind, AdminKit.of(context).accent),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  trashStateLabels[t.state] ?? t.state,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 12,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ),
                              if (isWide)
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _formatDate(t.changedAt),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: adminEnglish.value ? 112 : 96,
                                child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : TextButton.icon(
                                          onPressed: _restoring == null
                                              ? () => _restore(t)
                                              : null,
                                          icon: const Icon(
                                            Icons.restore,
                                            size: 16,
                                          ),
                                          label: Text(
                                            tr('שחזור', 'Restore'),
                                            style: TextStyle(
                                              fontFamily: AppFonts.rubik,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.success,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}

// ─── Helper Widgets ───

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.grayText,
        ),
      ),
    );
  }
}

/// What this page is, since it is not a copy of anything: every removal in
/// the panel marks the row in its own table, and this lists those rows.
class _HowThisWorksNote extends StatelessWidget {
  const _HowThisWorksNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminContentBg,
        border: Border.all(color: AppColors.adminCardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.adminTextLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('הסרה במסכי הניהול אינה מוחקת: כתבה עוברת לארכיון, עסק מסומן '
              'כסגור, אירוע מבוטל, קטגוריה או בלוק מושבתים. כאן מרוכזים כל '
              'הפריטים האלה, ו"שחזור" מחזיר כל אחד מהם. פריט חוזר למצב שהיה '
              'בו לפני ההסרה כשיומן הפעולות מתעד אותו; אחרת כתבה, עסק, אירוע '
              'והטבה חוזרים כטיוטה, מודעה, ביקורת ותגובה חוזרות לאישור, קמפיין '
              'והסכם חוזרים כמושהים, וכל השאר חוזר כפעיל. שום דבר כאן לא '
              'נמחק אוטומטית.', 'Removing in the admin screens does not delete: an article moves to the archive, a business is marked closed, an event is cancelled, a category or block is disabled. All those items are gathered here, and "Restore" brings each one back. An item returns to the state it was in before removal when the activity log recorded it; otherwise an article, business, event and benefit return as drafts, a listing, review and comment return to pending, a campaign and agreement return as paused, and everything else returns as active. Nothing here is deleted automatically.'),
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 12,
                height: 1.5,
                color: AppColors.adminTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
