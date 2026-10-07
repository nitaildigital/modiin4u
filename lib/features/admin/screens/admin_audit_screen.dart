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
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final e = list[i];
                  final action = e['action'] as String? ?? '';
                  final after = e['after_data'] is Map
                      ? e['after_data'] as Map
                      : const {};
                  final before = e['before_data'] is Map
                      ? e['before_data'] as Map
                      : const {};
                  final admin = e['admin_users'] is Map
                      ? e['admin_users'] as Map
                      : const {};
                  final adminName = admin['profiles'] is Map
                      ? ((admin['profiles'] as Map)['full_name'] as String? ??
                                '')
                            .trim()
                      : '';
                  final label = (after['label'] as String? ?? '').trim();
                  final summary = _summary(after, before);
                  final isLast = i == list.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline rail
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _actionColor(action),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.border.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _actionIcon(action),
                                        size: 16,
                                        color: _actionColor(action),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _actionLabel(action),
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _actionColor(action),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _entityLabel(
                                            e['entity_type'] as String? ?? '',
                                          ),
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 10,
                                            color: AppColors.grayText,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _timeAgo(
                                          e['created_at'] as String? ?? '',
                                        ),
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 11,
                                          color: AppColors.grayLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label.isEmpty
                                        ? (e['entity_id'] as String? ?? '')
                                        : label,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.midBlue
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          adminName.isEmpty
                                              ? '?'
                                              : adminName.characters.first,
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.midBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        adminName.isEmpty
                                            ? tr('מנהל שהוסר', 'A removed admin')
                                            : adminName,
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 12,
                                          color: AppColors.grayText,
                                        ),
                                      ),
                                      if (isWide &&
                                          e['ip_address'] != null) ...[
                                        const SizedBox(width: 12),
                                        Text(
                                          e['ip_address'] as String,
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 11,
                                            color: AppColors.grayLight,
                                            fontFeatures: [
                                              const FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (summary.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        summary,
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 11,
                                          height: 1.5,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
