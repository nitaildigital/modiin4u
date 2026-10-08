import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/supabase/account_blocked.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/m_kit.dart' show mAgo;
import '../../../shared/widgets/report_sheet.dart';
import '../../../shared/widgets/sign_in_action.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/article_comment.dart';
import '../providers/article_comments_provider.dart';
import 'm_article_parts.dart';

// ═══════════════════════════════════════════════════════════
// Comments under an article, on the phone layout (00071).
//
// They look and behave as the replies under a business's reviews do: the
// writer's initial or photo, name and when, the text, then Reply, Delete on
// one's own and Report on anyone else's. Writing needs an account, and
// accounts are the app's — in a narrow browser the comments are shown and
// the box gives way to a line saying where they are written.
// ═══════════════════════════════════════════════════════════

/// The light blue behind a comment a notification opened, as on the
/// business page. It fades to the same blue made clear.
const _markColor = Color(0xFFE8F1FB);
const _metaGrey = Color(0xFF6D6D6D);

class MArticleComments extends ConsumerStatefulWidget {
  final String articleId;

  /// From a reply notification (`/article/<id>?comment=<id>`): scrolled to
  /// once the comments have loaded, and marked for a few seconds.
  final String? focusCommentId;

  const MArticleComments({
    super.key,
    required this.articleId,
    this.focusCommentId,
  });

  @override
  ConsumerState<MArticleComments> createState() => _MArticleCommentsState();
}

class _MArticleCommentsState extends ConsumerState<MArticleComments> {
  final _controller = TextEditingController();
  final _field = FocusNode();
  final _focusKey = GlobalKey();
  bool _focusScrolled = false;
  bool _focusMarked = true;
  bool _sending = false;

  /// The comment being answered, shown above the box until sent or dropped.
  ArticleComment? _replyTo;

  @override
  void dispose() {
    _controller.dispose();
    _field.dispose();
    super.dispose();
  }

  void _scrollToFocus() {
    if (_focusScrolled) return;
    _focusScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusKey.currentContext;
      // Not on screen yet — the list may be one read before the comment
      // existed. Try again on the next build.
      if (target == null) {
        _focusScrolled = false;
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 0.2,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _focusMarked = false);
      });
    });
  }

  void _toast(String message, {bool error = false, bool signIn = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        action: signIn ? signInAction(context) : null,
        backgroundColor: error ? AppColors.error : AppColors.midBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Back to this page after signing in, as the "Sign in" on a toast does.
  void _signIn() {
    var next = '/article/${widget.articleId}';
    try {
      next = GoRouterState.of(context).uri.toString();
    } catch (_) {}
    context.push('/login?next=${Uri.encodeComponent(next)}');
  }

  void _startReply(ArticleComment c) {
    if (ref.read(authProvider) == null) {
      _toast(L.of(context).signInToReply, error: true, signIn: true);
      return;
    }
    setState(() => _replyTo = c);
    _field.requestFocus();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (ref.read(authProvider) == null) {
      _toast(mTr(context, 'Sign in to comment', 'יש להתחבר כדי להגיב'), error: true, signIn: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final live = await addArticleComment(
        articleId: widget.articleId,
        body: text,
        parentId: _replyTo?.id,
      );
      ref.invalidate(articleCommentsProvider(widget.articleId));
      if (!mounted) return;
      _controller.clear();
      _field.unfocus();
      setState(() {
        _sending = false;
        _replyTo = null;
      });
      // When it waits for the team, saying "sent" alone would leave the
      // writer wondering why nobody else sees it.
      _toast(live
          ? mTr(context, 'Your comment is up', 'התגובה פורסמה')
          : mTr(context, 'Sent — it will appear once the team approves it',
              'נשלחה — התגובה תופיע לאחר אישור הצוות'));
    } catch (e) {
      final blocked = await refusedAsBlocked(e);
      if (!mounted) return;
      setState(() => _sending = false);
      final gone = e is PostgrestException && e.message.contains('article-not-found');
      _toast(
        blocked
            ? accountBlockedMessage(context)
            : gone
                ? mTr(context, 'This article is no longer published.', 'הכתבה כבר לא מפורסמת.')
                : mTr(context, 'Could not send your comment. Please try again.',
                    'לא הצלחנו לשלוח את התגובה. נסו שוב.'),
        error: true,
      );
    }
  }

  Future<void> _delete(ArticleComment c, {required bool hasReplies}) async {
    final l = L.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          mTr(context, 'Delete this comment?', 'למחוק את התגובה?'),
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        // The table drops a comment's replies with it.
        content: hasReplies
            ? Text(
                mTr(context, 'The replies under it will be deleted too.',
                    'גם התגובות אליה יימחקו.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel, style: TextStyle(fontFamily: AppFonts.inter)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.delete, style: TextStyle(fontFamily: AppFonts.inter)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await deleteArticleComment(c.id);
      if (_replyTo?.id == c.id) setState(() => _replyTo = null);
      ref.invalidate(articleCommentsProvider(widget.articleId));
    } catch (_) {
      if (mounted) {
        _toast(mTr(context, 'Could not delete the comment. Please try again.',
            'לא הצלחנו למחוק את התגובה. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(articleCommentsProvider(widget.articleId));
    final threads = value.valueOrNull;

    // The website shows the conversation and nothing when there is none:
    // an empty "Comments (0)" there would invite what it cannot offer.
    if (kIsWeb && (threads == null || threads.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (widget.focusCommentId != null && value.hasValue && !value.isLoading) {
      _scrollToFocus();
    }

    final me = ref.watch(authProvider)?.id;
    final count = threads?.fold<int>(0, (n, t) => n + 1 + t.replies.length);

    // 32 under the story, here rather than at the caller so the gap goes
    // with the section when the website has none to show.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            count == null
                ? mTr(context, 'Comments', 'תגובות')
                : mTr(context, 'Comments ($count)', 'תגובות ($count)'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 19 / 16,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          if (value.isLoading && threads == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
              ),
            )
          else if (value.hasError && threads == null)
            GestureDetector(
              onTap: () => ref.invalidate(articleCommentsProvider(widget.articleId)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  mTr(context, 'Could not load the comments. Tap to try again.',
                      'לא הצלחנו לטעון את התגובות. הקישו כדי לנסות שוב.'),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _metaGrey),
                ),
              ),
            )
          else if (threads!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                mTr(context, 'No comments yet.', 'אין עדיין תגובות.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _metaGrey),
              ),
            )
          else
            for (var i = 0; i < threads.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: i == threads.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: kMNewsBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CommentTile(
                      key: threads[i].comment.id == widget.focusCommentId ? _focusKey : null,
                      comment: threads[i].comment,
                      marked: _focusMarked && threads[i].comment.id == widget.focusCommentId,
                      isMine: threads[i].comment.authorId == me,
                      onReply: () => _startReply(threads[i].comment),
                      onDelete: () => _delete(
                        threads[i].comment,
                        hasReplies: threads[i].replies.isNotEmpty,
                      ),
                    ),
                    for (final r in threads[i].replies)
                      _CommentTile(
                        key: r.id == widget.focusCommentId ? _focusKey : null,
                        comment: r,
                        isReply: true,
                        marked: _focusMarked && r.id == widget.focusCommentId,
                        isMine: r.authorId == me,
                        onReply: () => _startReply(r),
                        // A reply may have replies of its own, drawn beside
                        // it in the thread; the table drops those with it.
                        onDelete: () => _delete(
                          r,
                          hasReplies: threads[i].replies.any((x) => x.parentId == r.id),
                        ),
                      ),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          if (kIsWeb)
            Text(
              mTr(context, 'Comments are written in the Modiin4u app', 'התגובות נכתבות באפליקציה'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _metaGrey),
            )
          else if (me == null)
            MPrimaryButton(
              label: mTr(context, 'Sign in to comment', 'התחברו כדי להגיב'),
              onTap: _signIn,
            )
          else
            _writeBox(),
        ],
      ),
    );
  }

  /// One field and Send, with "Replying to …" over it while answering.
  Widget _writeBox() {
    final reply = _replyTo;
    final canSend = _controller.text.trim().isNotEmpty && !_sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reply != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mTr(
                      context,
                      'Replying to ${reply.authorName.isEmpty ? L.of(context).resident : reply.authorName}',
                      'תגובה ל${reply.authorName.isEmpty ? L.of(context).resident : reply.authorName}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _metaGrey),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _replyTo = null),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 8),
                    child: Icon(Icons.close, size: 16, color: _metaGrey),
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _field,
                minLines: 1,
                maxLines: 5,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                decoration: InputDecoration(
                  hintText: reply == null
                      ? mTr(context, 'Write a comment...', 'כתבו תגובה...')
                      : L.of(context).writeReplyHint,
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: FilledButton(
                onPressed: canSend ? _send : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    // The paper plane points the way the text runs.
                    : Transform.flip(
                        flipX: Directionality.of(context) == TextDirection.rtl,
                        child: const Icon(IconsaxPlusBold.send_1, size: 20, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One comment: the writer's photo or initial, name and when, then the text
/// and its actions. A reply is set in with a rule at its start, as under a
/// review. The writer's own says when it waits or the team took it down.
class _CommentTile extends StatelessWidget {
  final ArticleComment comment;
  final bool isReply;
  final bool isMine;

  /// Highlighted because a notification pointed here.
  final bool marked;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    required this.isMine,
    this.marked = false,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final name = comment.authorName.isEmpty ? l.resident : comment.authorName;
    final avatar = isReply ? 24.0 : 32.0;
    final actionStyle = TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: _metaGrey);

    final actions = <Widget>[
      // Only a live comment can be answered: nobody else sees a waiting one.
      // In the app only, where there are accounts.
      if (!kIsWeb && comment.isApproved)
        _action(l.replyToReview, onReply, actionStyle.copyWith(color: AppColors.midBlue, fontWeight: FontWeight.w500)),
      if (!kIsWeb && isMine) _action(l.delete, onDelete, actionStyle),
      // Comments go live without approval, so anyone can send one that
      // should not be there to the panel's Reports queue.
      if (!kIsWeb && !isMine)
        _action(
          mTr(context, 'Report', 'דיווח'),
          () => showReportSheet(context, entityType: 'comment', entityId: comment.id),
          actionStyle,
        ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      margin: EdgeInsetsDirectional.only(top: isReply ? 10 : 0, start: isReply ? 20 : 0),
      padding: EdgeInsetsDirectional.only(start: isReply ? 10 : 6, end: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: marked ? _markColor : _markColor.withValues(alpha: 0),
        borderRadius: isReply ? null : BorderRadius.circular(8),
        border: isReply
            ? BorderDirectional(
                start: BorderSide(
                  color: marked ? AppColors.midBlue : kMNewsBorder,
                  width: 2,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(comment: comment, size: avatar),
          SizedBox(width: isReply ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: isReply ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      mAgo(context, comment.createdAt),
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: _metaGrey),
                    ),
                    if (!comment.isApproved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          // Taken down is not waiting, so "Pending" would mislead.
                          comment.isRemoved
                              ? mTr(context, 'Hidden by the team', 'הוסתר על ידי הצוות')
                              : l.pendingApproval,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _metaGrey,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    comment.body,
                    // Residents write in Hebrew or English whatever the app is
                    // set to, so the text runs by its own script.
                    textDirection: mArticleDirection(comment.body),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: isReply ? 12 : 13,
                      color: kMNewsBodyText,
                      height: 1.4,
                    ),
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 16, children: actions),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(String label, VoidCallback onTap, TextStyle style) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: style),
      ),
    );
  }
}

/// The writer's profile photo, or the first letter of their name on the
/// light blue the review replies use.
class _Avatar extends StatelessWidget {
  final ArticleComment comment;
  final double size;
  const _Avatar({required this.comment, required this.size});

  @override
  Widget build(BuildContext context) {
    final letter = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFFE8EEF7), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        comment.initial,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.midBlue,
        ),
      ),
    );
    final url = comment.avatarUrl;
    if (url == null) return letter;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => letter,
      ),
    );
  }
}
