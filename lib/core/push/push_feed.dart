import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_config.dart';
import 'push_service.dart';

/// One notification as the bell lists it.
class PushFeedItem {
  final String id;
  final String title;
  final String body;
  final String? titleEn;
  final String? bodyEn;
  final String? imageUrl;
  final String? link;
  final DateTime sentAt;

  const PushFeedItem({
    required this.id,
    required this.title,
    required this.body,
    this.titleEn,
    this.bodyEn,
    this.imageUrl,
    this.link,
    required this.sentAt,
  });

  factory PushFeedItem.fromJson(Map<String, dynamic> j) => PushFeedItem(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    titleEn: j['title_en'] as String?,
    bodyEn: j['body_en'] as String?,
    imageUrl: j['image_url'] as String?,
    link: j['deep_link'] as String?,
    sentAt: DateTime.parse(j['sent_at'] as String).toLocal(),
  );

  /// The same choice the sender made for a device in this language.
  String titleFor(String languageCode) =>
      languageCode == 'en' && (titleEn?.trim().isNotEmpty ?? false)
      ? titleEn!
      : title;
  String bodyFor(String languageCode) =>
      languageCode == 'en' && (bodyEn?.trim().isNotEmpty ?? false)
      ? bodyEn!
      : body;
}

/// What was sent in the last 60 days that this device would have received
/// (`push_feed`, migration 00045). A device that never registered — Firebase
/// not set up, or a browser that has not allowed notifications — sees what
/// went to everyone or to a topic.
final pushFeedProvider = FutureProvider.autoDispose<List<PushFeedItem>>((
  ref,
) async {
  final token = await ref.read(pushServiceProvider).token();
  final rows = await SupabaseConfig.client.rpc(
    'push_feed',
    params: {'p_token': token, 'p_limit': 50},
  );
  return List<Map<String, dynamic>>.from(
    rows as List,
  ).map(PushFeedItem.fromJson).toList();
});
