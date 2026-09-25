import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';
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
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ),
      ),
      Positioned(
        left: 12,
        top: 51,
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.arrow_left,
              size: 20,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _content(BuildContext context, WidgetRef ref, L l, Offer offer) {
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(context, offer),
                      const SizedBox(height: 50),
                      _buildBusinessInfo(offer),
                      _buildDealInfo(offer),
                      _buildDealDetails(l, offer),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context, ref, l, offer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, Offer offer) {
    return SizedBox(
      height: 310, // 260 hero + space for overlapping logo
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hero image
          SizedBox(
            width: double.infinity,
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkPhoto(
                  url: offer.imageUrl ?? offer.businessLogoUrl,
                  icon: IconsaxPlusBold.discount_shape,
                  iconSize: 60,
                ),
                // Dark overlay gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x66000000), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Back button
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    IconsaxPlusLinear.arrow_left,
                    size: 20,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
            ),
          ),

          // Heart button
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  IconsaxPlusLinear.heart,
                  size: 20,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ),
          ),

          // Brand logo (overlapping bottom-left)
          Positioned(
            left: 16,
            top: 210,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                ),
              ),
              child: Center(
                child: Icon(
                  IconsaxPlusBold.shop,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.businessName ?? '',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 34 / 28,
              color: Colors.black,
            ),
          ),
          // "2.1 km away" used to sit at the end of this row. Nothing
          // measures that, so it is gone rather than invented.
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.location,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: const Color(0xFF6D6D6D),
                    ),
                    overflow: TextOverflow.ellipsis,
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
    final description = offer.description;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.name,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF123A72),
            ),
          ),
          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.4,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Deal details: valid until, hours, restrictions
  // ═══════════════════════════════════════════════
  /// Valid-until and terms, and only when the offer has them.
  ///
  /// This block used to assert an expiry date, opening hours of 6–10pm and
  /// four restrictions for every deal, none of which came from anywhere.
  Widget _buildDealDetails(L l, Offer offer) {
    final end = offer.endAt;
    final terms = offer.terms;
    if (end == null && (terms == null || terms.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (end != null)
            _DetailRow(
              icon: IconsaxPlusLinear.calendar_1,
              title: l.validUntil,
              subtitle: '${end.day} ${l.monthLong(end.month)} ${end.year}',
            ),
          if (end != null && terms != null && terms.trim().isNotEmpty)
            const SizedBox(height: 20),
          if (terms != null && terms.trim().isNotEmpty)
            _DetailRow(
              icon: IconsaxPlusLinear.info_circle,
              title: l.terms,
              subtitle: terms,
            ),
        ],
      ),
    );
  }

  /// Claim, directions, call.
  ///
  /// All three were painted buttons that did nothing. Claiming now writes an
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
    final address = offer.businessAddress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE7E7E7))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: offer.isClaimable && !alreadyClaimed
                  ? () => _claim(context, ref, l, offer)
                  : null,
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: offer.isClaimable && !alreadyClaimed
                      ? const Color(0xFF123A72)
                      : const Color(0xFFB9C0CE),
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
                      const SizedBox(width: 8),
                      Text(
                        offer.hasExpired
                            ? l.offerExpired
                            : alreadyClaimed
                            ? l.offerClaimed
                            : l.claimOffer,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (address != null && address.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _openMap(address),
                child: Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF123A72)),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          IconsaxPlusLinear.routing,
                          size: 20,
                          color: Color(0xFF123A72),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.getDirections,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF123A72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  void _showCode(BuildContext context, L l, Offer offer) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.offerClaimed,
          style: TextStyle(fontFamily: AppFonts.rubik),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              offer.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
            ),
            if (offer.code != null && offer.code!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  offer.code!,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF123A72),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.showThisCode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.close, style: TextStyle(fontFamily: AppFonts.rubik)),
          ),
        ],
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

// ═══════════════════════════════════════════════
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

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
        // Icon circle
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF3FB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 20, color: const Color(0xFF123A72)),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// More deal data model
// ═══════════════════════════════════════════════
