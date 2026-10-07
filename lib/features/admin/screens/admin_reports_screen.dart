import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_reports_provider.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/supabase/supabase_config.dart';

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
            tr('הפעולה נכשלה: $e', 'The action failed: $e'),
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
                    _StatChip(tr('פתוחים', 'Open'), '$open', AppColors.error),
                    const SizedBox(width: 12),
                    _StatChip(tr('בטיפול', 'In progress'), '$investigating', AppColors.gold),
                    const SizedBox(width: 12),
                    _StatChip(tr('נפתרו', 'Resolved'), '$resolved', AppColors.success),
                    const SizedBox(width: 12),
                    _StatChip(tr('סה״כ', 'Total'), '${list.length}', AppColors.midBlue),
                  ],
                ),
              );
            },
          ),

        // Nothing files reports yet; an empty list should not read as
        // "nothing wrong".
        const _WhereReportsComeFromNote(),

        // ─── Toolbar ───
        AdminListToolbar(
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _statusFilter.isEmpty, () => _setStatus('')),
            AdminFilterChip(
              tr('פתוח', 'Open'),
              _statusFilter == 'open',
              () => _setStatus('open'),
            ),
            AdminFilterChip(
              tr('בטיפול', 'In progress'),
              _statusFilter == 'reviewed',
              () => _setStatus('reviewed'),
            ),
            AdminFilterChip(
              tr('נפתר', 'Resolved'),
              _statusFilter == 'resolved',
              () => _setStatus('resolved'),
            ),
            AdminFilterChip(
              tr('נדחה', 'Rejected'),
              _statusFilter == 'dismissed',
              () => _setStatus('dismissed'),
            ),
            if (isWide) ...[
              const SizedBox(width: 16),
              AdminFilterChip(
                tr('עסקים', 'Businesses'),
                _entityFilter == 'business',
                () => _toggleEntity('business'),
              ),
              AdminFilterChip(
                tr('ביקורות', 'Reviews'),
                _entityFilter == 'review',
                () => _toggleEntity('review'),
              ),
              AdminFilterChip(
                tr('נכסים', 'Listings'),
                _entityFilter == 'listing',
                () => _toggleEntity('listing'),
              ),
              AdminFilterChip(
                tr('תגובות', 'Comments'),
                _entityFilter == 'comment',
                () => _toggleEntity('comment'),
              ),
              AdminFilterChip(
                tr('משתמשים', 'Users'),
                _entityFilter == 'user',
                () => _toggleEntity('user'),
              ),
            ],
          ],
          count: loaded != null ? tr('${loaded.length} דיווחים', '${loaded.length} reports') : null,
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
                        Icons.flag_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין דיווחים', 'No reports'),
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
                        _Col(tr('סיבה', 'Reason'), flex: 2),
                        _Col(tr('פריט', 'Item'), flex: 3),
                        _Col(tr('מדווח', 'Reporter'), flex: 2),
                        _Col(tr('סטטוס', 'Status'), flex: 1),
                        if (isWide) _Col(tr('תאריך', 'Date'), flex: 1),
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
                              // Five 40px buttons at most (Open, in
                              // progress, hide, resolve, reject); narrower,
                              // the last hung outside and took no taps.
                              SizedBox(
                                width: 208,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // What was reported, on the site, in a
                                    // new tab: the row says only its type.
                                    _IconAction(
                                      Icons.open_in_new,
                                      AppColors.midBlue,
                                      tr('פתח את מה שדווח', 'Open what was reported'),
                                      () => _openReported(
                                        r['entity_type'] as String? ?? '',
                                        r['entity_id'] as String? ?? '',
                                      ),
                                    ),
                                    if (status == 'open')
                                      _IconAction(
                                        Icons.search,
                                        AppColors.gold,
                                        tr('סמן בטיפול', 'Mark in progress'),
                                        () => _run(
                                          () => notifier.markReviewed(id),
                                          tr('הדיווח סומן בטיפול', 'Report marked in progress'),
                                        ),
                                      ),
                                    if ((status == 'open' ||
                                            status == 'reviewed') &&
                                        (r['entity_type'] == 'review' ||
                                            r['entity_type'] == 'comment'))
                                      _IconAction(
                                        Icons.visibility_off_outlined,
                                        AppColors.error,
                                        tr('הסתר וסגור את הדיווח', 'Hide it and close the report'),
                                        () => _run(
                                          () => notifier.hideAndResolve(
                                            id,
                                            r['entity_type'] as String,
                                            r['entity_id'] as String,
                                          ),
                                          tr('הוסתר, והדיווח נסגר', 'Hidden, and the report closed'),
                                        ),
                                      ),
                                    if (status == 'open' ||
                                        status == 'reviewed') ...[
                                      _IconAction(
                                        Icons.check,
                                        AppColors.success,
                                        tr('סמן כנפתר', 'Mark as resolved'),
                                        () => _run(
                                          () => notifier.resolve(id, tr('טופל', 'Resolved')),
                                          tr('הדיווח נסגר כנפתר', 'Report closed as resolved'),
                                        ),
                                      ),
                                      _IconAction(
                                        Icons.close,
                                        AppColors.grayLight,
                                        tr('דחה', 'Reject'),
                                        () => _run(
                                          () => notifier.dismiss(id),
                                          tr('הדיווח נדחה', 'Report rejected'),
                                        ),
                                      ),
                                    ],
                                    if (status == 'resolved' ||
                                        status == 'dismissed')
                                      _IconAction(
                                        Icons.undo,
                                        AppColors.midBlue,
                                        tr('פתח מחדש', 'Reopen'),
                                        () => _run(
                                          () => notifier.reopen(id),
                                          tr('הדיווח נפתח מחדש', 'Report reopened'),
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
    'spam' => tr('ספאם', 'Spam'),
    'offensive' => tr('תוכן פוגעני', 'Offensive content'),
    'fake' => tr('תוכן מזויף', 'Fake content'),
    'personal_info' => tr('מידע אישי', 'Personal information'),
    'harassment' => tr('הטרדה', 'Harassment'),
    'other' => tr('אחר', 'Other'),
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
  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: TextStyle(fontFamily: AppFonts.rubik))),
  );

  /// The reported item's page on the site. A review and a reply to one
  /// live on their business's page, so that is looked up first.
  Future<void> _openReported(String type, String id) async {
    try {
      final client = SupabaseConfig.client;
      String? path;
      switch (type) {
        case 'business':
          path = '/business/$id';
        case 'listing':
          path = '/listing/$id';
        case 'article':
          path = '/article/$id';
        case 'review' || 'comment':
          var reviewId = id;
          if (type == 'comment') {
            final c = await client.from('comments').select('entity_id').eq('id', id).maybeSingle();
            reviewId = c?['entity_id'] as String? ?? '';
          }
          final r = await client.from('reviews').select('business_id').eq('id', reviewId).maybeSingle();
          final business = r?['business_id'] as String?;
          if (business != null) path = '/business/$business';
      }
      if (path == null) {
        _toast(tr('הפריט כבר לא קיים', 'The item no longer exists'));
        return;
      }
      await launchUrl(Uri.base.resolve(path), webOnlyWindowName: '_blank');
    } catch (_) {
      _toast(tr('לא ניתן היה לפתוח', 'Could not open it'));
    }
  }

  String _entityLabel(String t) => switch (t) {
    'business' => tr('עסק', 'Business'),
    'listing' => tr('נכס', 'Listing'),
    'review' => tr('ביקורת', 'Review'),
    'comment' => tr('תגובה', 'Comment'),
    'article' => tr('כתבה', 'Article'),
    'user' => tr('משתמש', 'User'),
    _ => t,
  };
  IconData _entityIcon(String t) => switch (t) {
    'business' => Icons.store,
    'listing' => Icons.home_work_outlined,
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
    final k = AdminKit.of(context);
    final (label, color) = switch (status) {
      'open' => (tr('פתוח', 'Open'), k.danger),
      'reviewed' => (tr('בטיפול', 'In progress'), k.warning),
      'resolved' => (tr('נפתר', 'Resolved'), k.success),
      'dismissed' => (tr('נדחה', 'Rejected'), k.muted),
      _ => (status, k.muted),
    };
    return AdminPill(label, color);
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

/// Where the reports come from, so an empty list is not a mystery.
class _WhereReportsComeFromNote extends StatelessWidget {
  const _WhereReportsComeFromNote();

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
              tr('הדיווחים מגיעים מהאפליקציה: תושבים מדווחים על ביקורת, עסק או פארק, '
              'או מודעת נדל״ן. לאתר אין חשבונות תושבים, ולכן אין ממנו דיווחים.',
              'Reports come from the app: residents report a review, a business or park, or a listing. The website has no resident accounts, so none come from it.'),
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
