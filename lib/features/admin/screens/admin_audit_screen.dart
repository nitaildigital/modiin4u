import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_audit_provider.dart';
import '../providers/admin_trash_provider.dart' show trashStateLabels;

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
              SizedBox(
                width: isWide ? 280 : 180,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש ביומן...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grayLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.turquoise),
                    ),
                  ),
                  onChanged: (v) => ref
                      .read(adminAuditProvider.notifier)
                      .setSearch(v.isEmpty ? null : v),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip('הכל', _actionFilter.isEmpty, () => _setAction('')),
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
                _FilterChip(
                  auditActionLabels[action]!,
                  _actionFilter == action,
                  () => _setAction(action),
                ),
              const Spacer(),
              if (loaded != null)
                Text(
                  '${loaded.length} רשומות',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
            ],
          ),
        ),

        // ─── Timeline ───
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
                        Icons.history_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'אין רשומות ביומן',
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
                                        backgroundColor: AppColors.turquoise
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          adminName.isEmpty
                                              ? '?'
                                              : adminName.characters.first,
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.turquoise,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        adminName.isEmpty
                                            ? 'מנהל שהוסר'
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
    'update' => AppColors.turquoise,
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
        'status' => 'סטטוס',
        'is_active' => 'פעיל',
        _ => 'מפורסם',
      };
      parts.add(from == null ? '$name: $to' : '$name: $from ← $to');
    }
    final fields = after['fields'] is List
        ? [
            for (final f in after['fields'] as List)
              if (!const {'status', 'is_active', 'published'}.contains(f)) '$f',
          ]
        : const <String>[];
    if (fields.isNotEmpty) parts.add('שדות: ${fields.join(', ')}');
    return parts.join(' · ');
  }

  // In Hebrew, so the arrow between old and new reads right to left with
  // the rest of the line; a Latin run would lay it out backwards.
  String _value(Object? v) => switch (v) {
    true => 'כן',
    false => 'לא',
    null => '—',
    _ => trashStateLabels['$v'] ?? '$v',
  };

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
      if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
      if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
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
