import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/article_comment.dart';

/// One article's comments as threads: the comments that opened one, oldest
/// first so the conversation reads down, each with its replies under it.
///
/// Row security returns the approved comments and the signed-in person's own
/// whatever their state; an admin would get everyone's, hence the filter. On
/// the website only the approved ones are shown — writing is the app's, so a
/// browser has nobody's own to show. Dropped when the page closes, so
/// reopening it shows what the panel has approved since.
final articleCommentsProvider =
    FutureProvider.autoDispose.family<List<ArticleCommentThread>, String>((
      ref,
      articleId,
    ) async {
      final me = kIsWeb ? null : ref.watch(authProvider)?.id;
      final query = SupabaseConfig.client
          .from('comments')
          .select(
            'id, entity_id, author_id, parent_id, author_name, '
            'author_avatar_url, body, status, created_at',
          )
          .eq('entity_type', 'article')
          .eq('entity_id', articleId);
      final rows = await (me == null
              ? query.eq('status', 'approved')
              : query.or('status.eq.approved,author_id.eq.$me'))
          .order('created_at', ascending: true);
      return threadArticleComments([
        for (final r in List<Map<String, dynamic>>.from(rows))
          ArticleComment.fromJson(r),
      ]);
    });

/// Groups comments, oldest first, into threads one level deep.
///
/// A reply to a reply is drawn under the comment that opened its thread, so
/// the page never nests further than one step in. A reply whose thread is
/// not shown — the comment it answers was hidden — stands on its own rather
/// than vanishing.
List<ArticleCommentThread> threadArticleComments(List<ArticleComment> all) {
  final byId = {for (final c in all) c.id: c};
  String rootOf(ArticleComment c) {
    var current = c;
    final seen = <String>{};
    while (current.parentId != null &&
        byId.containsKey(current.parentId) &&
        seen.add(current.id)) {
      current = byId[current.parentId]!;
    }
    return current.id;
  }

  final order = <String>[];
  final replies = <String, List<ArticleComment>>{};
  for (final c in all) {
    final root = rootOf(c);
    if (root == c.id) {
      order.add(c.id);
    } else {
      replies.putIfAbsent(root, () => []).add(c);
    }
  }
  return [
    for (final id in order)
      ArticleCommentThread(comment: byId[id]!, replies: replies[id] ?? const []),
  ];
}

/// Writes a comment on an article, or a reply to one of its comments.
///
/// [parentId] is the comment being answered, as written — a reply to a reply
/// included — so the database tells that comment's writer, not the thread's.
/// True when it is live at once; false when the panel's Settings ask for
/// comments to be approved first. The database decides, so the app reports
/// what it did rather than guessing.
Future<bool> addArticleComment({
  required String articleId,
  required String body,
  String? parentId,
}) async {
  final uid = SupabaseConfig.client.auth.currentUser?.id;
  if (uid == null) throw StateError('signed-out');
  final row = await SupabaseConfig.client
      .from('comments')
      .insert({
        'entity_type': 'article',
        'entity_id': articleId,
        'author_id': uid,
        'body': body.trim(),
        'parent_id': ?parentId,
      })
      .select('status')
      .single();
  return row['status'] == 'approved';
}

/// Removes the signed-in person's own comment. Its replies go with it — the
/// table cascades — which the page warns of before asking.
Future<void> deleteArticleComment(String commentId) async {
  await SupabaseConfig.client.from('comments').delete().eq('id', commentId);
}
