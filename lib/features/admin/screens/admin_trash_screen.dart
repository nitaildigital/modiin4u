import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_trash_provider.dart';

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
            '"${_title(item)}" שוחזר — ${trashStateLabels[target] ?? target}',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'השחזור נכשל: $e',
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
              Icon(Icons.restore_from_trash, size: 20, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                'סל מחזור',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        'הכל',
                        _tableFilter.isEmpty,
                        () => _setTable(''),
                      ),
                      // Once filtered, the other tables were not read, so
                      // every chip stays offered; unfiltered, only the tables
                      // that have something removed.
                      for (final s in trashSources)
                        if (_tableFilter.isNotEmpty ||
                            (byTable[s.table] ?? 0) > 0)
                          _FilterChip(
                            byTable[s.table] == null
                                ? s.kind
                                : '${s.kind} (${byTable[s.table]})',
                            _tableFilter == s.table,
                            () => _setTable(s.table),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (list != null)
                Text(
                  '${list.length} פריטים',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'רענון',
                onPressed: notifier.load,
              ),
            ],
          ),
        ),

        // Tables that could not be read are named, not passed off as empty.
        if (asyncData.hasValue && notifier.failures.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppColors.error.withValues(alpha: 0.06),
            child: Text(
              'לא ניתן היה לקרוא: ${notifier.failures.keys.map((t) => trashSources.firstWhere((s) => s.table == t).kind).join(', ')}',
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
                'שגיאה: $e',
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
                        'אין פריטים שהוסרו',
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
                        _Col('פריט', flex: 4),
                        _Col('סוג', flex: 2),
                        _Col('מצב', flex: 1),
                        if (isWide) _Col('שינוי אחרון', flex: 2),
                        const SizedBox(width: 96),
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
                                  child: _KindPill(t.source.kind),
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
                                width: 96,
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
                                            'שחזור',
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
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.grayText,
            ),
          ),
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

class _KindPill extends StatelessWidget {
  final String kind;
  const _KindPill(this.kind);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        kind,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.turquoise,
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
              'הסרה במסכי הניהול אינה מוחקת: כתבה עוברת לארכיון, עסק מסומן '
              'כסגור, אירוע מבוטל, קטגוריה או בלוק מושבתים. כאן מרוכזים כל '
              'הפריטים האלה, ו"שחזור" מחזיר כל אחד מהם. פריט חוזר למצב שהיה '
              'בו לפני ההסרה כשיומן הפעולות מתעד אותו; אחרת כתבה, עסק, אירוע '
              'והטבה חוזרים כטיוטה, מודעה, ביקורת ותגובה חוזרות לאישור, קמפיין '
              'והסכם חוזרים כמושהים, וכל השאר חוזר כפעיל. שום דבר כאן לא '
              'נמחק אוטומטית.',
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
