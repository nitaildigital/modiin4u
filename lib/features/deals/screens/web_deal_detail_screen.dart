import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
// Web Deal Detail — desktop layout for /deal/:id
//
// The mobile page is a 260px hero with the offer stacked underneath it and the
// claim button pinned to the bottom of the viewport. On a laptop the two halves
// sit side by side: the photograph, the business and the headline on one side,
// the terms and the claim on the other, so the action is above the fold.
//
// `offers` has no rows, so this page is only reachable once the client loads a
// deal in the admin panel. Until then the states that matter are the ones for
// a deal that cannot be loaded or no longer exists, and those are what the
// page shows rather than a sample offer.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kIconGrey = Color(0xFF6D6D6D);
const _kDetailBg = Color(0xFFEEF3FB);

class WebDealDetailContent extends ConsumerStatefulWidget {
  final String dealId;
  const WebDealDetailContent({super.key, required this.dealId});

  @override
  ConsumerState<WebDealDetailContent> createState() =>
      _WebDealDetailContentState();
}

class _WebDealDetailContentState extends ConsumerState<WebDealDetailContent> {
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsHe = [
    'ינואר',
    'פברואר',
    'מרץ',
    'אפריל',
    'מאי',
    'יוני',
    'יולי',
    'אוגוסט',
    'ספטמבר',
    'אוקטובר',
    'נובמבר',
    'דצמבר',
  ];

  String _longDate(DateTime d) {
    final month = (_isHebrew ? _monthsHe : _monthsEn)[d.month - 1];
    return _isHebrew
        ? '${d.day} ב$month ${d.year}'
        : '${d.day} $month ${d.year}';
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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
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
                        title: _t(
                          'This deal could not be loaded',
                          'לא ניתן לטעון את המבצע',
                        ),
                        body: _t(
                          'Check your connection and try again.',
                          'בדקו את החיבור לאינטרנט ונסו שוב.',
                        ),
                        actionLabel: _t('Try again', 'נסו שוב'),
                        onAction: () =>
                            ref.invalidate(offerByIdProvider(widget.dealId)),
                      ),
                      data: (offer) => offer == null
                          ? _buildNotice(
                              icon: IconsaxPlusLinear.discount_shape,
                              title: _t(
                                'This offer could not be found',
                                'המבצע לא נמצא',
                              ),
                              body: _t(
                                'This deal has ended, or the address is wrong.',
                                'המבצע הסתיים, או שהכתובת שגויה.',
                              ),
                              actionLabel: _t('Back to Deals', 'חזרה למבצעים'),
                              onAction: () => context.go('/deals'),
                            )
                          : _buildBody(offer),
                    ),
                    const SizedBox(height: 100),
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

  // ─────────────────────────────────────────────
  // THE TWO COLUMNS
  // ─────────────────────────────────────────────
  Widget _buildBody(Offer offer) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1248),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackLink(),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final side = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhoto(offer),
                        const SizedBox(height: 28),
                        _buildBusiness(offer),
                      ],
                    );
                    final terms = _buildTermsCard(offer);

                    // Side by side at 1100 and above, which is every width
                    // this layout is reached at; the stacked form is here for
                    // the narrower window a desktop browser can still be at.
                    if (constraints.maxWidth < 900) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [side, const SizedBox(height: 32), terms],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: side),
                        const SizedBox(width: 40),
                        SizedBox(width: 420, child: terms),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
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
            Icon(
              _isHebrew
                  ? IconsaxPlusLinear.arrow_right_3
                  : IconsaxPlusLinear.arrow_left,
              size: 20,
              color: AppColors.midBlue,
            ),
            const SizedBox(width: 8),
            Text(
              _t('Back to Deals', 'חזרה למבצעים'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.midBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(Offer offer) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(
              url: offer.imageUrl ?? offer.businessLogoUrl,
              icon: IconsaxPlusBold.discount_shape,
              iconSize: 72,
            ),
            // The same wash the mobile hero carries, so a pale photograph
            // still holds the white badge below it.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x66000000), Colors.transparent],
                ),
              ),
            ),
            if (offer.hasExpired)
              PositionedDirectional(
                start: 20,
                top: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _t('This offer has ended', 'המבצע הסתיים'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFCB3E3C),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The business the deal belongs to. A logo, a name and an address — and
  /// nothing at all where the row is silent, rather than an empty line.
  Widget _buildBusiness(Offer offer) {
    final name = offer.businessName;
    final address = offer.businessAddress;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: NetworkPhoto(
              url: offer.businessLogoUrl,
              icon: IconsaxPlusBold.shop,
              iconSize: 34,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null && name.isNotEmpty)
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.25,
                  ),
                ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.location,
                      size: 18,
                      color: _kIconGrey,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        address,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 15,
                          color: _kGreyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (offer.businessId != null) ...[
                const SizedBox(height: 14),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/business/${offer.businessId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t('View the business', 'לעמוד העסק'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.midBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.midBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // THE TERMS AND THE ACTION
  // ─────────────────────────────────────────────
  Widget _buildTermsCard(Offer offer) {
    final description = offer.description;
    final end = offer.endAt;
    final terms = offer.terms;
    final address = offer.businessAddress;
    final claimed =
        ref.watch(myClaimedOfferIdsProvider).valueOrNull ?? const <String>{};
    final alreadyClaimed = claimed.contains(offer.id);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.name,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
              height: 1.25,
            ),
          ),
          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                height: 1.5,
                color: _kGreyText,
              ),
            ),
          ],
          if (end != null || (terms != null && terms.trim().isNotEmpty)) ...[
            const SizedBox(height: 24),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 24),
            if (end != null)
              _DetailRow(
                icon: IconsaxPlusLinear.calendar_1,
                title: _t('Valid Until', 'בתוקף עד'),
                subtitle: _longDate(end),
              ),
            if (end != null && terms != null && terms.trim().isNotEmpty)
              const SizedBox(height: 20),
            if (terms != null && terms.trim().isNotEmpty)
              _DetailRow(
                icon: IconsaxPlusLinear.info_circle,
                title: _t('Terms', 'תנאים'),
                subtitle: terms,
              ),
          ],
          const SizedBox(height: 28),
          _buildClaimButton(offer, alreadyClaimed),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDirectionsButton(address),
          ],
        ],
      ),
    );
  }

  Widget _buildClaimButton(Offer offer, bool alreadyClaimed) {
    final live = offer.isClaimable && !alreadyClaimed;

    return MouseRegion(
      cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: live ? () => _claim(offer) : null,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: live ? AppColors.midBlue : const Color(0xFFB9C0CE),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconsaxPlusLinear.scan_barcode,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  offer.hasExpired
                      ? _t('This offer has ended', 'המבצע הסתיים')
                      : alreadyClaimed
                      ? _t('Offer claimed', 'המבצע נשמר')
                      : _t('Claim this offer', 'קבלת המבצע'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionsButton(String address) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openMap(address),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconsaxPlusLinear.routing,
                  size: 20,
                  color: AppColors.midBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  _t('Get Directions', 'ניווט'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CLAIMING — the same write the mobile page makes
  // ─────────────────────────────────────────────
  Future<void> _claim(Offer offer) async {
    try {
      await ref.read(offerRepositoryProvider).claim(offer);
      ref.invalidate(myClaimedOfferIdsProvider);
      if (!mounted) return;
      _showCode(offer);
    } on StateError catch (e) {
      if (!mounted) return;
      _toast(
        e.message == 'already-claimed'
            ? _t(
                'You have already claimed this offer',
                'כבר קיבלתם את המבצע הזה',
              )
            : _t('Sign in to claim this offer', 'התחברו כדי לקבל את המבצע'),
      );
    } catch (_) {
      if (mounted) {
        _toast(
          _t(
            'Could not save. Please try again.',
            'לא ניתן היה לשמור. נסו שוב.',
          ),
        );
      }
    }
  }

  void _showCode(Offer offer) {
    final code = offer.code;
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _t('Offer claimed', 'המבצע נשמר'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                offer.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15),
              ),
              if (code != null && code.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'Show this code at the business',
                    'הציגו את הקוד בבית העסק',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: _kIconGrey,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                _t('Close', 'סגירה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  color: AppColors.midBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static Future<void> _openMap(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1248),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 44,
                    color: _kIconGrey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: _kGreyText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onAction,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.midBlue,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ONE TERM — icon circle, label, value
// ═══════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: _kDetailBg,
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 20, color: AppColors.midBlue)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  height: 1.45,
                  color: _kGreyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
