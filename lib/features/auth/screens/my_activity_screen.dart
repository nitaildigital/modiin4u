import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/my_activity_provider.dart';
import '../widgets/m_account_widgets.dart';

/// Menu → My activity: the resident's own reviews and comments in one place,
/// with what came of them — waiting for approval, likes, "helpful", the
/// business's answer (the client, 25 Nov). Each opens where it was written.
class MyActivityScreen extends ConsumerStatefulWidget {
  const MyActivityScreen({super.key});

  @override
  ConsumerState<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends ConsumerState<MyActivityScreen> {
  bool _comments = false;

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authProvider.select((u) => u != null));
    final activity = ref.watch(myActivityProvider);
    final data = activity.valueOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                MAccountTopBar(title: mTr(context, 'My activity', 'הפעילות שלי')),
                const SizedBox(height: 12),
                if (signedIn)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _Tab(
                          label: mTr(context, 'Reviews', 'ביקורות'),
                          count: data?.reviews.length,
                          selected: !_comments,
                          onTap: () => setState(() => _comments = false),
                        ),
                        const SizedBox(width: 8),
                        _Tab(
                          label: mTr(context, 'Comments', 'תגובות'),
                          count: data?.comments.length,
                          selected: _comments,
                          onTap: () => setState(() => _comments = true),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: !signedIn
                      ? _Message(mTr(context, 'Sign in to see your reviews and comments.',
                          'התחברו כדי לראות את הביקורות והתגובות שלכם.'))
                      : activity.hasError && data == null
                          ? _Message(mTr(context, 'Could not load your activity. Pull down to try again.',
                              'לא הצלחנו לטעון את הפעילות שלכם. משכו למטה כדי לנסות שוב.'),
                              onRetry: () => ref.invalidate(myActivityProvider))
                          : data == null
                              ? const Center(child: CircularProgressIndicator())
                              : _List(
                                  items: _comments ? data.comments : data.reviews,
                                  empty: _comments
                                      ? mTr(context, 'You have not commented yet. Comments you write under articles and reviews appear here.',
                                          'עדיין לא הגבתם. תגובות שתכתבו לכתבות ולביקורות יופיעו כאן.')
                                      : mTr(context, 'You have not reviewed a place yet. Reviews you write appear here.',
                                          'עדיין לא כתבתם ביקורת. ביקורות שתכתבו יופיעו כאן.'),
                                  onRefresh: () => ref.refresh(myActivityProvider.future),
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        count == null ? label : '$label ($count)',
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.navy),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.white,
      selectedColor: const Color(0xFFE3EDFB),
      side: const BorderSide(color: AppColors.border),
      checkmarkColor: AppColors.navy,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message(this.text, {this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: MAccountColors.label),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(mTr(context, 'Try again', 'נסו שוב'))),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  final List<MyActivityItem> items;
  final String empty;
  final Future<void> Function() onRefresh;
  const _List({required this.items, required this.empty, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                _Message(empty),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEDEDED)),
              itemBuilder: (context, i) => _Card(item: items[i]),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final MyActivityItem item;
  const _Card({required this.item});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = item.createdAt == null ? '' : DateFormat.yMMMMd(locale).format(item.createdAt!);
    final (statusText, statusColor) = switch (item.status) {
      'approved' => (null, null),
      'pending' => (mTr(context, 'Pending approval', 'ממתין לאישור'), const Color(0xFFD98A00)),
      _ => (mTr(context, 'Not published', 'לא פורסם'), AppColors.error),
    };
    final meta = TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: MAccountColors.label);

    return InkWell(
      onTap: () => context.push(item.link),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.place.isEmpty ? mTr(context, 'Modiin4u', 'מודיעין בשבילך') : item.place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(date, style: meta),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (item.rating != null)
                  for (var s = 1; s <= 5; s++)
                    Icon(
                      s <= item.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: s <= item.rating! ? const Color(0xFFFFC107) : const Color(0xFFCFCFCF),
                    ),
                if (item.onReview) Text(mTr(context, 'Reply to a review', 'תגובה לביקורת'), style: meta),
                if (item.rating == null && !item.onReview) Text(mTr(context, 'Comment on an article', 'תגובה לכתבה'), style: meta),
                if (statusText != null) ...[
                  const SizedBox(width: 8),
                  Text(statusText, style: meta.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
            if (item.body.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 1.4, color: MAccountColors.value),
              ),
            ],
            if (item.likes > 0 || item.helpful > 0 || item.answered) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  if (item.likes > 0)
                    _Stat(icon: IconsaxPlusBold.like_1, text: '${item.likes}'),
                  if (item.helpful > 0)
                    _Stat(icon: IconsaxPlusBold.tick_circle, text: '${mTr(context, 'Helpful', 'מועיל')} · ${item.helpful}'),
                  if (item.answered)
                    _Stat(icon: IconsaxPlusBold.message_text, text: mTr(context, 'Answered', 'התקבלה תשובה')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Stat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.midBlue),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.midBlue),
        ),
      ],
    );
  }
}
