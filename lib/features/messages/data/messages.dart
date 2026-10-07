import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

/// Messages between a business and a person (00069): one conversation per
/// pair, read and written only by the two sides.

/// A conversation as the caller sees it — from `my_conversations`, which
/// names the other side (a resident's name and photo are private otherwise).
class Conversation {
  final String id;
  final String businessId;
  final String profileId;

  /// Whether the caller is on the business's side of it.
  final bool asBusiness;
  final String otherName;
  final String? otherAvatar;
  final String? jobTitle;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.businessId,
    required this.profileId,
    required this.asBusiness,
    required this.otherName,
    this.otherAvatar,
    this.jobTitle,
    this.lastMessage,
    required this.lastMessageAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'] as String,
    businessId: j['business_id'] as String,
    profileId: j['profile_id'] as String,
    asBusiness: j['as_business'] as bool? ?? false,
    otherName: (j['other_name'] as String?) ?? '',
    otherAvatar: j['other_avatar'] as String?,
    jobTitle: j['job_title'] as String?,
    lastMessage: j['last_message'] as String?,
    lastMessageAt: DateTime.tryParse(j['last_message_at'] as String? ?? '') ?? DateTime.now(),
    unread: (j['unread'] as num?)?.toInt() ?? 0,
  );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String? senderId;
  final String body;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    conversationId: j['conversation_id'] as String,
    senderId: j['sender_id'] as String?,
    body: (j['body'] as String?) ?? '',
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );
}

class MessageRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Conversation>> conversations() async {
    if (_client.auth.currentUser == null) return const [];
    final rows = await _client.rpc('my_conversations');
    return [
      for (final r in List<Map<String, dynamic>>.from(rows as List)) Conversation.fromJson(r),
    ];
  }

  Future<int> unreadCount() async {
    if (_client.auth.currentUser == null) return 0;
    final n = await _client.rpc('my_unread_messages');
    return (n as num?)?.toInt() ?? 0;
  }

  /// Opens (or finds) the conversation between [businessId] and a person:
  /// [profileId] when the caller writes as the business, the caller otherwise.
  Future<String> start({required String businessId, String? profileId, String? jobId}) async {
    final id = await _client.rpc('start_conversation', params: {
      'p_business': businessId,
      'p_profile': profileId,
      'p_job': jobId,
    });
    return id as String;
  }

  /// The conversation's messages, live: the first event is the history, and
  /// each new message arrives as it is sent.
  Stream<List<ChatMessage>> watch(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        // Oldest first, as the chat builds it. A stream's order is newest
        // first unless told otherwise, and the conversation read backwards.
        .order('created_at', ascending: true)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  Future<void> send(String conversationId, String body) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('not signed in');
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': body.trim(),
    });
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _client.rpc('mark_conversation_read', params: {'p_conversation': conversationId});
    } catch (_) {}
  }
}

final messageRepositoryProvider = Provider((ref) => MessageRepository());

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  ref.watch(authProvider.select((u) => u?.id));
  return ref.watch(messageRepositoryProvider).conversations();
});

/// The badge on the home page's message icon.
final unreadMessagesProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(authProvider.select((u) => u?.id));
  return ref.watch(messageRepositoryProvider).unreadCount();
});

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, conversationId) => ref.watch(messageRepositoryProvider).watch(conversationId),
);
