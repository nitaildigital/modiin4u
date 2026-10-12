import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/owner_data.dart';

/// The business's own events (00081), as its Deals page lists deals: newest
/// first, each with where it stands — waiting for approval, shown, withdrawn
/// or over — and a menu to edit or withdraw it.
class BusinessEventsScreen extends ConsumerWidget {
  const BusinessEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myEventsProvider);
    final hasBusiness = ref.watch(myBusinessIdProvider) != null;
    return MPage(
      title: mTr(context, 'My Events', 'האירועים שלי'),
      body: Stack(
        children: [
          Positioned.fill(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => MEmpty(
                icon: IconsaxPlusLinear.calendar,
                title: mTr(context, 'Could not load your events', 'לא ניתן לטעון את האירועים'),
              ),
              data: (events) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myEventsProvider);
                  await ref.read(myEventsProvider.future);
                },
                child: events.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          MEmpty(
                            icon: IconsaxPlusLinear.calendar,
                            title: hasBusiness
                                ? mTr(context, 'No events yet', 'אין אירועים עדיין')
                                : mTr(context, 'No business on this account', 'אין עסק בחשבון הזה'),
                            text: hasBusiness
                                ? mTr(
                                    context,
                                    'Create an event; it appears in the app once the team approves it.',
                                    'צרו אירוע; הוא יופיע באפליקציה לאחר אישור הצוות.',
                                  )
                                : null,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: mStepHairline),
                        itemBuilder: (context, i) => _EventRow(item: events[i]),
                      ),
              ),
            ),
          ),
          if (hasBusiness)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 16,
              child: Center(
                child: MFloatingAdd(
                  label: mTr(context, 'Create Event', 'יצירת אירוע'),
                  onTap: () => context.push('/business-events/new'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  final OwnerEvent item;
  const _EventRow({required this.item});

  (String, Color, Color) _status(BuildContext context) => switch (item.status) {
    'published' => (mTr(context, 'Published', 'פורסם'), const Color(0xFF1E9E4A), const Color(0xFFE7F9E8)),
    'pending' => (mTr(context, 'Awaiting approval', 'ממתין לאישור'), const Color(0xFFB4540C), const Color(0xFFFFF1E2)),
    'cancelled' => (mTr(context, 'Withdrawn', 'בוטל'), const Color(0xFF6D6D6D), const Color(0xFFF1F1F1)),
    _ => (mTr(context, 'Ended', 'הסתיים'), const Color(0xFF6D6D6D), const Color(0xFFF1F1F1)),
  };

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(mTr(ctx, 'Withdraw this event?', 'לבטל את האירוע?'), style: mText(17, weight: FontWeight.w600)),
        content: Text(
          mTr(ctx, 'It will no longer appear in the app. The team can restore it.', 'הוא לא יופיע עוד באפליקציה. הצוות יכול לשחזר אותו.'),
          style: mText(14, color: const Color(0xFF3D3D3D), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(mTr(ctx, 'Keep', 'השארה'), style: mText(14, color: mStepGrey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(mTr(ctx, 'Withdraw', 'ביטול האירוע'), style: mText(14, weight: FontWeight.w600, color: mKitRed)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(ownerRepositoryProvider).cancelEvent(item.event.id);
      ref.invalidate(myEventsProvider);
    } catch (_) {
      if (context.mounted) mToast(context, mTr(context, 'Could not save. Try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = item.event;
    final (label, fg, bg) = _status(context);
    final date = e.startDate == null ? '' : mDate(context, e.startDate!.toLocal());
    final time = (e.startTime ?? '').length >= 5 ? e.startTime!.substring(0, 5) : '';
    return InkWell(
      onTap: item.isPublished ? () => context.push('/event/${e.id}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: NetworkPhoto(url: e.imageUrl, width: 72, height: 72, icon: IconsaxPlusBold.calendar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: mText(15, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text([date, time].where((s) => s.isNotEmpty).join(' · '), style: mText(12.5, color: mStepGrey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                    child: Text(label, style: mText(11.5, weight: FontWeight.w500, color: fg)),
                  ),
                ],
              ),
            ),
            if (!item.isCancelled)
              PopupMenuButton<String>(
                icon: const Icon(IconsaxPlusLinear.more, color: Color(0xFF3D3D3D)),
                color: Colors.white,
                onSelected: (v) => v == 'edit' ? context.push('/business-events/${e.id}/edit') : _withdraw(context, ref),
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text(mTr(ctx, 'Edit', 'עריכה'), style: mText(14))),
                  PopupMenuItem(value: 'withdraw', child: Text(mTr(ctx, 'Withdraw', 'ביטול האירוע'), style: mText(14, color: mKitRed))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
