import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/messages.dart';
import 'conversations_screen.dart' show MessagesSignInPrompt;

const _mineBubble = Color(0xFFE8F0FB);
const _theirBubble = Color(0xFFF4F4F4);
const _dayPill = Color(0xFFECEFF3);
const _avatarSize = 32.0;

/// One conversation (/messages/:id), as drawn in `business_side/Message.png`:
/// the other side's photo and name at the top, the messages oldest first with
/// the newest at the foot, and a field to write in.
///
/// Left out of the drawing because nothing backs them: the "Online" line and
/// its green dot (there is no presence data), the attachment and emoji icons
/// (messages are text only), and the "⋯" menu (it would have no action).
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _field = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  // Marking read is debounced: a burst of replies is one call, not several.
  Timer? _readTimer;
  Future<void> _reading = Future.value();
  String? _newestSeen;

  // Kept from initState because `ref` cannot be used once the screen is
  // being disposed, and the badge has to be refreshed then.
  late final ProviderContainer _container;

  MessageRepository get _repo => ref.read(messageRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _markRead();
  }

  @override
  void dispose() {
    final pending = _readTimer?.isActive ?? false;
    _readTimer?.cancel();
    if (pending) _reading = _container.read(messageRepositoryProvider).markRead(widget.conversationId);
    // The home badge and the list are refreshed only once the last "read"
    // has landed, or they would be fetched while it was still unread.
    final container = _container;
    _reading.whenComplete(() {
      container.invalidate(unreadMessagesProvider);
      container.invalidate(conversationsProvider);
    });
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _markRead() {
    _reading = _repo.markRead(widget.conversationId);
  }

  void _scheduleRead() {
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _markRead();
    });
  }

  Future<void> _send() async {
    final body = _field.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.send(widget.conversationId, body);
      if (!mounted) return;
      _field.clear();
      // The list runs from the foot (it is reversed), so the newest message
      // is at offset 0.
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    } catch (_) {
      if (mounted) {
        mToast(
          context,
          mTr(context, "Couldn't send your message. Please try again.", 'לא הצלחנו לשלוח את ההודעה. נסו שוב.'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // The stored session takes a moment to read back, so a null here does not
    // yet mean signed out.
    if (user == null) {
      return MPage(
        title: mTr(context, 'Messages', 'הודעות'),
        body: ref.watch(authRestoringProvider)
            ? const Center(child: CircularProgressIndicator())
            : const MessagesSignInPrompt(),
      );
    }

    final myId = user.id;
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));

    // A reply from the other side while the screen is open is read as it
    // arrives. The history that comes first was covered by the read on open.
    ref.listen(chatMessagesProvider(widget.conversationId), (prev, next) {
      final list = next.valueOrNull;
      if (list == null || list.isEmpty) return;
      final newest = list.last;
      final firstLoad = prev?.valueOrNull == null;
      if (newest.id == _newestSeen) return;
      _newestSeen = newest.id;
      if (!firstLoad && newest.senderId != myId) _scheduleRead();
    });

    final conversations = ref.watch(conversationsProvider);
    Conversation? conversation;
    for (final c in conversations.valueOrNull ?? const <Conversation>[]) {
      if (c.id == widget.conversationId) conversation = c;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _Header(conversation: conversation, loading: conversations.isLoading && conversation == null),
                Expanded(
                  // A dropped realtime channel surfaces as an error; while the
                  // history is on screen it stays there rather than blanking.
                  child: messages.when(
                    skipError: true,
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => MEmpty(
                      icon: IconsaxPlusLinear.warning_2,
                      title: mTr(context, "Couldn't load this conversation", 'לא הצלחנו לטעון את השיחה'),
                      text: mTr(context, 'Go back and open it again.', 'חזרו ופתחו אותה שוב.'),
                    ),
                    data: (list) => list.isEmpty
                        ? MEmpty(
                            icon: IconsaxPlusLinear.messages_2,
                            title: mTr(context, 'No messages yet', 'אין הודעות עדיין'),
                            text: mTr(context, 'Write the first one below.', 'כתבו את ההודעה הראשונה למטה.'),
                          )
                        : _MessageList(
                            messages: list,
                            myId: myId,
                            other: conversation,
                            controller: _scroll,
                          ),
                  ),
                ),
                _InputBar(controller: _field, sending: _sending, onSend: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Back arrow, then the other side's photo and name. The drawing's "Online"
/// line has no data behind it; the job the conversation began from is shown
/// there instead when there is one.
class _Header extends StatelessWidget {
  final Conversation? conversation;
  final bool loading;
  const _Header({required this.conversation, required this.loading});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final job = (c?.jobTitle ?? '').trim();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(15, 10, 16, 12),
      child: Row(
        children: [
          const MBackArrow(color: Color(0xFF3D3D3D)),
          const SizedBox(width: 14),
          if (c == null) ...[
            // Until the list has loaded, a grey shape holds the name's place.
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: mKitChipBg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            if (loading)
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(color: mKitChipBg, borderRadius: BorderRadius.circular(7)),
              ),
          ] else ...[
            MAvatar(url: c.otherAvatar, name: c.otherName, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.otherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: mHeading(17)),
                  if (job.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(job, maxLines: 1, overflow: TextOverflow.ellipsis, style: mText(12, color: mStepGrey)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A day's pill, or a message and whether it starts a run from one sender.
sealed class _Item {}

class _DayItem extends _Item {
  final DateTime day;
  _DayItem(this.day);
}

class _MessageItem extends _Item {
  final ChatMessage message;
  final bool firstOfRun;
  _MessageItem(this.message, this.firstOfRun);
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String myId;
  final Conversation? other;
  final ScrollController controller;

  const _MessageList({
    required this.messages,
    required this.myId,
    required this.other,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Built oldest first, then shown reversed so the list opens at its foot
    // and stays there as messages arrive.
    final items = <_Item>[];
    DateTime? lastDay;
    String? lastSender;
    for (final m in messages) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      final newDay = day != lastDay;
      if (newDay) items.add(_DayItem(day));
      items.add(_MessageItem(m, newDay || m.senderId != lastSender));
      lastDay = day;
      lastSender = m.senderId;
    }

    return LayoutBuilder(
      builder: (context, box) {
        final maxBubble = box.maxWidth * 0.76;
        return ListView.builder(
          controller: controller,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[items.length - 1 - i];
            return switch (item) {
              _DayItem(:final day) => _DayPill(day: day),
              _MessageItem(:final message, :final firstOfRun) => Padding(
                padding: EdgeInsets.only(top: firstOfRun ? 16 : 6),
                child: _Bubble(
                  message: message,
                  mine: message.senderId == myId,
                  showAvatar: firstOfRun,
                  other: other,
                  maxWidth: maxBubble,
                ),
              ),
            };
          },
        );
      },
    );
  }
}

class _DayPill extends StatelessWidget {
  final DateTime day;
  const _DayPill({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _dayPill, borderRadius: BorderRadius.circular(6)),
          child: Text(mDate(context, day), style: mText(11.5, color: mStepGrey)),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final bool showAvatar;
  final Conversation? other;
  final double maxWidth;

  const _Bubble({
    required this.message,
    required this.mine,
    required this.showAvatar,
    required this.other,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 10),
        decoration: BoxDecoration(
          color: mine ? _mineBubble : _theirBubble,
          borderRadius: BorderRadius.circular(16),
        ),
        // Sized to the longer of the text and the time, so a short message
        // makes a small bubble with its time still at the bottom-end.
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.body, style: mText(14, color: mStepInk, height: 1.45)),
              const SizedBox(height: 6),
              Text(
                _bubbleTime(context, message.createdAt),
                textAlign: TextAlign.end,
                style: mText(11, color: mStepGrey),
              ),
            ],
          ),
        ),
      ),
    );

    if (mine) {
      return Align(alignment: AlignmentDirectional.centerEnd, child: bubble);
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The photo marks the first of a run; the rest keep its indent.
          if (showAvatar)
            MAvatar(url: other?.otherAvatar, name: other?.otherName ?? '', size: _avatarSize)
          else
            const SizedBox(width: _avatarSize),
          const SizedBox(width: 12),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: mStepHairline),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: mStepHairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: mText(14, color: mStepInk, height: 1.4),
              decoration: InputDecoration(
                hintText: mTr(context, 'Type a message…', 'כתבו הודעה…'),
                hintStyle: mText(14, color: mStepGrey),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(borderSide: const BorderSide(color: mStepMid)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: sending ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sending ? mStepMid.withValues(alpha: 0.6) : mStepMid,
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  // The plane points the way the text runs.
                  : Transform.flip(
                      flipX: rtl,
                      child: const Icon(IconsaxPlusBold.send_1, size: 22, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "9:12 AM" in English; "09:12" in Hebrew, where the 24-hour clock is usual.
String _bubbleTime(BuildContext context, DateTime when) {
  final t = when.toLocal();
  final mm = t.minute.toString().padLeft(2, '0');
  final he = '${t.hour.toString().padLeft(2, '0')}:$mm';
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final en = '$h12:$mm ${t.hour < 12 ? 'AM' : 'PM'}';
  return mTr(context, en, he);
}
