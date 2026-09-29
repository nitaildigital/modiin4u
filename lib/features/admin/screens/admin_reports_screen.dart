import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _setStatus(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminReportsProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  void _toggleEntity(String type) {
    setState(() => _entityFilter = _entityFilter == type ? '' : type);
    ref
        .read(adminReportsProvider.notifier)
        .setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter);
  }

  /// Runs an action on a report and says what happened — they used to be
  /// fired and forgotten, so a refused update looked like a success.
  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(
          content: Text(done, style: TextStyle(fontFamily: AppFonts.rubik)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'הפעולה נכשלה: $e',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminReportsProvider);
    final loaded = asyncData.valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats ───
        if (loaded != null)
          Builder(
            builder: (_) {
              final list = loaded;
              final open = list.where((r) => r['status'] == 'open').length;
              final investigating = list
                  .where((r) => r['status'] == 'reviewed')
                  .length;
              final resolved = list
                  .where((r) => r['status'] == 'resolved')
                  .length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                    _StatChip('פתוחים', '$open', AppColors.error),
                    const SizedBox(width: 12),
                    _StatChip('בטיפול', '$investigating', AppColors.gold),
                    const SizedBox(width: 12),
                    _StatChip('נפתרו', '$resolved', AppColors.success),
                    const SizedBox(width: 12),
                    _StatChip('סה״כ', '${list.length}', AppColors.turquoise),
                  ],
                ),
              );
            },
          ),

        // Nothing files reports yet; an empty list should not read as
        // "nothing wrong".
        const _NothingWritesThisNote(),

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
              _FilterChip('הכל', _statusFilter.isEmpty, () => _setStatus('')),
              _FilterChip(
                'פתוח',
                _statusFilter == 'open',
                () => _setStatus('open'),
              ),
              _FilterChip(
                'בטיפול',
                _statusFilter == 'reviewed',
                () => _setStatus('reviewed'),
              ),
              _FilterChip(
                'נפתר',
                _statusFilter == 'resolved',
                () => _setStatus('resolved'),
              ),
              _FilterChip(
                'נדחה',
                _statusFilter == 'dismissed',
                () => _setStatus('dismissed'),
              ),
              if (isWide) ...[
                const SizedBox(width: 16),
                _FilterChip(
                  'עסקים',
                  _entityFilter == 'business',
                  () => _toggleEntity('business'),
                ),
                _FilterChip(
                  'ביקורות',
                  _entityFilter == 'review',
                  () => _toggleEntity('review'),
                ),
                _FilterChip(
                  'תגובות',
                  _entityFilter == 'comment',
                  () => _toggleEntity('comment'),
                ),
                _FilterChip(
                  'משתמשים',
                  _entityFilter == 'user',
                  () => _toggleEntity('user'),
                ),
              ],
              const Spacer(),
              if (loaded != null)
                Text(
                  '${loaded.length} דיווחים',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
            ],
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
                        Icons.flag_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין דיווחים',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
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
                        _Col('סיבה', flex: 2),
                        _Col('פריט', flex: 3),
                        _Col('מדווח', flex: 2),
                        _Col('סטטוס', flex: 1),
                        if (isWide) _Col('תאריך', flex: 1),
                        const SizedBox(width: 110),
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
                        final r = list[i];
                        final id = r['id'] as String;
                        final notifier = ref.read(
                          adminReportsProvider.notifier,
                        );
                        final status = r['status'] as String? ?? 'open';
                        final reporter = r['profiles'] is Map
                            ? ((r['profiles'] as Map)['full_name'] as String? ??
                                  '')
                            : '';
                        final isOpen = status == 'open';
                        final reason = _reasonLabel(
                          r['reason'] as String? ?? '',
                        );
                        final entityIcon = _entityIcon(
                          r['entity_type'] as String? ?? '',
                        );

                        return Container(
                          color: isOpen
                              ? AppColors.error.withValues(alpha: 0.03)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      _reasonIcon(r['reason'] as String? ?? ''),
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        reason,
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Icon(
                                      entityIcon,
                                      size: 14,
                                      color: AppColors.grayLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _entityLabel(
                                              r['entity_type'] as String? ?? '',
                                            ),
                                            style: TextStyle(
                                              fontFamily: AppFonts.rubik,
                                              fontSize: 13,
                                              color: AppColors.navy,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (r['details'] != null &&
                                              (r['details'] as String)
                                                  .isNotEmpty)
                                            Text(
                                              r['details'] as String,
                                              style: TextStyle(
                                                fontFamily: AppFonts.rubik,
                                                fontSize: 11,
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
                              Expanded(
                                flex: 2,
                                child: Text(
                                  reporter,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 13,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _StatusPill(status),
                                ),
                              ),
                              if (isWide)
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _shortDate(
                                      r['created_at'] as String? ?? '',
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 12,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: 110,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (status == 'open')
                                      _IconAction(
                                        Icons.search,
                                        AppColors.gold,
                                        'סמן בטיפול',
                                        () => _run(
                                          () => notifier.markReviewed(id),
                                          'הדיווח סומן בטיפול',
                                        ),
                                      ),
                                    if (status == 'open' ||
                                        status == 'reviewed') ...[
                                      _IconAction(
                                        Icons.check,
                                        AppColors.success,
                                        'סמן כנפתר',
                                        () => _run(
                                          () => notifier.resolve(id, 'טופל'),
                                          'הדיווח נסגר כנפתר',
                                        ),
                                      ),
                                      _IconAction(
                                        Icons.close,
                                        AppColors.grayLight,
                                        'דחה',
                                        () => _run(
                                          () => notifier.dismiss(id),
                                          'הדיווח נדחה',
                                        ),
                                      ),
                                    ],
                                    if (status == 'resolved' ||
                                        status == 'dismissed')
                                      _IconAction(
                                        Icons.undo,
                                        AppColors.turquoise,
                                        'פתח מחדש',
                                        () => _run(
                                          () => notifier.reopen(id),
                                          'הדיווח נפתח מחדש',
                                        ),
                                      ),
                                  ],
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

  // The `report_reason` enum's values (migration 00001).
  String _reasonLabel(String r) => switch (r) {
    'spam' => 'ספאם',
    'offensive' => 'תוכן פוגעני',
    'fake' => 'תוכן מזויף',
    'personal_info' => 'מידע אישי',
    'harassment' => 'הטרדה',
    'other' => 'אחר',
    _ => r,
  };
  IconData _reasonIcon(String r) => switch (r) {
    'spam' => Icons.report,
    'offensive' => Icons.warning,
    'fake' => Icons.error_outline,
    'personal_info' => Icons.privacy_tip_outlined,
    'harassment' => Icons.person_off,
    _ => Icons.flag,
  };
  String _entityLabel(String t) => switch (t) {
    'business' => 'עסק',
    'review' => 'ביקורת',
    'comment' => 'תגובה',
    'article' => 'כתבה',
    'user' => 'משתמש',
    _ => t,
  };
  IconData _entityIcon(String t) => switch (t) {
    'business' => Icons.store,
    'review' => Icons.rate_review,
    'comment' => Icons.comment,
    'article' => Icons.article,
    'user' => Icons.person,
    _ => Icons.help_outline,
  };
  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('פתוח', AppColors.error),
      'reviewed' => ('בטיפול', AppColors.gold),
      'resolved' => ('נפתר', AppColors.success),
      'dismissed' => ('נדחה', AppColors.grayLight),
      _ => (status, AppColors.grayLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  const _IconAction(this.icon, this.color, this.tooltip, this.onPressed);
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 16, color: color),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

/// Why this list is empty, said rather than left to be guessed.
class _NothingWritesThisNote extends StatelessWidget {
  const _NothingWritesThisNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              'עדיין אין באתר או באפליקציה כפתור לדיווח על תוכן, ולכן הרשימה '
              'תתמלא רק כשיתווסף אחד.',
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

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.grayLight,
      ),
    ),
  );
}

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
