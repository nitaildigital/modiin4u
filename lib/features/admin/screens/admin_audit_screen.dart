import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_audit_provider.dart';
import '../providers/admin_trash_provider.dart' show trashStateLabels;
import '../admin_language.dart';
import '../ui/admin_kit.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});
  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final _searchController = TextEditingController();
  String _actionFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setAction(String action) {
    setState(() => _actionFilter = action);
    ref
        .read(adminAuditProvider.notifier)
        .setActionFilter(action.isEmpty ? null : action);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminAuditProvider);
    final loaded = asyncData.valueOrNull;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Toolbar ───
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש ביומן...', 'Search the log...'),
            onChanged: (v) => ref
                .read(adminAuditProvider.notifier)
                .setSearch(v.isEmpty ? null : v),
          ),
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _actionFilter.isEmpty, () => _setAction('')),
            for (final action in const [
              'create',
              'update',
              'publish',
              'archive',
              'approve',
              'reject',
              'restore',
              'delete',
              'view',
            ])
              AdminFilterChip(
                auditActionLabels[action]!,
                _actionFilter == action,
                () => _setAction(action),
              ),
          ],
          count: loaded == null ? null : tr('${loaded.length} רשומות', '${loaded.length} records'),
        ),

        // ─── Timeline ───
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
                        Icons.history_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין רשומות ביומן', 'No log entries'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              // As a table, as the CRM's activity lists: what was done, to
              // what, by whom, when. It was a timeline of cards.
              return Column(
                children: [
                  AdminTableHeader(
                    children: [
                      SizedBox(width: 150, child: Text(tr('פעולה', 'Action'))),
                      Expanded(flex: 5, child: Text(tr('פריט', 'Item'))),
                      if (isWide) Expanded(flex: 2, child: Text(tr('מנהל', 'Admin'))),
                      SizedBox(width: 110, child: Text(tr('מתי', 'When'))),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        final action = e['action'] as String? ?? '';
                        final after = e['after_data'] is Map ? e['after_data'] as Map : const {};
                        final before = e['before_data'] is Map ? e['before_data'] as Map : const {};
                        final admin = e['admin_users'] is Map ? e['admin_users'] as Map : const {};
                        final adminName = admin['profiles'] is Map
                            ? ((admin['profiles'] as Map)['full_name'] as String? ?? '').trim()
                            : '';
                        final label = (after['label'] as String? ?? '').trim();
                        final summary = _summary(after, before);
                        final k = AdminKit.of(context);
                        final who = adminName.isEmpty ? tr('מנהל שהוסר', 'A removed admin') : adminName;

                        return AdminTableRow(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _actionColor(action).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Icon(_actionIcon(action), size: 15, color: _actionColor(action)),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _actionLabel(action),
                                        overflow: TextOverflow.ellipsis,
                                        style: k.label.copyWith(color: _actionColor(action), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          label.isEmpty ? (e['entity_id'] as String? ?? '') : label,
                                          style: k.body.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                        AdminPill(_entityLabel(e['entity_type'] as String? ?? ''), k.inkSoft),
                                      ],
                                    ),
                                    if (!isWide) Text(who, style: k.hint.copyWith(fontSize: 12)),
                                    if (summary.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: k.subtle,
                                          border: Border.all(color: k.border),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(summary, style: k.hint.copyWith(fontSize: 12, height: 1.5, color: k.inkSoft)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isWide)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(who, style: k.body.copyWith(fontSize: 13.5, color: k.inkSoft)),
                                      if (e['ip_address'] != null)
                                        Text(
                                          e['ip_address'] as String,
                                          style: k.hint.copyWith(
                                            fontSize: 11,
                                            fontFeatures: [const FontFeature.tabularFigures()],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  _timeAgo(e['created_at'] as String? ?? ''),
                                  style: k.hint.copyWith(fontSize: 12.5),
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

  Color _actionColor(String a) => switch (a) {
    'create' => AppColors.success,
    'update' => AppColors.midBlue,
    'delete' => AppColors.error,
    'approve' => AppColors.gold,
    'publish' => AppColors.success,
    'restore' => AppColors.success,
    'archive' => AppColors.grayText,
    'reject' => AppColors.error,
    'login' => AppColors.midBlue,
    'view' => AppColors.grayText,
    _ => AppColors.grayLight,
  };
  IconData _actionIcon(String a) => switch (a) {
    'create' => Icons.add_circle_outline,
    'update' => Icons.edit,
    'delete' => Icons.delete_outline,
    'approve' => Icons.check_circle_outline,
    'publish' => Icons.publish,
    'restore' => Icons.restore,
    'archive' => Icons.archive_outlined,
    'reject' => Icons.cancel_outlined,
    'login' => Icons.login,
    'view' => Icons.visibility_outlined,
    _ => Icons.info_outline,
  };
  String _actionLabel(String a) => auditActionLabels[a] ?? a;
  String _entityLabel(String t) => auditTableLabels[t] ?? t;

  /// What changed, in a line: the state columns with their old and new
  /// values, then the names of the other fields written. The log keeps no
  /// other values (see `recordAdminAction`).
  String _summary(Map after, Map before) {
    final parts = <String>[];
    for (final key in const ['status', 'is_active', 'published']) {
      if (!after.containsKey(key)) continue;
      final to = _value(after[key]);
      final from = before.containsKey(key) ? _value(before[key]) : null;
      final name = switch (key) {
        'status' => tr('סטטוס', 'Status'),
        'is_active' => tr('פעיל', 'Active'),
        _ => tr('מפורסם', 'Published'),
      };
      parts.add(from == null ? '$name: $to' : '$name: $from ${tr('←', '→')} $to');
    }
    final fields = after['fields'] is List
        ? [
            for (final f in after['fields'] as List)
              if (!const {'status', 'is_active', 'published'}.contains(f)) '$f',
          ]
        : const <String>[];
    if (fields.isNotEmpty) parts.add(tr('שדות: ${fields.join(', ')}', 'Fields: ${fields.join(', ')}'));
    return parts.join(' · ');
  }

  // In Hebrew, so the arrow between old and new reads right to left with
  // the rest of the line; a Latin run would lay it out backwards.
  String _value(Object? v) => switch (v) {
    true => tr('כן', 'Yes'),
    false => tr('לא', 'No'),
    null => '—',
    _ => trashStateLabels['$v'] ?? '$v',
  };

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return tr('לפני ${diff.inMinutes} דקות', '${diff.inMinutes} minutes ago');
      if (diff.inHours < 24) return tr('לפני ${diff.inHours} שעות', '${diff.inHours} hours ago');
      if (diff.inDays < 7) return tr('לפני ${diff.inDays} ימים', '${diff.inDays} days ago');
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
