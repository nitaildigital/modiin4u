import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/content_language.dart';
import '../../../core/supabase/supabase_config.dart';
import 'auth_provider.dart';

/// One review or comment of the signed-in resident, as "My activity" lists it.
class MyActivityItem {
  final String id;

  /// Where it was written: the business, or the article.
  final String place;
  final String body;

  /// 'approved', 'pending', 'rejected' or 'hidden'.
  final String status;
  final DateTime? createdAt;

  /// Where tapping it leads: the business on that review, or the article.
  final String link;

  /// Reviews only.
  final int? rating;
  final bool answered;

  /// Comments only: an answer under someone's review rather than an article.
  final bool onReview;

  final int likes;
  final int helpful;

  const MyActivityItem({
    required this.id,
    required this.place,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.link,
    this.rating,
    this.answered = false,
    this.onReview = false,
    this.likes = 0,
    this.helpful = 0,
  });
}

class MyActivity {
  final List<MyActivityItem> reviews;
  final List<MyActivityItem> comments;
  const MyActivity({this.reviews = const [], this.comments = const []});
}

String _businessName(Object? embedded) {
  final b = embedded is Map ? embedded : null;
  return b == null ? '' : localName((b['name'] as String?) ?? '', b['name_en'] as String?);
}

/// The resident's reviews (a withdrawn one is gone from here as from the
/// page) and comments, newest first, with what others did with them: likes,
/// "helpful", the business's answer. Row security gives a person all of
/// their own, whatever their state, so a review waiting for approval is
/// here too, marked. Read again each time the page opens.
final myActivityProvider = FutureProvider.autoDispose<MyActivity>((ref) async {
  final me = ref.watch(authProvider.select((u) => u?.id));
  if (me == null) return const MyActivity();
  final db = SupabaseConfig.client;

  final reviewRows = List<Map<String, dynamic>>.from(await db
      .from('reviews')
      .select('id, business_id, rating, title, body, status, created_at, admin_response, businesses(name, name_en)')
      .eq('author_id', me)
      .isFilter('withdrawn_at', null)
      .order('created_at', ascending: false)
      .limit(200));
  final commentRows = List<Map<String, dynamic>>.from(await db
      .from('comments')
      .select('id, entity_type, entity_id, body, status, created_at')
      .eq('author_id', me)
      .order('created_at', ascending: false)
      .limit(200));

  // What the comments were written under: an article's title, or the
  // business whose review they answer.
  final articleIds = {
    for (final c in commentRows)
      if (c['entity_type'] == 'article') c['entity_id'] as String,
  };
  final reviewIds = {
    for (final c in commentRows)
      if (c['entity_type'] == 'review') c['entity_id'] as String,
  };
  final articles = articleIds.isEmpty
      ? const <Map<String, dynamic>>[]
      : List<Map<String, dynamic>>.from(
          await db.from('articles').select('id, title').inFilter('id', articleIds.toList()));
  final parents = reviewIds.isEmpty
      ? const <Map<String, dynamic>>[]
      : List<Map<String, dynamic>>.from(await db
          .from('reviews')
          .select('id, business_id, businesses(name, name_en)')
          .inFilter('id', reviewIds.toList()));
  final articleTitle = {for (final a in articles) a['id'] as String: (a['title'] as String?) ?? ''};
  final parentOf = {for (final p in parents) p['id'] as String: p};

  Future<Map<String, (int, int)>> counts(String type, List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = List<Map<String, dynamic>>.from(
        await db.rpc('reaction_counts', params: {'p_entity_type': type, 'p_ids': ids}));
    return {
      for (final r in rows)
        r['entity_id'] as String: ((r['likes'] as num?)?.toInt() ?? 0, (r['helpful'] as num?)?.toInt() ?? 0),
    };
  }

  final reviewCounts = await counts('review', [for (final r in reviewRows) r['id'] as String]);
  final commentCounts = await counts('comment', [for (final c in commentRows) c['id'] as String]);

  final reviews = [
    for (final r in reviewRows)
      MyActivityItem(
        id: r['id'] as String,
        place: _businessName(r['businesses']),
        body: ((r['body'] as String?)?.trim().isNotEmpty ?? false)
            ? r['body'] as String
            : (r['title'] as String?) ?? '',
        status: (r['status'] as String?) ?? 'pending',
        createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '')?.toLocal(),
        link: '/business/${r['business_id']}?review=${r['id']}',
        rating: (r['rating'] as num?)?.toInt(),
        answered: ((r['admin_response'] as String?) ?? '').trim().isNotEmpty,
        likes: reviewCounts[r['id']]?.$1 ?? 0,
        helpful: reviewCounts[r['id']]?.$2 ?? 0,
      ),
  ];

  final comments = <MyActivityItem>[];
  for (final c in commentRows) {
    final id = c['id'] as String;
    final onReview = c['entity_type'] == 'review';
    final String place;
    final String link;
    if (onReview) {
      final parent = parentOf[c['entity_id']];
      // The review it answered is no longer shown (taken back or hidden):
      // nothing to open it on.
      if (parent == null) continue;
      place = _businessName(parent['businesses']);
      link = '/business/${parent['business_id']}?review=${parent['id']}&reply=$id';
    } else {
      place = articleTitle[c['entity_id']] ?? '';
      link = '/article/${c['entity_id']}';
    }
    comments.add(MyActivityItem(
      id: id,
      place: place,
      body: (c['body'] as String?) ?? '',
      status: (c['status'] as String?) ?? 'pending',
      createdAt: DateTime.tryParse((c['created_at'] as String?) ?? '')?.toLocal(),
      link: link,
      onReview: onReview,
      likes: commentCounts[id]?.$1 ?? 0,
    ));
  }

  return MyActivity(reviews: reviews, comments: comments);
});
