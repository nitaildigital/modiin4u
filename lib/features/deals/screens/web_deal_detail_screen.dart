import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Deal Detail — /deal/:id
//
// The design has no frame for one deal, so this page is built from the Deals
// frame's card and the business page's layout: the photograph and what the
// deal says on the wide side, and on the narrow side a card with the business,
// the headline, the time left and what to do next.
//
// Claiming takes an account, and the client has decided accounts belong to
// the app. So the page says where to claim it rather than offering a button
// that could only ask the visitor to sign in to something the site does not
// have. The code is not printed here either: it is what a claim hands over.
// ═══════════════════════════════════════════════════════════

const _kAsset = 'assets/web/deals';
const _kLine = Color(0xFFE7E7E7);
const _kHeading = Color(0xFF1C1C1E);
const _kGrey = Color(0xFF5F5E5A);
const _kMuted = Color(0xFF6D6D6D);
const _kBody = Color(0xFF3D3D3D);
const _kOrange = Color(0xFFFB7901);
const _kTint = Color(0xFFEEF3FB);

TextStyle _display(double size, {Color color = AppColors.midBlue, double? height}) =>
    TextStyle(fontFamily: AppFonts.nunito, fontSize: size, fontWeight: FontWeight.w600, color: color, height: height);

TextStyle _inter(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.black, double? height}) =>
    TextStyle(fontFamily: AppFonts.inter, fontSize: size, fontWeight: weight, color: color, height: height);

final _hebrew = RegExp(r'[֐-׿]');
TextDirection _dirOf(String s) => _hebrew.hasMatch(s) ? TextDirection.rtl : TextDirection.ltr;

/// Database text keeps its own direction but starts where the page starts.
TextAlign _alignOf(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left;

class WebDealDetailContent extends ConsumerStatefulWidget {
  final String dealId;
  const WebDealDetailContent({super.key, required this.dealId});

  @override
  ConsumerState<WebDealDetailContent> createState() => _WebDealDetailContentState();
}

class _WebDealDetailContentState extends ConsumerState<WebDealDetailContent>
    with WebLanguageState<WebDealDetailContent> {
  bool get _isHebrew => webIsHebrew.value;

  String _t(String en, String he) => _isHebrew ? he : en;

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsHe = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];

  String _longDate(DateTime d) {
    final local = d.toLocal();
    final month = (_isHebrew ? _monthsHe : _monthsEn)[local.month - 1];
    return _isHebrew ? '${local.day} ב$month ${local.year}' : '$month ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(offerByIdProvider(widget.dealId));

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'deals',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    async.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 160),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      // A failed request and a missing row are different
                      // things: one is worth trying again, the other is not.
                      error: (_, _) => _buildNotice(
                        icon: IconsaxPlusLinear.wifi_square,
                        title: _t('This deal could not be loaded', 'לא ניתן לטעון את המבצע'),
                        body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
                        actionLabel: _t('Try again', 'נסו שוב'),
                        onAction: () => ref.invalidate(offerByIdProvider(widget.dealId)),
                      ),
                      data: (offer) => offer == null
                          ? _buildNotice(
                              icon: IconsaxPlusLinear.discount_shape,
                              title: _t('This offer could not be found', 'המבצע לא נמצא'),
                              body: _t('This deal has ended, or the address is wrong.', 'המבצע הסתיים, או שהכתובת שגויה.'),
                              actionLabel: _t('Back to Deals', 'חזרה למבצעים'),
                              onAction: () => context.go('/deals'),
                            )
                          : _buildBody(offer),
                    ),
                    const SizedBox(height: 120),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Offer offer) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackLink(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, c) {
                final main = _buildMain(offer);
                final side = _buildSideCard(offer);
                if (c.maxWidth < 1000) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [side, const SizedBox(height: 40), main],
                  );
                }
                // The business page's proportions: the wide column, then 136
                // at full width (48 on a laptop), then a 376 card.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: main),
                    SizedBox(width: c.maxWidth >= 1500 ? 136 : 48),
                    SizedBox(width: 376, child: side),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/deals'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.flip(
              flipX: !_isHebrew,
              child: SvgPicture.asset('$_kAsset/arrow20.svg', width: 20, height: 20),
            ),
            const SizedBox(width: 8),
            Text(_t('Back to Deals', 'חזרה למבצעים'), style: _inter(15, weight: FontWeight.w500, color: AppColors.midBlue)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // THE WIDE SIDE — photograph, what the deal is, its terms
  // ─────────────────────────────────────────────
  Widget _buildMain(Offer offer) {
    final description = (offer.description ?? '').trim();
    final terms = (offer.terms ?? '').trim();
    final badge = offer.badge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 460,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkPhoto(
                  url: offer.imageUrl ?? offer.businessCoverUrl,
                  icon: IconsaxPlusBold.discount_shape,
                  iconSize: 72,
                ),
                if (badge != null || offer.hasExpired)
                  PositionedDirectional(
                    top: 20,
                    start: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: offer.hasExpired ? Colors.white : _kOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        offer.hasExpired ? _t('This offer has ended', 'המבצע הסתיים') : badge!,
                        textDirection: offer.hasExpired ? null : _dirOf(badge!),
                        style: _inter(18,
                            weight: FontWeight.w600,
                            color: offer.hasExpired ? const Color(0xFFCB3E3C) : Colors.white,
                            height: 1.21),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 56),
          Text(_t('About this deal', 'על המבצע'), style: _display(24)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(description, textDirection: _dirOf(description), style: _inter(16, color: _kBody, height: 1.6)),
          ),
        ],
        if (terms.isNotEmpty) ...[
          const SizedBox(height: 56),
          Text(_t('Terms & Conditions', 'תנאים והגבלות'), style: _display(24)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(terms, textDirection: _dirOf(terms), style: _inter(16, color: _kBody, height: 1.6)),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // THE NARROW SIDE — the business, the headline, the clock, what next
  // ─────────────────────────────────────────────
  Widget _buildSideCard(Offer offer) {
    final timeLeft = offer.timeLeftLabel(isHebrew: _isHebrew);
    final place = offer.businessAddress ?? offer.businessNeighborhood;
    final end = offer.endAt;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.businessName != null)
            MouseRegion(
              cursor: offer.businessId == null ? MouseCursor.defer : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: offer.businessId == null ? null : () => context.push('/business/${offer.businessId}'),
                child: Row(
                  children: [
                    _LogoRing(url: offer.businessLogoUrl, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.businessName!,
                              textDirection: _dirOf(offer.businessName!),
                              textAlign: _alignOf(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(16, weight: FontWeight.w600, color: _kHeading)),
                          if (offer.businessNeighborhood != null) ...[
                            const SizedBox(height: 4),
                            Text(offer.businessNeighborhood!,
                                textDirection: _dirOf(offer.businessNeighborhood!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _inter(14, color: _kGrey)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(offer.name, textDirection: _dirOf(offer.name), textAlign: _alignOf(context), style: _inter(26, weight: FontWeight.w600, color: AppColors.midBlue, height: 1.25)),
          if (timeLeft != null || offer.isResidentsOnly) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (timeLeft != null) ...[
                  SvgPicture.asset('$_kAsset/card_clock.svg', width: 20, height: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeLeft, textDirection: TextDirection.ltr, style: _inter(16, weight: FontWeight.w600, color: AppColors.navy, height: 1.19)),
                      const SizedBox(height: 2),
                      Text(_t('Time Left', 'זמן שנותר'), style: _inter(12, color: _kGrey, height: 1.25)),
                    ],
                  ),
                  const SizedBox(width: 44),
                ],
                if (offer.isResidentsOnly) ...[
                  SvgPicture.asset('$_kAsset/card_lock.svg', width: 20, height: 20),
                  const SizedBox(width: 8),
                  Text(_t('Residents Only', 'לתושבים בלבד'), style: _inter(12, weight: FontWeight.w600, color: _kOrange, height: 1.25)),
                ],
              ],
            ),
          ],
          if (end != null || offer.pointsRequired > 0 || place != null) ...[
            const SizedBox(height: 24),
            const Divider(height: 1, color: _kLine),
            const SizedBox(height: 24),
            if (end != null)
              _FactRow(icon: IconsaxPlusLinear.calendar_1, label: _t('Valid Until', 'בתוקף עד'), value: _longDate(end)),
            if (offer.pointsRequired > 0) ...[
              if (end != null) const SizedBox(height: 20),
              _FactRow(
                icon: IconsaxPlusLinear.medal_star,
                label: _t('Points', 'נקודות'),
                value: _t('${offer.pointsRequired} points', '${offer.pointsRequired} נקודות'),
              ),
            ],
            if (place != null) ...[
              if (end != null || offer.pointsRequired > 0) const SizedBox(height: 20),
              _FactRow(icon: IconsaxPlusLinear.location, label: _t('Location', 'מיקום'), value: place),
            ],
          ],
          const SizedBox(height: 28),
          // Where the deal is claimed, in place of a button the site cannot
          // honour: claiming needs an account, and accounts are in the app.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kTint, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(IconsaxPlusLinear.mobile, size: 22, color: AppColors.midBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('Claim it in the Modiin4u app', 'מממשים באפליקציית מודיעין בשבילך'),
                          style: _inter(15, weight: FontWeight.w600, color: AppColors.midBlue)),
                      const SizedBox(height: 4),
                      Text(
                        _t('The app gives you the code to show at the business.', 'האפליקציה נותנת את הקוד להצגה בבית העסק.'),
                        style: _inter(14, color: _kBody, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (offer.businessId != null) ...[
            const SizedBox(height: 16),
            _PillButton(
              label: _t('View Business', 'לעמוד העסק'),
              filled: true,
              onTap: () => context.push('/business/${offer.businessId}'),
            ),
          ],
          if (place != null) ...[
            const SizedBox(height: 12),
            _PillButton(
              label: _t('Get Directions', 'ניווט'),
              filled: false,
              onTap: () => launchUrl(
                Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(offer.businessAddress ?? place)}'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: WebSection(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
          decoration: BoxDecoration(border: Border.all(color: _kLine), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Icon(icon, size: 44, color: _kMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: _display(20, color: AppColors.navy)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: _inter(14, color: _kGrey)),
              const SizedBox(height: 24),
              _PillButton(label: actionLabel, filled: true, onTap: onAction, shrink: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PIECES
// ═══════════════════════════════════════════════

class _LogoRing extends StatelessWidget {
  final String? url;
  final double size;
  const _LogoRing({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.0488),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _kLine, width: 0.878),
      ),
      child: NetworkPhoto(url: url, radius: BorderRadius.circular(size), icon: IconsaxPlusBold.shop, iconSize: size * 0.3),
    );
  }
}

/// A fact about the deal: a tinted round icon, its name, its value.
class _FactRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _FactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: _kTint, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 20, color: AppColors.midBlue)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _inter(14, color: _kMuted)),
              const SizedBox(height: 4),
              Text(value, textDirection: _dirOf(value), textAlign: _alignOf(context), style: _inter(15, weight: FontWeight.w500, color: Colors.black, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final bool filled;
  final bool shrink;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.filled, required this.onTap, this.shrink = false});

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final solid = widget.filled || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.shrink ? null : double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: solid ? AppColors.midBlue : Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Text(widget.label,
              style: _inter(16, weight: FontWeight.w500, color: solid ? Colors.white : AppColors.midBlue, height: 1.5)),
        ),
      ),
    );
  }
}
