import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../businesses/providers/business_providers.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';
import '../widgets/m_deal_card.dart';
import '../widgets/m_deal_detail_parts.dart';
import 'web_deal_detail_screen.dart';

/// One deal.
///
/// Every field on this page was fixed text about a restaurant that does not
/// exist: "Urban Plate Kitchen & Bar", a 20% discount, "Valid Until 30 August
/// 2026", opening hours of 6–10pm, a list of restrictions and three more
/// invented deals underneath. It showed the same page for whatever id the
/// route was given.
class DealDetailScreen extends StatelessWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebDealDetailContent(dealId: dealId);
        }
        return _MobileDealDetailContent(dealId: dealId);
      },
    );
  }
}

/// Figma mobile "Deal Details" (806:10899), from the offer's own row.
///
/// What the design draws and the database does not hold is left off rather
/// than invented: the distance ("2.1 km away") and the "Valid Days & Hours"
/// row. The restrictions are the offer's terms, one per line, after the
/// limits the admin set on it (residents only, one per person).
///
/// Claiming takes an account, and accounts belong to the app, so on the web
/// the page offers directions and a call but no "Redeem Deal".
class _MobileDealDetailContent extends ConsumerWidget {
  final String dealId;
  const _MobileDealDetailContent({required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final async = ref.watch(offerByIdProvider(dealId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _notFound(context, l),
        data: (offer) => offer == null
            ? _notFound(context, l)
            : _content(context, ref, l, offer),
      ),
    );
  }

  Widget _notFound(BuildContext context, L l) => Stack(
    children: [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.offerNotFound,
            textAlign: TextAlign.center,
            style: mDealsInter(15, color: kMDealsMuted),
          ),
        ),
      ),
      PositionedDirectional(
        start: 12,
        top: MediaQuery.paddingOf(context).top + 7,
        child: _backButton(context),
      ),
    ],
  );

  static Widget _backButton(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go('/deals'),
      child: Transform.flip(
        flipX: rtl,
        child: SvgPicture.asset('$kMDealIcon/m_deals_back.svg', width: 40, height: 40),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, L l, Offer offer) {
    final businessId = offer.businessId;
    final more = businessId == null
        ? const <Offer>[]
        : (ref.watch(activeOffersProvider).valueOrNull ?? const <Offer>[])
              .where((o) => o.businessId == businessId && o.id != offer.id && !o.hasExpired)
              .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context, ref, offer),
                    _buildBusinessInfo(offer),
                    _buildDealInfo(offer),
                    _buildDealDetails(context, l, offer),
                    if (more.isNotEmpty) _buildMore(offer, more),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, ref, l, offer),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Photograph, back, heart, "Show all photos", the business's mark
  // ═══════════════════════════════════════════════
  Widget _buildHero(BuildContext context, WidgetRef ref, Offer offer) {
    final top = MediaQuery.paddingOf(context).top;
    final businessId = offer.businessId;
    final gallery = businessId == null
        ? const <String>[]
        : ref.watch(businessGalleryProvider(businessId)).valueOrNull ?? const <String>[];

    return SizedBox(
      height: 310, // 260 photograph + the lower half of the 100 logo
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkPhoto(
                  url: offer.imageUrl ?? offer.businessCoverUrl,
                  icon: IconsaxPlusBold.discount_shape,
                  iconSize: 60,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x66000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ],
            ),
          ),

          PositionedDirectional(start: 12, top: top + 7, child: _backButton(context)),

          // The heart keeps the business in the person's saved places —
          // favourites have no kind for an offer — and needs an account, so
          // it is an app control.
          if (!kIsWeb && businessId != null)
            PositionedDirectional(
              end: 12,
              top: top + 7,
              child: _HeartButton(businessId: businessId),
            ),

          if (gallery.isNotEmpty)
            PositionedDirectional(
              end: 14,
              bottom: 50 + 14,
              child: GestureDetector(
                onTap: () => showMDealPhotos(context, gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('$kMDealIcon/m_deals_photos.svg', width: 14, height: 14),
                      const SizedBox(width: 8),
                      Text(
                        mDealsT(context, 'Show all photos', 'כל התמונות'),
                        style: mDealsInter(12, weight: FontWeight.w500, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          PositionedDirectional(
            start: 16,
            top: 210,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: NetworkPhoto(
                url: offer.businessLogoUrl,
                radius: BorderRadius.circular(50),
                icon: IconsaxPlusBold.shop,
                iconSize: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Business name + address
  // ═══════════════════════════════════════════════
  Widget _buildBusinessInfo(Offer offer) {
    final address = offer.businessAddress;
    final name = offer.businessName;
    if (name == null && address == null) return const SizedBox(height: 20);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kMDealsLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null) Text(name, style: mDealsDisplay(28, color: Colors.black)),
          // "2.1 km away" sat at the end of this row. Nothing measures that,
          // so it is left off rather than invented.
          if (address != null) ...[
            if (name != null) const SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset('$kMDealIcon/m_deals_location.svg', width: 16, height: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mDealsInter(14, color: kMDealsMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Deal title + description
  // ═══════════════════════════════════════════════
  Widget _buildDealInfo(Offer offer) {
    final description = offer.description?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.name,
            style: mDealsInter(20, weight: FontWeight.w600, color: AppColors.midBlue),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description, style: mDealsInter(14, color: kMDealsMuted, height: 1.4)),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Valid until, restrictions
  // ═══════════════════════════════════════════════
  /// This block used to assert an expiry date, opening hours of 6–10pm and
  /// four restrictions for every deal, none of which came from anywhere.
  Widget _buildDealDetails(BuildContext context, L l, Offer offer) {
    final end = offer.endAt?.toLocal();
    final restrictions = <String>[
      if (offer.isResidentsOnly)
        mDealsT(context, 'Registered residents only', 'לתושבים רשומים בלבד'),
      if (offer.maxPerUser == 1)
        mDealsT(context, 'One redemption per user', 'מימוש אחד למשתמש'),
      for (final line in (offer.terms ?? '').split('\n'))
        if (line.replaceFirst(RegExp(r'^\s*[-•*·]\s*'), '').trim().isNotEmpty)
          line.replaceFirst(RegExp(r'^\s*[-•*·]\s*'), '').trim(),
    ];
    if (end == null && restrictions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (end != null)
            MDealFactRow(
              icon: 'm_deals_valid_until.svg',
              title: l.validUntil,
              body: MDealFactText('${end.day} ${l.monthLong(end.month)} ${end.year}'),
            ),
          if (end != null && restrictions.isNotEmpty) const SizedBox(height: 20),
          if (restrictions.isNotEmpty)
            MDealFactRow(
              icon: 'm_deals_restrictions.svg',
              title: mDealsT(context, 'Restrictions', 'הגבלות'),
              body: MDealBullets(restrictions),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // More Deals from <business>
  // ═══════════════════════════════════════════════
  Widget _buildMore(Offer offer, List<Offer> more) {
    return Builder(
      builder: (context) {
        final name = offer.businessName;
        return Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  name == null
                      ? mDealsT(context, 'More Deals', 'מבצעים נוספים')
                      : mDealsT(context, 'More Deals from $name', 'מבצעים נוספים של $name'),
                  style: mDealsInter(16, weight: FontWeight.w600, color: const Color(0xFF1F1F1F)),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < more.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      MDealMiniCard(offer: more[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Redeem, directions, call.
  ///
  /// All three were painted buttons that did nothing. Redeeming writes an
  /// `offer_claims` row and shows the code; directions and calling are only
  /// offered when the business actually has an address or a number.
  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    L l,
    Offer offer,
  ) {
    final claimed =
        ref.watch(myClaimedOfferIdsProvider).valueOrNull ?? const <String>{};
    final alreadyClaimed = claimed.contains(offer.id);
    final canClaim = offer.isClaimable && !alreadyClaimed;
    final address = offer.businessAddress;
    final businessId = offer.businessId;
    final phone = businessId == null
        ? null
        : ref.watch(businessByIdProvider(businessId)).valueOrNull?.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasAddress = address != null && address.isNotEmpty;

    final secondary = <Widget>[
      if (hasAddress)
        Expanded(
          child: MDealActionButton(
            icon: 'm_deals_direction.svg',
            label: mDealsT(context, 'Get Direction', l.getDirections),
            onTap: () => _openMap(address),
          ),
        ),
      if (hasAddress && hasPhone) const SizedBox(width: 11),
      if (hasPhone)
        Expanded(
          child: MDealActionButton(
            icon: 'm_deals_call.svg',
            label: l.callBusiness,
            onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
          ),
        ),
    ];
    if (kIsWeb && secondary.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kMDealsLine)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!kIsWeb)
              MDealActionButton(
                icon: 'm_deals_redeem.svg',
                filled: true,
                enabled: canClaim,
                label: offer.hasExpired
                    ? l.offerExpired
                    : alreadyClaimed
                    ? l.offerClaimed
                    : mDealsT(context, 'Redeem Deal', 'מימוש המבצע'),
                onTap: () => _claim(context, ref, l, offer),
              ),
            if (!kIsWeb && secondary.isNotEmpty) const SizedBox(height: 16),
            if (secondary.isNotEmpty) Row(children: secondary),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(
    BuildContext context,
    WidgetRef ref,
    L l,
    Offer offer,
  ) async {
    try {
      await ref.read(offerRepositoryProvider).claim(offer);
      ref.invalidate(myClaimedOfferIdsProvider);
      if (!context.mounted) return;
      _showCode(context, l, offer);
    } on StateError catch (e) {
      if (!context.mounted) return;
      _toast(
        context,
        e.message == 'already-claimed' ? l.alreadyClaimed : l.signInToClaim,
      );
    } catch (_) {
      if (context.mounted) _toast(context, l.errCouldNotSave);
    }
  }

  /// What a claim hands over: the offer's own code, where it has one. The
  /// design draws no state for this, so it is the page's own pieces — the
  /// display face, the pale blue tint, the pill button.
  void _showCode(BuildContext context, L l, Offer offer) {
    final code = offer.code?.trim();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.offerClaimed,
                textAlign: TextAlign.center,
                style: mDealsDisplay(22, color: AppColors.midBlue),
              ),
              const SizedBox(height: 8),
              Text(
                offer.name,
                textAlign: TextAlign.center,
                style: mDealsInter(14, color: kMDealsMuted, height: 1.4),
              ),
              if (code != null && code.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.showThisCode,
                  textAlign: TextAlign.center,
                  style: mDealsInter(12, color: kMDealsMuted),
                ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    l.close,
                    style: mDealsInter(14, weight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String message) {
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
}

/// The white round heart on the photograph: saves the deal's business.
class _HeartButton extends ConsumerWidget {
  final String businessId;
  const _HeartButton({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      isFavoriteProvider((kind: FavoriteKind.business, id: businessId)),
    );
    return GestureDetector(
      onTap: () async {
        final l = L.of(context);
        try {
          final ok = await ref
              .read(favoritesProvider.notifier)
              .toggle(FavoriteKind.business, businessId);
          if (!ok && context.mounted) {
            _MobileDealDetailContent._toast(context, l.signInToSave);
          }
        } catch (_) {
          if (context.mounted) {
            _MobileDealDetailContent._toast(context, l.errCouldNotSave);
          }
        }
      },
      child: saved
          ? Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(IconsaxPlusBold.heart, size: 20, color: Color(0xFFE90052)),
            )
          : SvgPicture.asset('$kMDealIcon/m_deals_heart.svg', width: 40, height: 40),
    );
  }
}
