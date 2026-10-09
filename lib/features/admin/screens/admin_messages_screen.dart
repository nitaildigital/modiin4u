import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../shared/widgets/network_photo.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// Conversations between businesses and residents (00069), read-only — the
/// client, 9 Oct: "the admin can see all the chats which are done by
/// businesses and the job seekers". Through 00078's functions, which check
/// the moderation module and write each conversation opened to the activity
/// log. Reading here marks nothing as read for either side.

class _AdminConversation {
  final String id;
  final String businessName;
  final String? businessLogo;
  final String residentName;
  final String? residentAvatar;
  final String? jobTitle;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int messageCount;

  const _AdminConversation({
    required this.id,
    required this.businessName,
    this.businessLogo,
    required this.residentName,
    this.residentAvatar,
    this.jobTitle,
    this.lastMessage,
    required this.lastMessageAt,
    required this.messageCount,
  });

  factory _AdminConversation.fromJson(Map<String, dynamic> j) => _AdminConversation(
    id: j['id'] as String,
    businessName: (j['business_name'] as String?) ?? '',
    businessLogo: j['business_logo'] as String?,
    residentName: (j['resident_name'] as String?)?.trim().isNotEmpty == true
        ? j['resident_name'] as String
        : tr('תושב ללא שם', 'Unnamed resident'),
    residentAvatar: j['resident_avatar'] as String?,
    jobTitle: j['job_title'] as String?,
    lastMessage: j['last_message'] as String?,
    lastMessageAt: DateTime.tryParse(j['last_message_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    messageCount: (j['message_count'] as num?)?.toInt() ?? 0,
  );
}

class _AdminMessage {
  final String id;
  final bool fromBusiness;
  final String body;
  final DateTime createdAt;

  const _AdminMessage({required this.id, required this.fromBusiness, required this.body, required this.createdAt});

  factory _AdminMessage.fromJson(Map<String, dynamic> j) => _AdminMessage(
    id: j['id'] as String,
    fromBusiness: j['from_business'] == true,
    body: (j['body'] as String?) ?? '',
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );
}

const _pageSize = 50;

final _searchProvider = StateProvider.autoDispose<String>((ref) => '');
final _limitProvider = StateProvider.autoDispose<int>((ref) => _pageSize);

final _conversationsProvider = FutureProvider.autoDispose<List<_AdminConversation>>((ref) async {
  final search = ref.watch(_searchProvider);
  final limit = ref.watch(_limitProvider);
  final rows = await SupabaseConfig.client.rpc('admin_conversations', params: {
    'p_search': search.trim().isEmpty ? null : search.trim(),
    'p_limit': limit,
    'p_offset': 0,
  });
  return List<Map<String, dynamic>>.from(rows as List).map(_AdminConversation.fromJson).toList();
});

final _messagesProvider = FutureProvider.autoDispose.family<List<_AdminMessage>, String>((ref, id) async {
  final rows = await SupabaseConfig.client.rpc('admin_conversation_messages', params: {'p_conversation': id});
  return List<Map<String, dynamic>>.from(rows as List).map(_AdminMessage.fromJson).toList();
});

String _when(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  _AdminConversation? _open;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // Each letter would be a query; the list is asked for once typing pauses.
  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(_limitProvider.notifier).state = _pageSize;
      ref.read(_searchProvider.notifier).state = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final list = ref.watch(_conversationsProvider);
    final limit = ref.watch(_limitProvider);
    final rows = list.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminListToolbar(
          search: AdminSearchField(
            controller: _search,
            hint: tr('חיפוש לפי עסק, תושב, משרה או הודעה', 'Search by business, resident, job or message'),
            onChanged: _onSearch,
            width: 340,
          ),
          count: rows == null ? null : '${rows.length}${rows.length >= limit ? '+' : ''}',
          actions: [
            AdminToolbarButton(
              label: tr('רענון', 'Refresh'),
              icon: Icons.refresh,
              primary: false,
              onPressed: () {
                ref.invalidate(_conversationsProvider);
                if (_open != null) ref.invalidate(_messagesProvider(_open!.id));
              },
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: k.accentSoft,
          child: Row(
            children: [
              Icon(IconsaxPlusLinear.shield_tick, size: 16, color: k.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('שיחות פרטיות בין עסקים לתושבים. קריאה בלבד; כל שיחה שנפתחת נרשמת ביומן הפעולות.',
                     'Private conversations between businesses and residents. Read-only; every conversation opened is written to the activity log.'),
                  style: k.hint.copyWith(color: k.inkSoft),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 400,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: k.surface,
                    border: BorderDirectional(end: BorderSide(color: k.border)),
                  ),
                  child: list.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr('השיחות לא נטענו.', 'Conversations did not load.'), style: k.body),
                            const SizedBox(height: 4),
                            Text(
                              '$e'.contains('admin_conversations') ? tr('הרץ את מיגרציה 00078.', 'Run migration 00078.') : '$e',
                              style: k.hint,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            AdminButton.secondary(
                              label: tr('נסה שוב', 'Try again'),
                              onPressed: () => ref.invalidate(_conversationsProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (rows) => rows.isEmpty
                        ? Center(child: Text(tr('אין שיחות.', 'No conversations.'), style: k.hint))
                        : ListView.separated(
                            itemCount: rows.length + (rows.length >= limit ? 1 : 0),
                            separatorBuilder: (_, _) => Divider(height: 1, color: k.border),
                            itemBuilder: (context, i) {
                              if (i == rows.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: AdminButton.secondary(
                                    label: tr('עוד שיחות', 'More conversations'),
                                    onPressed: () => ref.read(_limitProvider.notifier).state = limit + _pageSize,
                                  ),
                                );
                              }
                              final c = rows[i];
                              return _ConversationTile(
                                conversation: c,
                                selected: _open?.id == c.id,
                                onTap: () => setState(() => _open = c),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: _open == null
                    ? Center(
                        child: Text(tr('בחרו שיחה כדי לקרוא אותה.', 'Choose a conversation to read it.'), style: k.hint),
                      )
                    : _Thread(conversation: _open!),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const _Avatar({this.url, required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url ?? '').isNotEmpty
            ? NetworkPhoto(url: url!, icon: IconsaxPlusBold.user, width: double.infinity, height: double.infinity)
            : ColoredBox(
                color: k.accentSoft,
                child: Center(child: Text(initial, style: k.label.copyWith(color: k.accent))),
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _AdminConversation conversation;
  final bool selected;
  final VoidCallback onTap;
  const _ConversationTile({required this.conversation, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final c = conversation;
    final job = (c.jobTitle ?? '').trim();
    return Material(
      color: selected ? k.accentSoft : k.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: c.businessLogo, name: c.businessName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c.businessName} ↔ ${c.residentName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.heading.copyWith(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_when(c.lastMessageAt), style: k.hint.copyWith(fontSize: 11.5)),
                      ],
                    ),
                    if (job.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(IconsaxPlusLinear.briefcase, size: 13, color: k.muted),
                          const SizedBox(width: 4),
                          Flexible(child: Text(job, maxLines: 1, overflow: TextOverflow.ellipsis, style: k.hint)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (c.lastMessage ?? '').trim().isEmpty ? tr('אין הודעות', 'No messages') : c.lastMessage!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.body.copyWith(fontSize: 13, color: k.inkSoft),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AdminPill('${c.messageCount}', k.muted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One conversation, as the two sides wrote it: the business's lines on one
/// side, the resident's on the other, each with its time.
class _Thread extends ConsumerWidget {
  final _AdminConversation conversation;
  const _Thread({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = AdminKit.of(context);
    final c = conversation;
    final messages = ref.watch(_messagesProvider(c.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(color: k.surface, border: Border(bottom: BorderSide(color: k.border))),
          child: Row(
            children: [
              _Avatar(url: c.businessLogo, name: c.businessName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.businessName, style: k.heading),
                    Text(
                      [
                        tr('עם ${c.residentName}', 'with ${c.residentName}'),
                        if ((c.jobTitle ?? '').trim().isNotEmpty) c.jobTitle!.trim(),
                      ].join(' · '),
                      style: k.hint,
                    ),
                  ],
                ),
              ),
              _Avatar(url: c.residentAvatar, name: c.residentName, size: 40),
            ],
          ),
        ),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e', style: k.hint)),
            data: (list) => list.isEmpty
                ? Center(child: Text(tr('אין הודעות בשיחה.', 'No messages in this conversation.'), style: k.hint))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _Bubble(
                      message: list[i],
                      sender: list[i].fromBusiness ? c.businessName : c.residentName,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final _AdminMessage message;
  final String sender;
  const _Bubble({required this.message, required this.sender});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final business = message.fromBusiness;
    return Align(
      alignment: business ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: business ? k.surface : k.accentSoft,
            border: Border.all(color: k.border),
            borderRadius: BorderRadius.circular(k.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$sender · ${_when(message.createdAt)}', style: k.hint.copyWith(fontSize: 11.5)),
              const SizedBox(height: 4),
              SelectableText(message.body, style: k.body),
            ],
          ),
        ),
      ),
    );
  }
}
