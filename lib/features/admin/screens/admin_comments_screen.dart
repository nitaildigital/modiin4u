import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_comments_provider.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// The titles of the articles the listed comments are on, by id — one read
/// for the whole list, keyed by the ids sorted and joined, so a comment reads
/// as being on a story the moderator can recognise.
final _articleTitlesProvider =
    FutureProvider.autoDispose.family<Map<String, String>, String>((ref, joined) async {
      final rows = await SupabaseConfig.client
          .from('articles')
          .select('id, title')
          .inFilter('id', joined.split(','));
      return {
        for (final r in List<Map<String, dynamic>>.from(rows))
          r['id'] as String: (r['title'] as String? ?? '').trim(),
      };
    });

class AdminCommentsScreen extends ConsumerStatefulWidget {
  const AdminCommentsScreen({super.key});
  @override
  ConsumerState<AdminCommentsScreen> createState() =>
      _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends ConsumerState<AdminCommentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = '';
  String _entityFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setStatus(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminCommentsProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  void _toggleEntity(String type) {
    setState(() => _entityFilter = _entityFilter == type ? '' : type);
    ref
        .read(adminCommentsProvider.notifier)
        .setEntityTypeFilter(_entityFilter.isEmpty ? null : _entityFilter);
  }

  /// Runs a moderation action and says what happened — the actions used to
  /// be fired and forgotten, so a refused update looked like a success.
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
    final asyncData = ref.watch(adminCommentsProvider);
    final list = asyncData.valueOrNull;
    final notifier = ref.read(adminCommentsProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;
    final articleIds = {
      for (final c in list ?? const <Map<String, dynamic>>[])
        if (c['entity_type'] == 'article' && c['entity_id'] is String) c['entity_id'] as String,
    }.toList()
      ..sort();
    final articleTitles = articleIds.isEmpty
        ? const <String, String>{}
        : ref.watch(_articleTitlesProvider(articleIds.join(','))).valueOrNull ??
            const <String, String>{};

    return Column(
      children: [
        // ─── Stats ───
        if (list != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                _StatChip(
                  tr('ממתינות', 'Pending'),
                  '${list.where((c) => c['status'] == 'pending').length}',
                  AppColors.gold,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  tr('מאושרות', 'Approved'),
                  '${list.where((c) => c['status'] == 'approved').length}',
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                // `report_count` is how many residents reported the comment.
                _StatChip(
                  tr('דווחו', 'Reported'),
                  '${list.where((c) => ((c['report_count'] as num?) ?? 0) > 0).length}',
                  AppColors.error,
                ),
                const SizedBox(width: 12),
                _StatChip(tr('סה״כ', 'Total'), '${list.length}', AppColors.midBlue),
              ],
            ),
          ),

        // Nothing creates comments yet; an empty list should not read as
        // "all caught up".
        const _NothingWritesThisNote(),

        // ─── Toolbar ───
        AdminListToolbar(
          search: AdminSearchField(
            controller: _searchController,
            width: isWide ? 280 : 180,
            hint: tr('חיפוש תגובה...', 'Search comments...'),
            onChanged: (v) => notifier.setSearch(v.isEmpty ? null : v),
          ),
          filters: [
            AdminFilterChip(tr('הכל', 'All'), _statusFilter.isEmpty, () => _setStatus('')),
            AdminFilterChip(
              tr('ממתין', 'Pending'),
              _statusFilter == 'pending',
              () => _setStatus('pending'),
            ),
            AdminFilterChip(
              tr('מאושר', 'Approved'),
              _statusFilter == 'approved',
              () => _setStatus('approved'),
            ),
            AdminFilterChip(
              tr('נדחה', 'Rejected'),
              _statusFilter == 'rejected',
              () => _setStatus('rejected'),
            ),
            AdminFilterChip(
              tr('מוסתר', 'Hidden'),
              _statusFilter == 'hidden',
              () => _setStatus('hidden'),
            ),
            if (isWide) ...[
              const SizedBox(width: 12),
              // Residents' replies to reviews, from the business pages.
              AdminFilterChip(
                tr('ביקורות', 'Reviews'),
                _entityFilter == 'review',
                () => _toggleEntity('review'),
              ),
              AdminFilterChip(
                tr('עסקים', 'Businesses'),
                _entityFilter == 'business',
                () => _toggleEntity('business'),
              ),
              AdminFilterChip(
                tr('כתבות', 'Articles'),
                _entityFilter == 'article',
                () => _toggleEntity('article'),
              ),
              AdminFilterChip(
                tr('אירועים', 'Events'),
                _entityFilter == 'event',
                () => _toggleEntity('event'),
              ),
            ],
          ],
          count: list != null ? tr('${list.length} תגובות', '${list.length} comments') : null,
        ),

        // ─── List ───
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
                        Icons.forum_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין תגובות', 'No comments'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: list.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) {
                  final c = list[i];
                  final id = c['id'] as String;
                  final status = c['status'] as String? ?? 'pending';
                  final reports = (c['report_count'] as num?)?.toInt() ?? 0;
                  final author = c['profiles'] is Map
                      ? ((c['profiles'] as Map)['full_name'] as String? ?? '')
                            .trim()
                      : '';

                  return Container(
                    color: reports > 0
                        ? AppColors.error.withValues(alpha: 0.04)
                        : (status == 'pending'
                              ? AppColors.gold.withValues(alpha: 0.04)
                              : null),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.midBlue.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            author.isEmpty ? '?' : author.characters.first,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    author.isEmpty ? tr('ללא שם', 'Untitled') : author,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Takes the room the status leaves, as an
                                  // article's title can be long.
                                  Expanded(
                                    child: Text(
                                      _entityLabel(c, articleTitles),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 11,
                                        color: AppColors.grayLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusPill(status),
                                  if (reports > 0) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.flag,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    Text(
                                      '$reports',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c['body'] as String? ?? '',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 13,
                                  color: AppColors.navy,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    _shortDate(
                                      c['created_at'] as String? ?? '',
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 11,
                                      color: AppColors.grayLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (status != 'approved')
                                    _ActionButton(
                                      tr('אשר', 'Confirm'),
                                      Icons.check,
                                      AppColors.success,
                                      () => _run(
                                        () => notifier.approve(id),
                                        tr('התגובה אושרה', 'Comment approved'),
                                      ),
                                    ),
                                  if (status == 'pending')
                                    _ActionButton(
                                      tr('דחה', 'Reject'),
                                      Icons.close,
                                      AppColors.error,
                                      () => _run(
                                        () => notifier.reject(id),
                                        tr('התגובה נדחתה — אפשר להחזיר אותה מסל המחזור', 'Comment rejected — you can bring it back from the trash'),
                                      ),
                                    ),
                                  if (status == 'approved')
                                    _ActionButton(
                                      tr('הסתר', 'Hide'),
                                      Icons.visibility_off,
                                      AppColors.midBlue,
                                      () => _run(
                                        () => notifier.hide(id),
                                        tr('התגובה הוסתרה — אפשר להחזיר אותה מסל המחזור', 'Comment hidden — you can bring it back from the trash'),
                                      ),
                                    ),
                                ],
                              ),
                            ],
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

  /// Where the comment was left. An article's comment names the article,
  /// and says when it answers another comment there.
  String _entityLabel(Map<String, dynamic> c, Map<String, String> articleTitles) {
    final t = c['entity_type'] as String? ?? '';
    if (t == 'article') {
      final title = articleTitles[c['entity_id']] ?? '';
      final kind = c['parent_id'] != null
          ? tr('תגובה בכתבה', 'Reply on an article')
          : tr('כתבה', 'Article');
      return title.isEmpty ? kind : '$kind · $title';
    }
    return switch (t) {
      'review' => tr('תגובה לביקורת', 'Reply to the review'),
      'business' => tr('על עסק', 'About a business'),
      'event' => tr('על אירוע', 'About an event'),
      _ => t,
    };
  }
  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton(this.label, this.icon, this.color, this.onPressed);
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 14),
    label: Text(
      label,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
    ),
    style: TextButton.styleFrom(
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
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
              // Brought up to date with what the database does: replies to
              // reviews (00039, live at once since 00063) and comments on
              // articles (00071) wait only when Settings ask for approval.
              tr('תושבים כותבים מהאפליקציה תגובות לביקורות ותגובות לכתבות. '
              'תגובה עולה מיד, אלא אם בהגדרות נקבע שתגובות ממתינות לאישור — '
              'אז היא מופיעה כאן כממתינה.', 'Residents reply to reviews and comment on articles from the app. A comment goes up at once unless Settings ask for approval — then it waits here as pending.'),
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final (label, color) = switch (status) {
      'approved' => (tr('מאושר', 'Approved'), k.success),
      'pending' => (tr('ממתין', 'Pending'), k.warning),
      'rejected' => (tr('נדחה', 'Rejected'), k.danger),
      'hidden' => (tr('מוסתר', 'Hidden'), k.muted),
      _ => (status, k.muted),
    };
    return AdminPill(label, color);
  }
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
