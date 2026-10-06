import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';
import '../widgets/m_deal_card.dart';

/// The resident's voucher for a deal they claimed — what they show at the
/// till, and where they use it.
///
/// Claiming used to end at a dialog with the deal's one code (none of the live
/// deals has one), and nothing after it: no way to mark the deal used, so
/// every claim stayed "claimed". The voucher carries the claim's own code
/// (00056), the resident's name and when it was claimed, and a clock that
/// runs, so the staff are looking at the live app and not a screenshot. At the
/// till the resident slides "Use now" in front of them (the client's choice,
/// 6 Oct); the voucher then says when it was used, for good.
class DealVoucherScreen extends ConsumerStatefulWidget {
  final Offer offer;
  const DealVoucherScreen({super.key, required this.offer});

  static Future<void> open(BuildContext context, Offer offer) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => DealVoucherScreen(offer: offer),
        ),
      );

  @override
  ConsumerState<DealVoucherScreen> createState() => _DealVoucherScreenState();
}

class _DealVoucherScreenState extends ConsumerState<DealVoucherScreen> {
  late final Timer _tick;
  DateTime _now = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';
  String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  Future<void> _use(String claimId) async {
    final he = mDealsIsHebrew(context);
    String t(String en, String hebrew) => he ? hebrew : en;
    setState(() => _busy = true);
    String? problem;
    try {
      await ref.read(offerRepositoryProvider).redeem(claimId);
      ref.invalidate(myClaimsProvider);
      ref.invalidate(offerByIdProvider(widget.offer.id));
      await ref.read(myClaimsProvider.future);
    } on StateError catch (e) {
      problem = switch (e.message) {
        'claim-used' => t('This voucher was already used.', 'השובר כבר מומש.'),
        'offer-ended' => t('This deal has ended.', 'המבצע הסתיים.'),
        'account-blocked' => t('This account is blocked.', 'החשבון חסום.'),
        _ => t('Using vouchers is not available yet.', 'מימוש שוברים עדיין לא זמין.'),
      };
      ref.invalidate(myClaimsProvider);
    } catch (_) {
      problem = t('That did not work. Check the connection and try again.',
          'הפעולה לא הצליחה. בדקו את החיבור ונסו שוב.');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final claim = ref.watch(myClaimsProvider).valueOrNull?[offer.id];
    final me = ref.watch(authProvider);
    final code = (claim?.code?.isNotEmpty ?? false) ? claim!.code! : offer.code?.trim();
    final dealCode = offer.code?.trim();
    final used = claim?.redeemed ?? false;
    final ended = offer.hasExpired;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        title: Text(mDealsT(context, 'My voucher', 'השובר שלי'), style: mDealsInter(16, weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: claim == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            NetworkPhoto(
                              url: offer.businessLogoUrl,
                              width: 48,
                              height: 48,
                              radius: BorderRadius.circular(24),
                              icon: IconsaxPlusBold.shop,
                              iconSize: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(offer.businessName ?? '',
                                  style: mDealsInter(15, weight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(offer.name, style: mDealsDisplay(22, color: AppColors.midBlue)),
                        const SizedBox(height: 20),
                        if (code != null && code.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: used ? const Color(0xFFF1F1F1) : const Color(0xFFEEF3FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SelectableText(
                              code,
                              style: mDealsInter(30, weight: FontWeight.w700,
                                  color: used ? kMDealsMuted : AppColors.midBlue).copyWith(letterSpacing: 4),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (dealCode != null && dealCode.isNotEmpty && dealCode != code)
                          _row(mDealsT(context, 'Deal code', 'קוד המבצע'), dealCode),
                        if (me != null) _row(mDealsT(context, 'Name', 'שם'), me.name),
                        _row(mDealsT(context, 'Claimed', 'נלקח'), '${_date(claim.createdAt)}, ${_time(claim.createdAt)}'),
                        if (offer.endAt != null)
                          _row(mDealsT(context, 'Valid until', 'בתוקף עד'), _date(offer.endAt!.toLocal())),
                        const SizedBox(height: 16),
                        const Divider(color: kMDealsLine, height: 1),
                        const SizedBox(height: 16),
                        if (used)
                          _status(
                            IconsaxPlusBold.tick_circle,
                            const Color(0xFF0E7E4B),
                            mDealsT(context, 'Used', 'מומש'),
                            claim.redeemedAt == null
                                ? null
                                : mDealsT(context, 'on ${_date(claim.redeemedAt!)} at ${_time(claim.redeemedAt!)}',
                                    'ב-${_date(claim.redeemedAt!)} בשעה ${_time(claim.redeemedAt!)}'),
                          )
                        else if (ended)
                          _status(IconsaxPlusBold.close_circle, kMDealsMuted,
                              mDealsT(context, 'This deal has ended', 'המבצע הסתיים'), null)
                        else ...[
                          // The running clock: the staff see a live screen.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _Pulse(),
                              const SizedBox(width: 8),
                              Text('${_time(_now)}:${_two(_now.second)}',
                                  style: mDealsInter(15, weight: FontWeight.w600, color: kMDealsNavy)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _SlideToUse(
                            label: mDealsT(context, 'Slide to use now', 'החליקו למימוש עכשיו'),
                            busy: _busy,
                            onDone: () => _use(claim.id),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            mDealsT(context, 'Slide in front of the staff when you pay. A voucher can be used once.',
                                'החליקו מול הצוות בזמן התשלום. ניתן לממש את השובר פעם אחת.'),
                            textAlign: TextAlign.center,
                            style: mDealsInter(12, color: kMDealsMuted, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(label, style: mDealsInter(13, color: kMDealsMuted)),
        const SizedBox(width: 12),
        Expanded(
          // Dates and codes run left to right in Hebrew too: laid out
          // right to left, "6.10.2026, 15:39" came out "15:39 ,6.10.2026".
          // Against the outer edge, whichever side that is.
          child: Text(value,
              textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.left : TextAlign.right,
              textDirection: RegExp(r'[\u0590-\u05FF]').hasMatch(value) ? null : TextDirection.ltr,
              style: mDealsInter(13, weight: FontWeight.w500, color: kMDealsNavy)),
        ),
      ],
    ),
  );

  Widget _status(IconData icon, Color color, String title, String? detail) => Column(
    children: [
      Icon(icon, color: color, size: 40),
      const SizedBox(height: 8),
      Text(title, style: mDealsInter(18, weight: FontWeight.w700, color: color)),
      if (detail != null) ...[
        const SizedBox(height: 4),
        Text(detail, style: mDealsInter(13, color: kMDealsMuted)),
      ],
    ],
  );
}

/// A dot that keeps pulsing beside the clock.
class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.25, end: 1.0).animate(_c),
    child: Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(color: Color(0xFF0E7E4B), shape: BoxShape.circle),
    ),
  );
}

/// "Slide to use": the thumb must travel the whole track, so a stray tap in a
/// pocket does not use the voucher. Follows the reading direction.
class _SlideToUse extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback onDone;
  const _SlideToUse({required this.label, required this.busy, required this.onDone});

  @override
  State<_SlideToUse> createState() => _SlideToUseState();
}

class _SlideToUseState extends State<_SlideToUse> {
  static const _thumb = 52.0;
  double _x = 0; // 0..1

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, box) {
        final travel = box.maxWidth - _thumb - 8;
        return GestureDetector(
          onHorizontalDragUpdate: widget.busy
              ? null
              : (d) => setState(() {
                  final dx = rtl ? -d.delta.dx : d.delta.dx;
                  _x = (_x + dx / travel).clamp(0.0, 1.0);
                }),
          onHorizontalDragEnd: widget.busy
              ? null
              : (_) {
                  if (_x > 0.9) {
                    setState(() => _x = 1);
                    widget.onDone();
                  } else {
                    setState(() => _x = 0);
                  }
                },
          child: Container(
            height: _thumb + 8,
            decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
            child: Stack(
              children: [
                Center(
                  child: widget.busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(widget.label, style: mDealsInter(15, weight: FontWeight.w600, color: Colors.white)),
                ),
                PositionedDirectional(
                  start: 4 + travel * _x,
                  top: 4,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(rtl ? IconsaxPlusLinear.arrow_left : IconsaxPlusLinear.arrow_right,
                        color: AppColors.midBlue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(_SlideToUse old) {
    super.didUpdateWidget(old);
    // A failed attempt puts the thumb back.
    if (old.busy && !widget.busy) _x = 0;
  }
}
