import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_reviews_provider.dart';
import '../ui/admin_kit.dart';
import '../admin_language.dart';

/// Whether the panel offers its own reply to a review. Off: see the note
/// at the reply button.
const _repliesEnabled = false;

/// Reviews of businesses: approve, turn down, hide, and reply.
///
/// The reviewer is named as the website names them — from the review's own
/// `author_name` and `author_avatar_url` — and each row shows what the
/// business page shows: the stars, the title, the text and the date.
class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String _statusFilter = '';
  final _search = TextEditingController();
  Future<void>? _pendingSearch;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setStatus(String status) {
    setState(() => _statusFilter = status);
    ref
        .read(adminReviewListProvider.notifier)
        .setStatusFilter(status.isEmpty ? null : status);
  }

  void _onSearch(String v) {
    _pendingSearch?.ignore();
    _pendingSearch = Future.delayed(const Duration(milliseconds: 400)).then((
      _,
    ) {
      if (!mounted) return;
      ref
          .read(adminReviewListProvider.notifier)
          .setSearch(v.trim().isEmpty ? null : v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncReviews = ref.watch(adminReviewListProvider);
    final notifier = ref.watch(adminReviewListProvider.notifier);

    return Column(
      children: [
        AdminListToolbar(
          search: AdminSearchField(
            controller: _search,
            onChanged: _onSearch,
            width: 260,
            hint: tr('חיפוש לפי שם או טקסט...', 'Search by name or text...'),
          ),
          filters: [
            for (final (value, label) in [
              ('', tr('הכל', 'All')),
              ('pending', tr('ממתין', 'Pending')),
              ('approved', tr('מאושר', 'Approved')),
              ('rejected', tr('נדחה', 'Rejected')),
              ('hidden', tr('מוסתר', 'Hidden')),
            ])
              AdminFilterChip(
                label,
                _statusFilter == value,
                () => _setStatus(value),
              ),
          ],
          // Nothing is printed while the count is unknown, rather than a
          // zero that reads as "no reviews". `hasValue`, not
          // `whenData(...).value`: the latter rethrows on a failed load
          // and greys the whole section instead of letting the list below
          // show the error and a retry.
          count: asyncReviews.hasValue
              ? (notifier.totalCount == 0
                    ? tr('אין ביקורות', 'No reviews')
                    : tr('${notifier.totalCount} ביקורות', '${notifier.totalCount} reviews'))
              : null,
        ),
        Expanded(
          child: asyncReviews.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              icon: IconsaxPlusLinear.danger,
              message: tr('לא ניתן לטעון את הביקורות', 'Could not load the reviews'),
              detail: '$e',
              onRetry: () => ref.read(adminReviewListProvider.notifier).load(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return _Message(
                  icon: IconsaxPlusLinear.star,
                  message: tr('אין ביקורות', 'No reviews'),
                  detail: tr('ביקורות שתושבים יכתבו על עסקים יופיעו כאן.', 'Reviews residents write about businesses appear here.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: rows.length + (notifier.hasMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.adminCardBorder),
                itemBuilder: (context, i) => i == rows.length
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: notifier.loadMore,
                            child: Text(
                              tr('טען עוד', 'Load more'),
                              style: TextStyle(fontFamily: AppFonts.inter),
                            ),
                          ),
                        ),
                      )
                    : _reviewTile(rows[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final id = r['id'] as String;
    final status = r['status'] as String? ?? 'pending';
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final name = (r['author_name'] as String?)?.trim() ?? '';
    final avatar = r['author_avatar_url'] as String?;
    final business = (r['businesses'] as Map?)?['name'] as String?;
    final title = (r['title'] as String?)?.trim() ?? '';
    final body = (r['body'] as String?)?.trim() ?? '';
    final response = (r['admin_response'] as String?)?.trim() ?? '';
    final created = DateTime.tryParse(r['created_at'] as String? ?? '');
    final responded = DateTime.tryParse(r['responded_at'] as String? ?? '');
    final verified = r['is_verified'] as bool? ?? false;

    final small = TextStyle(
      fontFamily: AppFonts.rubik,
      fontSize: 12,
      color: AppColors.adminTextLight,
    );

    return Container(
      color: status == 'pending'
          ? AppColors.gold.withValues(alpha: 0.04)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: avatar != null && avatar.isNotEmpty
                  ? NetworkPhoto(
                      url: avatar,
                      width: 40,
                      height: 40,
                      icon: Icons.person_outline,
                      iconSize: 18,
                    )
                  : Container(
                      color: AppColors.midBlue.withValues(alpha: 0.12),
                      alignment: Alignment.center,
                      child: Text(
                        name.isEmpty ? '?' : name.characters.first,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midBlue,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      // The website prints "תושב" for a review with no name;
                      // the panel says plainly that the name is missing.
                      name.isEmpty ? tr('ללא שם', 'Untitled') : name,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.adminTextDark,
                      ),
                    ),
                    Text(
                      tr('— ${business ?? 'עסק לא ידוע'}', '— ${business ?? 'unknown business'}'),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 13,
                        color: AppColors.adminTextMedium,
                      ),
                    ),
                    _Stars(rating),
                    AdminPill(_statusLabel(status), _statusColor(status)),
                    if (verified) AdminPill(tr('מאומת', 'Verified'), AdminKit.of(context).accent),
                  ],
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.adminTextDark,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  body.isEmpty ? tr('דירוג בלבד, ללא טקסט', 'Rating only, no text') : body,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    height: 1.5,
                    color: body.isEmpty
                        ? AppColors.adminTextLight
                        : AppColors.grayText,
                  ),
                ),
                if (created != null) ...[
                  const SizedBox(height: 4),
                  Text(_date(created), style: small),
                ],
                if (response.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: BorderDirectional(
                        start: BorderSide(color: AppColors.midBlue, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          responded == null
                              ? tr('תגובה', 'Comment')
                              : tr('תגובה · ${_date(responded)}', 'Reply · ${_date(responded)}'),
                          style: small.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          response,
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.adminTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The client: Modiin4u and the businesses do not reply to
              // reviews at this stage — residents reply to each other, and
              // those replies are moderated under תגובות. The dialog stays
              // for when he wants it back.
              if (_repliesEnabled)
              IconButton(
                tooltip: response.isEmpty ? tr('תגובה', 'Comment') : tr('עריכת התגובה', 'Edit the comment'),
                icon: const Icon(
                  Icons.reply_outlined,
                  color: AppColors.midBlue,
                ),
                onPressed: () => _openReply(id, response),
              ),
              if (status != 'approved')
                IconButton(
                  tooltip: tr('אישור', 'Approve'),
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: _busy.contains(id)
                      ? null
                      : () => _run(
                          () => ref
                              .read(adminReviewListProvider.notifier)
                              .approve(id),
                          tr('הביקורת אושרה', 'Review approved'),
                          id: id,
                        ),
                ),
              if (status != 'rejected')
                IconButton(
                  tooltip: tr('דחייה', 'Reject'),
                  icon: const Icon(Icons.close, color: AppColors.error),
                  onPressed: _busy.contains(id)
                      ? null
                      : () => _run(
                          () => ref
                              .read(adminReviewListProvider.notifier)
                              .reject(id),
                          tr('הביקורת נדחתה', 'Review rejected'),
                          id: id,
                        ),
                ),
              if (status != 'hidden')
                IconButton(
                  tooltip: tr('הסתרה מהאתר', 'Hide from the site'),
                  icon: const Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.adminTextLight,
                  ),
                  onPressed: _busy.contains(id)
                      ? null
                      : () => _run(
                          () => ref
                              .read(adminReviewListProvider.notifier)
                              .hide(id),
                          tr('הביקורת הוסתרה', 'Review hidden'),
                          id: id,
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openReply(String id, String current) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _ReplyDialog(initial: current),
    );
    if (text == null) return;
    await _run(
      () => ref.read(adminReviewListProvider.notifier).reply(id, text),
      text.trim().isEmpty ? tr('התגובה הוסרה', 'Comment removed') : tr('התגובה נשמרה', 'Comment saved'),
    );
  }

  static String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  String _statusLabel(String status) => switch (status) {
    'approved' => tr('מאושר', 'Approved'),
    'pending' => tr('ממתין', 'Pending'),
    'rejected' => tr('נדחה', 'Rejected'),
    'hidden' => tr('מוסתר', 'Hidden'),
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'approved' => AdminKit.of(context).success,
    'pending' => AdminKit.of(context).warning,
    'rejected' => AdminKit.of(context).danger,
    _ => AdminKit.of(context).muted,
  };

  /// Reviews with a write in flight, whose buttons are off until it lands so
  /// a second click cannot race the first.
  final _busy = <String>{};

  Future<void> _run(
    Future<void> Function() write,
    String done, {
    String? id,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    if (id != null) setState(() => _busy.add(id));
    try {
      await write();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(tr('הפעולה נכשלה: $e', 'The action failed: $e')),
        ),
      );
    } finally {
      if (id != null && mounted) setState(() => _busy.remove(id));
    }
  }
}

/// Writing the reply. Returns the text, an empty string to remove the reply,
/// or null when cancelled.
class _ReplyDialog extends StatefulWidget {
  final String initial;
  const _ReplyDialog({required this.initial});

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: adminDir,
      child: AlertDialog(
        title: Text(
          widget.initial.isEmpty ? tr('תגובה לביקורת', 'Reply to the review') : tr('עריכת התגובה', 'Edit the comment'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: _text,
            autofocus: true,
            maxLines: 6,
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ביטול', 'Cancel'), style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
          if (widget.initial.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(
                tr('מחיקת התגובה', 'Delete the comment'),
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                ),
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _text.text),
            child: Text(tr('שמירה', 'Save'), style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars(this.rating);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 15,
            color: i <= rating ? AppColors.gold : AppColors.adminTextLight,
          ),
      ],
    );
  }
}

/// An empty list or a failed load, said plainly.
class _Message extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  const _Message({
    required this.icon,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: AppColors.adminTextLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 15,
                color: AppColors.adminTextMedium,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: AppColors.adminTextLight,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  tr('נסה שוב', 'Try again'),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
