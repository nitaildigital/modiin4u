import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/owner_data.dart';

/// A request to promote the business, one of its deals or one of its jobs
/// (`business_side/Promote Deal.png`, `Promote Deal-1.png`). The owner asks
/// for a number of days; the management panel approves or declines, and an
/// approved item is shown first in its list until then (00069).
class PromoteScreen extends ConsumerStatefulWidget {
  /// `business`, `offer` or `job`, as `promotion_requests.entity_type`.
  final String type;
  final String id;
  const PromoteScreen({super.key, required this.type, required this.id});

  @override
  ConsumerState<PromoteScreen> createState() => _PromoteScreenState();
}

class _PromoteScreenState extends ConsumerState<PromoteScreen> {
  static const _durations = [3, 7, 14, 30];

  late final Future<({String? title, String? imageUrl})> _target =
      ref.read(ownerRepositoryProvider).target(widget.type, widget.id);
  final _message = TextEditingController();
  int _days = 3;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Where the back arrow goes when the page was opened straight from an
  /// address and there is nothing to go back to.
  String get _fallback => switch (widget.type) {
    'business' => '/my-business',
    'offer' => '/business-deals',
    _ => '/business-jobs/${widget.id}',
  };

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      final message = _message.text.trim();
      await ref.read(ownerRepositoryProvider).requestPromotion(
        type: widget.type,
        id: widget.id,
        days: _days,
        message: message.isEmpty ? null : message,
      );
      ref.invalidate(myPromotionRequestsProvider);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      // The database allows one waiting request per item.
      final waiting = e.toString().contains('already-requested');
      mToast(
        context,
        waiting
            ? mTr(context, 'A request for this is already waiting for approval', 'בקשה לקידום זה כבר ממתינה לאישור')
            : mTr(context, 'Could not send the request. Try again.', 'שליחת הבקשה נכשלה. נסו שוב.'),
        error: true,
      );
      if (waiting) ref.invalidate(myPromotionRequestsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) return _sentPage();
    final pending = ref.watch(pendingPromotionProvider(widget.id));
    return MPage(
      // The design's "Promote Detal" is a typo.
      title: mTr(context, 'Promote Detail', 'פרטי קידום'),
      onBack: () => context.back(_fallback),
      bottom: MButton(
        label: pending != null
            ? mTr(context, 'Request waiting for approval', 'הבקשה ממתינה לאישור')
            : mTr(context, 'Submit Promotion Request', 'שליחת בקשת קידום'),
        loading: _sending,
        onTap: pending != null ? null : _submit,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _itemCard(),
          const SizedBox(height: 24),
          Text(mTr(context, 'Promotion Detail', 'פרטי הקידום'), style: mText(16, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          MFormCard(
            label: mTr(context, 'Promotion Duration', 'משך הקידום'),
            child: MDropdownRow<int>(
              placeholder: mTr(context, 'Select', 'בחירה'),
              value: _days,
              items: [
                for (final d in _durations) DropdownMenuItem(value: d, child: Text(_daysLabel(d))),
              ],
              onChanged: (v) => setState(() => _days = v ?? _days),
            ),
          ),
          const SizedBox(height: 16),
          _messageBox(),
          _history(),
        ],
      ),
    );
  }

  String _daysLabel(int d) => mTr(context, '$d days', '$d ימים');

  Widget _itemCard() {
    return FutureBuilder(
      future: _target,
      builder: (context, snap) {
        final t = snap.data;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: mStepHairline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 102,
                  height: 80,
                  child: (t?.imageUrl ?? '').isEmpty
                      ? Container(color: mKitBlueBg, child: const Icon(IconsaxPlusLinear.image, color: mStepMid))
                      : NetworkPhoto(url: t!.imageUrl!, width: 102, height: 80, icon: IconsaxPlusBold.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: snap.connectionState != ConnectionState.done
                    ? const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Text(
                        t?.title ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: mText(18, weight: FontWeight.w600, color: mStepMid),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _messageBox() {
    return Container(
      height: 135,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mTr(context, 'Message', 'הודעה'), style: mText(13, weight: FontWeight.w500)),
          const SizedBox(height: 13),
          Expanded(
            child: TextField(
              controller: _message,
              maxLines: null,
              expands: true,
              maxLength: 1000,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepInk, height: 1.4),
              decoration: InputDecoration(
                hintText: mTr(
                  context,
                  'Tell us anything about your promotion request.',
                  'ספרו לנו כל דבר על בקשת הקידום.',
                ),
                hintMaxLines: 3,
                hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: mStepGrey),
                // The database keeps a thousand characters; the counter
                // would only clutter a box this size.
                counterText: '',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Earlier requests for this item, newest first, so the owner can see
  /// what was asked and what the panel decided.
  Widget _history() {
    final all = ref.watch(myPromotionRequestsProvider).valueOrNull ?? const <PromotionRequest>[];
    final mine = [
      for (final r in all)
        if (r.entityId == widget.id && r.entityType == widget.type) r,
    ];
    if (mine.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mTr(context, 'Earlier requests', 'בקשות קודמות'), style: mText(13, weight: FontWeight.w500, color: mStepGrey)),
          const SizedBox(height: 8),
          for (final r in mine)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: _statusColor(r.status), shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_daysLabel(r.days)} · ${_statusLabel(r)}',
                      style: mText(12.5, color: const Color(0xFF3D3D3D), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'approved' => mKitGreen,
    'pending' => mKitOrange,
    'declined' => mKitRed,
    _ => mStepGrey,
  };

  String _statusLabel(PromotionRequest r) {
    final reason = (r.reason ?? '').trim();
    return switch (r.status) {
      'pending' => mTr(context, 'Pending', 'ממתין לאישור'),
      'approved' when r.endsAt != null => mTr(
        context,
        'Approved until ${mDate(context, r.endsAt!.toLocal())}',
        'אושר עד ${mDate(context, r.endsAt!.toLocal())}',
      ),
      'approved' => mTr(context, 'Approved', 'אושר'),
      'declined' when reason.isNotEmpty => mTr(context, 'Declined ($reason)', 'נדחה ($reason)'),
      'declined' => mTr(context, 'Declined', 'נדחה'),
      _ => mTr(context, 'Cancelled', 'בוטל'),
    };
  }

  /// After sending: the green tick of the published pages, and a word on
  /// what happens next.
  Widget _sentPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text(mTr(context, 'Request sent', 'הבקשה נשלחה'), textAlign: TextAlign.center, style: mHeading(22)),
                          const SizedBox(height: 8),
                          Text(
                            mTr(
                              context,
                              "The Modiin4u team will review it. You'll get a notification when it is approved or declined.",
                              'צוות Modiin4u יבדוק אותה. תקבלו התראה כשהיא תאושר או תידחה.',
                            ),
                            textAlign: TextAlign.center,
                            style: mText(14, color: mStepGrey, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  MButton(label: mTr(context, 'Done', 'סיום'), onTap: () => context.back(_fallback)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
