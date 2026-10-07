import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../deals/models/offer.dart';
import '../data/owner_data.dart';

/// The business's deals (`business_side/Deals.png`), live or not, newest
/// first, each with a menu to edit, promote, close or delete it.
///
/// The design's second line under each deal ("Mon – Sun · 6:00 PM – 10:00
/// PM") has no column behind it, so it is left out.
class BusinessDealsScreen extends ConsumerWidget {
  const BusinessDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myDealsProvider);
    final hasBusiness = ref.watch(myBusinessIdProvider) != null;
    return MPage(
      title: mTr(context, 'Deals', 'מבצעים'),
      body: Stack(
        children: [
          Positioned.fill(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => MEmpty(
                icon: IconsaxPlusLinear.ticket_discount,
                title: mTr(context, 'Could not load your deals', 'לא ניתן לטעון את המבצעים'),
              ),
              data: (deals) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myDealsProvider);
                  ref.invalidate(myPromotionRequestsProvider);
                  await ref.read(myDealsProvider.future);
                },
                child: deals.isEmpty
                    // A scrollable, so the empty page can still be pulled.
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          MEmpty(
                            icon: IconsaxPlusLinear.ticket_discount,
                            title: hasBusiness
                                ? mTr(context, 'No deals yet', 'אין מבצעים עדיין')
                                : mTr(context, 'No business on this account', 'אין עסק בחשבון הזה'),
                            text: hasBusiness
                                ? mTr(
                                    context,
                                    'Create a deal and it goes live in the app at once.',
                                    'צרו מבצע והוא יעלה לאפליקציה מיד.',
                                  )
                                : null,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: deals.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: mStepHairline),
                        itemBuilder: (context, i) => _DealRow(deal: deals[i]),
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
                  label: mTr(context, 'Create Deal', 'יצירת מבצע'),
                  onTap: () => context.push('/business-deals/new'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Action { edit, promote, close, delete }

class _DealRow extends ConsumerWidget {
  final Offer deal;
  const _DealRow({required this.deal});

  bool get _active => deal.status == 'active';

  void _refresh(WidgetRef ref) => ref.invalidate(myDealsProvider);

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String text,
    required String action,
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: mText(17, weight: FontWeight.w600)),
        content: Text(text, style: mText(14, color: const Color(0xFF3D3D3D), height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(mTr(context, 'Cancel', 'ביטול'), style: mText(14, color: mStepGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              action,
              style: mText(14, weight: FontWeight.w600, color: danger ? mKitRed : mStepMid),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _close(BuildContext context, WidgetRef ref, {bool asked = false}) async {
    if (!asked &&
        !await _confirm(
          context,
          title: mTr(context, 'Close this deal?', 'לסגור את המבצע?'),
          text: mTr(
            context,
            'It stops showing in the app and stops taking claims. Vouchers already claimed stay valid.',
            'המבצע יוסר מהאפליקציה ולא ניתן יהיה לממש אותו עוד. שוברים שכבר נלקחו יישארו בתוקף.',
          ),
          action: mTr(context, 'Close Deal', 'סגירת המבצע'),
        )) {
      return;
    }
    try {
      await ref.read(ownerRepositoryProvider).closeDeal(deal.id);
      _refresh(ref);
      if (context.mounted) mToast(context, mTr(context, 'Deal closed', 'המבצע נסגר'));
    } catch (_) {
      if (context.mounted) mToast(context, mTr(context, 'Could not close the deal', 'לא ניתן לסגור את המבצע'), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(
      context,
      title: mTr(context, 'Delete this deal?', 'למחוק את המבצע?'),
      text: mTr(context, 'This cannot be undone.', 'לא ניתן לבטל פעולה זו.'),
      action: mTr(context, 'Delete', 'מחיקה'),
      danger: true,
    )) {
      return;
    }
    if (!context.mounted) return;
    final bool deleted;
    try {
      deleted = await ref.read(ownerRepositoryProvider).deleteDeal(deal.id);
    } catch (_) {
      if (context.mounted) mToast(context, mTr(context, 'Could not delete the deal', 'לא ניתן למחוק את המבצע'), error: true);
      return;
    }
    if (!context.mounted) return;
    if (deleted) {
      _refresh(ref);
      mToast(context, mTr(context, 'Deal deleted', 'המבצע נמחק'));
      return;
    }
    // A deal someone has claimed cannot be deleted (00069), so their voucher
    // is never taken away; it can be closed.
    if (!_active) {
      mToast(
        context,
        mTr(context, 'Customers have claimed this deal, so it cannot be deleted.', 'לקוחות כבר מימשו את המבצע, ולכן לא ניתן למחוק אותו.'),
        error: true,
      );
      return;
    }
    final close = await _confirm(
      context,
      title: mTr(context, 'This deal has claims', 'למבצע יש מימושים'),
      text: mTr(
        context,
        'Customers have claimed this deal, so it cannot be deleted. You can close it instead: it stops showing and their vouchers stay valid.',
        'לקוחות כבר מימשו את המבצע, ולכן לא ניתן למחוק אותו. אפשר לסגור אותו במקום: הוא יוסר מהאפליקציה והשוברים שלהם יישארו בתוקף.',
      ),
      action: mTr(context, 'Close Deal', 'סגירת המבצע'),
    );
    if (close && context.mounted) await _close(context, ref, asked: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requested = ref.watch(pendingPromotionProvider(deal.id)) != null;
    final description = (deal.description ?? '').trim();
    final status = switch (deal.status) {
      'active' || null => null,
      'draft' => MStatusPill.forStatus('draft', mTr(context, 'Draft', 'טיוטה')),
      _ => MStatusPill.forStatus('closed', mTr(context, 'Closed', 'סגור')),
    };

    return InkWell(
      // The public page shows only live deals.
      onTap: _active ? () => context.push('/deal/${deal.id}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 96,
                height: 80,
                child: (deal.imageUrl ?? '').isEmpty
                    ? Container(color: mKitBlueBg, child: const Icon(IconsaxPlusLinear.ticket_discount, color: mStepMid))
                    : NetworkPhoto(url: deal.imageUrl!, width: 96, height: 80, icon: IconsaxPlusBold.image),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deal.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: mHeading(17)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mText(12.5, color: mStepGrey),
                    ),
                  ],
                  if (deal.endAt != null) ...[
                    const SizedBox(height: 8),
                    MMeta(
                      IconsaxPlusLinear.timer_1,
                      mTr(
                        context,
                        'Valid until ${mDate(context, deal.endAt!.toLocal())}',
                        'בתוקף עד ${mDate(context, deal.endAt!.toLocal())}',
                      ),
                    ),
                  ],
                  if (status != null || deal.isPromoted) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ?status,
                        if (deal.isPromoted)
                          MStatusPill(
                            mTr(context, 'Promoted', 'מקודם'),
                            color: mStepMid,
                            background: mKitBlueBg,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _menu(context, ref, requested: requested),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, WidgetRef ref, {required bool requested}) {
    PopupMenuItem<_Action> item(_Action value, IconData icon, String label, {Color color = mStepInk, bool enabled = true}) =>
        PopupMenuItem<_Action>(
          value: value,
          enabled: enabled,
          height: 40,
          child: Row(
            children: [
              Icon(icon, size: 18, color: enabled ? color : mStepGrey),
              const SizedBox(width: 10),
              Text(label, style: mText(14, color: enabled ? color : mStepGrey)),
            ],
          ),
        );

    return PopupMenuButton<_Action>(
      icon: const Icon(IconsaxPlusLinear.more, size: 22, color: mStepInk),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 176),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (a) => switch (a) {
        _Action.edit => context.push('/business-deals/${deal.id}/edit'),
        _Action.promote => context.push('/promote/offer/${deal.id}'),
        _Action.close => _close(context, ref),
        _Action.delete => _delete(context, ref),
      },
      itemBuilder: (context) => [
        item(_Action.edit, IconsaxPlusLinear.edit_2, mTr(context, 'Edit Deal', 'עריכת מבצע')),
        // A closed deal is not shown, so there is nothing to promote; one
        // already waiting for the panel cannot be asked for twice.
        if (_active && !deal.isPromoted)
          item(
            _Action.promote,
            IconsaxPlusLinear.speaker,
            requested ? mTr(context, 'Promotion requested', 'נשלחה בקשת קידום') : mTr(context, 'Promote', 'קידום'),
            enabled: !requested,
          ),
        if (_active) item(_Action.close, IconsaxPlusLinear.close_circle, mTr(context, 'Close Deal', 'סגירת המבצע')),
        item(_Action.delete, IconsaxPlusLinear.trash, mTr(context, 'Delete', 'מחיקה'), color: mKitRed),
      ],
    );
  }
}
