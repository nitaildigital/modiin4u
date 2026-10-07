import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/messages.dart';

/// The conversations list (/messages): one row per person or business the
/// signed-in person is talking with, newest first. There is no frame for it in
/// the design, so it follows the chat and the other `business_side/` pages —
/// a white page, a centred title, and rows led by a round avatar.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final title = mTr(context, 'Messages', 'הודעות');

    // The stored session takes a moment to read back, so a null here does not
    // yet mean signed out.
    if (user == null && ref.watch(authRestoringProvider)) {
      return MPage(title: title, body: const Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return MPage(title: title, body: const MessagesSignInPrompt());
    }

    final conversations = ref.watch(conversationsProvider);

    Future<List<Conversation>> refresh() {
      ref.invalidate(unreadMessagesProvider);
      return ref.refresh(conversationsProvider.future);
    }

    return MPage(
      title: title,
      body: RefreshIndicator(
        color: mStepMid,
        onRefresh: refresh,
        child: conversations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _FillScroll(
            child: MEmpty(
              icon: IconsaxPlusLinear.warning_2,
              title: mTr(context, "Couldn't load your messages", 'לא הצלחנו לטעון את ההודעות'),
              text: mTr(context, 'Pull down to try again.', 'משכו למטה כדי לנסות שוב.'),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return _FillScroll(
                child: MEmpty(
                  icon: IconsaxPlusLinear.messages_2,
                  title: mTr(context, 'No messages yet', 'אין הודעות עדיין'),
                  text: mTr(
                    context,
                    'Businesses can write to people who applied to their jobs. Replies appear here.',
                    'עסקים יכולים לכתוב לאנשים שהגישו מועמדות למשרות שלהם. התשובות יופיעו כאן.',
                  ),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsetsDirectional.only(start: 80, end: 16),
                child: Divider(height: 1, thickness: 1, color: mStepHairline),
              ),
              itemBuilder: (context, i) => _ConversationRow(
                conversation: list[i],
                onTap: () async {
                  await context.push('/messages/${list[i].id}');
                  // Reading a conversation changes its unread count and,
                  // if a reply was sent, its last line and its place.
                  if (!context.mounted) return;
                  ref.invalidate(conversationsProvider);
                  ref.invalidate(unreadMessagesProvider);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// What a signed-out visitor sees on the messages pages: messages belong to an
/// account, so there is nothing to show until they sign in.
class MessagesSignInPrompt extends StatelessWidget {
  const MessagesSignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MEmpty(
              icon: IconsaxPlusLinear.messages_2,
              title: mTr(context, 'Sign in to see your messages', 'התחברו כדי לראות את ההודעות'),
              text: mTr(
                context,
                'Conversations with businesses are kept with your account.',
                'השיחות עם עסקים נשמרות בחשבון שלכם.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: MButton(
                label: mTr(context, 'Sign in', 'התחברות'),
                onTap: () => context.push('/login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A centred message that can still be pulled down to refresh: the indicator
/// only answers a scrollable, so the message sits in one that fills the page.
class _FillScroll extends StatelessWidget {
  final Widget child;
  const _FillScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  const _ConversationRow({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unread > 0;
    final job = (c.jobTitle ?? '').trim();
    final last = (c.lastMessage ?? '').trim();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            MAvatar(url: c.otherAvatar, name: c.otherName, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mText(15, weight: FontWeight.w600, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _listTime(context, c.lastMessageAt),
                        style: mText(
                          12,
                          weight: unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread ? mStepMid : mStepGrey,
                        ),
                      ),
                    ],
                  ),
                  if (job.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(IconsaxPlusLinear.briefcase, size: 13, color: mStepGrey),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            job,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mText(12, color: mStepGrey),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          last.isEmpty ? mTr(context, 'No messages yet', 'אין הודעות עדיין') : last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mText(
                            13,
                            weight: unread ? FontWeight.w600 : FontWeight.w400,
                            color: unread ? mStepInk : mStepGrey,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: mStepMid, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            c.unread > 99 ? '99+' : '${c.unread}',
                            style: mText(11, weight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "14:05" today, "Yesterday", or "8/10" further back — day first, as dates
/// are written in Israel.
String _listTime(BuildContext context, DateTime when) {
  final t = when.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final days = today.difference(day).inDays;
  if (days <= 0) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
  if (days == 1) return mTr(context, 'Yesterday', 'אתמול');
  return '${t.day}/${t.month}';
}
