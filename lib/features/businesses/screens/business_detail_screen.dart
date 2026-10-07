import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/widgets/sign_in_action.dart';
import '../../../core/supabase/account_blocked.dart';
import '../../../shared/widgets/report_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../repositories/business_stats.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/error_retry.dart';
import '../models/menu_item.dart' as menu;
import '../../../shared/widgets/skeleton.dart';
import '../models/business.dart';
import '../models/review_reply.dart';
import '../providers/business_providers.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../../shared/widgets/network_photo.dart';
import 'web_business_detail_screen.dart';
import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../shared/widgets/web_chrome.dart' show WebFooter, WebNavbar, webIsHebrew;
import '../repositories/business_repository.dart' show BusinessNotFound;

class BusinessDetailScreen extends ConsumerWidget {
  final String businessId;

  /// From a notification: the review, and the reply under it, to open the
  /// Reviews tab at and mark.
  final String? focusReviewId;
  final String? focusReplyId;

  const BusinessDetailScreen({
    super.key,
    required this.businessId,
    this.focusReviewId,
    this.focusReplyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = businessByIdProvider(businessId);

    return ref
        .watch(provider)
        .when(
          loading: () => const _BusinessDetailSkeleton(),
          // A business that is not there is not a connection problem: a
          // retry can never find it. That page said "something went wrong,
          // check your internet" with a retry button, and on the website
          // without the navbar — a dead end for every old link.
          error: (error, _) => error is BusinessNotFound
              ? const _BusinessNotFound()
              : Scaffold(
                  backgroundColor: Colors.white,
                  body: SafeArea(
                    child: ErrorRetry(onRetry: () => ref.invalidate(provider)),
                  ),
                ),
          data: (business) => _BusinessDetailContent(
            business: business,
            focusReviewId: focusReviewId,
            focusReplyId: focusReplyId,
          ),
        );
  }
}

class _BusinessDetailContent extends ConsumerStatefulWidget {
  final Business business;
  final String? focusReviewId;
  final String? focusReplyId;

  const _BusinessDetailContent({
    required this.business,
    this.focusReviewId,
    this.focusReplyId,
  });

  @override
  ConsumerState<_BusinessDetailContent> createState() =>
      _BusinessDetailContentState();
}

class _BusinessDetailContentState
    extends ConsumerState<_BusinessDetailContent> {
  Business get business => widget.business;

  @override
  void initState() {
    super.initState();
    BusinessStats.record(business.id, BusinessStat.view);
    // Opened from a reply or review notification: straight to Reviews.
    if (widget.focusReviewId != null) _selectedTab = 3;
  }

  /// The review or reply a notification pointed at: keyed so the page can
  /// scroll to it once the list has loaded, and marked for a few seconds.
  final _focusKey = GlobalKey();
  bool _focusScrolled = false;
  bool _focusMarked = true;

  void _scrollToFocus() {
    if (_focusScrolled) return;
    _focusScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusKey.currentContext;
      // Not on screen yet — the list shown may be the one from before the
      // notification's reply existed (another page of this business kept it).
      // Try again on the next build.
      if (target == null) {
        _focusScrolled = false;
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 0.2,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _focusMarked = false);
      });
    });
  }

  /// Share, from the control on the photograph.
  void _shareBusiness() {
    BusinessStats.record(business.id, BusinessStat.share);
    Share.share(
      [
        business.name,
        business.description,
        business.address,
      ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
      subject: business.name,
    );
  }

  int _selectedTab = 0;

  /// The app is Hebrew-first; labels the shared ARB files do not carry yet
  /// are written in both languages here.
  bool get _isHe => Localizations.localeOf(context).languageCode == 'he';

  // Review creation state
  int _userRating = 0;
  bool _showReviewForm = false;
  bool _savingReview = false;
  final _reviewTextController = TextEditingController();

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  /// The language the desktop chrome is in. The mobile layout follows the
  /// app locale; the web pages each carry their own toggle, as the rest of
  /// the `web_*` screens do.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth > 1100
          ? _buildDesktop(context)
          : _buildMobile(context),
    );
  }

  /// Every business card on every desktop page opens this screen. Wide, it
  /// is the design's business page (web_business_detail_screen.dart).
  Widget _buildDesktop(BuildContext context) =>
      WebBusinessDetailContent(business: business);

  Widget _buildMobile(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image, with the logo half over its lower edge ──
            // The frame: a 260 photo, the 100 logo from y 210 to 310 and the
            // kosher chip 16 under the photo. The logo used to be pulled up
            // with a transform, which left its 50px of layout space behind as
            // a gap above the name.
            SizedBox(
              height: 310,
              child: Stack(
                children: [
                  _buildHero(topPadding),
                  PositionedDirectional(
                    start: 16,
                    top: 210,
                    child: _BusinessLogo(url: business.logoUrl, size: 100),
                  ),
                  PositionedDirectional(
                    end: 15,
                    top: 276,
                    child: _buildKosherChip(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Name + Subtitle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: TextStyle(
                      // "Avenir Next Rounded Pro Demi" in the frame.
                      fontFamily: AppFonts.nunito,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Its category, in the reader's language, as on the cards.
                  Text(
                    businessKind(
                      business,
                      ref.watch(businessPrimaryCategoryProvider).valueOrNull,
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Rating + Open status ──
            _buildRatingRow(),

            const SizedBox(height: 16),

            // ── Address row ──
            _buildAddressRow(),
            _buildNeighborhoodLink(),

            const SizedBox(height: 28),

            // ── Action buttons ──
            _buildActionButtons(),

            const SizedBox(height: 16),

            // ── Tab bar ──
            _buildTabBar(business),

            // ── Tab content (switches by selected tab) ──
            _buildTabContent(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Hero image with gradient overlay
  // ─────────────────────────────────────────────
  Widget _buildHero(double topPadding) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Cover photo, falling back to the brand gradient
          Container(
            width: double.infinity,
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF010A36), Color(0xFF0058B5)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (business.imageUrl != null && business.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: business.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SizedBox.shrink(),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                // Dark gradient overlay at bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Stands in for a missing photograph — and only then. It was
                // drawn unconditionally, so a restaurant bell sat in the
                // middle of every business's cover photo.
                if (business.imageUrl == null || business.imageUrl!.isEmpty)
                  Center(
                    child: Icon(
                      IconsaxPlusLinear.reserve,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),

          // Back button, share and heart sit by reading direction, so in
          // Hebrew the whole row mirrors and the arrow points right.
          PositionedDirectional(
            start: 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: AppIcons.back,
              onTap: () => context.back('/businesses'),
            ),
          ),

          // Share button
          PositionedDirectional(
            end: 56 + 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: IconsaxPlusLinear.export_1,
              onTap: _shareBusiness,
            ),
          ),

          // Favorite button
          PositionedDirectional(
            end: 12,
            top: topPadding + 7,
            child: FavoriteButton(
              kind: FavoriteKind.business,
              id: business.id,
              size: 40,
              iconSize: 20,
              color: const Color(0xFF3D3D3D),
            ),
          ),

          // "Show all photos" opens the Photos tab — and is drawn only for a
          // business whose gallery (entity_media, role 'gallery') has photos.
          if ((ref.watch(businessGalleryProvider(business.id)).valueOrNull ??
                  const <String>[])
              .isNotEmpty)
            PositionedDirectional(
              end: 13,
              bottom: 14,
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/web/business/gallery.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        L.of(context).showAllPhotos,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Kosher badge (the logo is placed in the hero's stack)
  // ─────────────────────────────────────────────
  /// Only when the business is certified; nothing otherwise.
  Widget _buildKosherChip() {
    // The certificate's Hebrew name ("מהדרין") in Hebrew; "Kosher" in English,
    // as the website has it.
    final certificate = business.kosherLabel;
    if (certificate == null) return const SizedBox.shrink();
    final label = _isHe ? certificate : L.of(context).kosher;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconsaxPlusLinear.verify,
            size: 14,
            color: AppColors.midBlue,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.midBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Rating + Open status row
  // ─────────────────────────────────────────────
  Widget _buildRatingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // A business nobody has reviewed says so, rather than showing a gold
          // star beside "0.0 (0)" — which reads as a bad score, not as none.
          if (business.reviewCount == 0)
            Text(
              L.of(context).notRatedYet,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
            )
          else ...[
            const Icon(
              IconsaxPlusBold.star_1,
              size: 16,
              color: Color(0xFFFFC107),
            ),
            const SizedBox(width: 6),
            Text(
              business.rating.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${business.reviewCount})',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],

          // Open or closed, but only when the business has hours on record.
          if (business.hours.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: business.isOpenNow
                    ? const Color(0xFF00BA00)
                    : AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                business.isOpenNow ? Icons.check : Icons.close,
                size: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              business.isOpenNow
                  ? L.of(context).openNow
                  : L.of(context).closed,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: business.isOpenNow
                    ? const Color(0xFF00BA00)
                    : AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Address row
  // ─────────────────────────────────────────────
  /// A link to the neighbourhood's own page.
  ///
  /// On its own line rather than appended to the address: addresses here run
  /// long and the row ellipsises, so a tail on that line is usually invisible
  /// and never tappable. Nothing in the app linked to `/neighborhood/:id`
  /// before this, so the screen existed and could not be reached.
  Widget _buildNeighborhoodLink() {
    final id = business.neighborhoodId;
    if (id == null || business.neighborhood.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/neighborhood/$id'),
        child: Row(
          children: [
            const Icon(
              IconsaxPlusLinear.buildings_2,
              size: 16,
              color: Color(0xFF123A72),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                business.neighborhood,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF123A72),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              IconsaxPlusLinear.arrow_left_2,
              size: 14,
              color: Color(0xFF123A72),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.location,
            size: 16,
            color: Color(0xFF888888),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                business.address,
                business.neighborhood,
              ].where((s) => s.isNotEmpty).join(', '),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Distance needs the device location, which is not wired up yet.
          Text(
            '',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Action buttons: Direction, then Call and Website
  // ─────────────────────────────────────────────
  /// The frame's row: a "Direction" pill at the start, the phone and web
  /// circles at the end. Share lives on the photograph (as in the frame);
  /// Instagram is not in the frame and is kept only for a business that has
  /// one, so its link is not lost.
  Widget _buildActionButtons() {
    final l = L.of(context);

    final direction = GestureDetector(
      onTap: () {
        BusinessStats.record(business.id, BusinessStat.directions);
        // A business with no location on record has 0,0 for one: Waze went
        // to the Gulf of Guinea. Then it searches the address instead.
        final hasPlace = business.latitude != 0 || business.longitude != 0;
        final address = business.address.trim();
        launchUrl(
          Uri.parse(
            hasPlace
                ? 'https://waze.com/ul?ll=${business.latitude},'
                      '${business.longitude}&navigate=yes'
                : 'https://waze.com/ul?q=${Uri.encodeComponent('$address, מודיעין')}&navigate=yes',
          ),
        );
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.midBlue,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/m_food_direction.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l.getDirections,
              maxLines: 1,
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
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          direction,
          const Spacer(),
          // A park has no phone, website or social page (the client's
          // rule for parks), so it keeps only the directions button.
          // Call and Website are drawn only when the business has them, as
          // WhatsApp and Instagram are; a greyed circle offered nothing.
          if (!business.isPark && (business.phone?.trim().isNotEmpty ?? false))
            _OutlineCircleButton(
              icon: IconsaxPlusLinear.call,
              color: AppColors.turquoise,
              onTap: () {
                BusinessStats.record(business.id, BusinessStat.call);
                launchUrl(Uri.parse('tel:${business.phone}'));
              },
            ),
          if (!business.isPark && (business.website?.trim().isNotEmpty ?? false)) ...[
            if (business.phone?.trim().isNotEmpty ?? false)
              const SizedBox(width: 12),
            _OutlineCircleButton(
              icon: IconsaxPlusLinear.global,
              color: AppColors.turquoise,
              onTap: () {
                BusinessStats.record(business.id, BusinessStat.website);
                launchUrl(Uri.parse(business.website!));
              },
            ),
          ],
          // WhatsApp, which the website showed and the phone did not.
          if ((business.whatsapp?.trim().isNotEmpty ?? false) && !business.isPark) ...[
            const SizedBox(width: 12),
            _OutlineCircleButton(
              icon: IconsaxPlusLinear.messages_2,
              color: AppColors.turquoise,
              onTap: () {
                BusinessStats.record(business.id, BusinessStat.whatsapp);
                var digits = business.whatsapp!.replaceAll(RegExp(r'\D'), '');
                if (digits.startsWith('0')) digits = '972${digits.substring(1)}';
                launchUrl(
                  Uri.parse('https://wa.me/$digits'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
          if (business.instagram != null && !business.isPark) ...[
            const SizedBox(width: 12),
            _OutlineCircleButton(
              icon: IconsaxPlusLinear.instagram,
              color: AppColors.turquoise,
              onTap: () {
                BusinessStats.record(business.id, BusinessStat.instagram);
                launchUrl(Uri.parse(business.instagram!));
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab bar (Overview, Menu, Photos, Reviews)
  // ─────────────────────────────────────────────
  /// The tabs this business actually has.
  ///
  /// Menu is left out when there is no menu: the tab used to be there for
  /// every business and showed the same invented one — hummus, lamb chops,
  /// Israeli beer — on a hairdresser as readily as on a restaurant.
  List<({String label, int index})> _tabsFor(Business business, L l) {
    final hasMenu =
        !business.isPark &&
        (ref.watch(businessMenuProvider(business.id)).valueOrNull ?? const [])
            .isNotEmpty;
    return [
      (label: l.tabOverview, index: 0),
      if (hasMenu) (label: l.tabMenu, index: 1),
      (label: l.tabPhotos, index: 2),
      (label: l.tabReviews, index: 3),
    ];
  }

  Widget _buildTabBar(Business business) {
    final l = L.of(context);
    final tabs = _tabsFor(business, l);

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab.index == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab.index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.midBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.midBlue
                          : const Color(0xFF454545),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab content switcher
  // ─────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return Column(
          // Stretched, so a section narrower than the screen (a heading over
          // an empty state) still starts at the page's edge, not centred.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOverviewSection(),
            // The gallery strip, then "Did you visit?" — which asks for a
            // review, and a review needs an account: the app's, since 28
            // September, so the card is not drawn in a browser.
            _buildGallerySection(),
            _buildReviewsSection(),
            // Wrong details, a business that has closed: to the panel's
            // Reports queue. App only, as reports need an account.
            if (!kIsWeb)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => showReportSheet(
                      context,
                      entityType: 'business',
                      entityId: business.id,
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFF6D6D6D)),
                    label: Text(
                      _isHe ? 'דיווח על בעיה' : 'Report a problem',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      case 1:
        return _buildMenuTab(business);
      case 2:
        return _buildPhotosTab();
      case 3:
        return _buildReviewsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────
  // Menu tab
  // ─────────────────────────────────────────────
  Widget _buildMenuTab(Business business) {
    final items =
        ref.watch(businessMenuProvider(business.id)).valueOrNull ??
        const <menu.MenuItem>[];

    // Grouped by the heading the admin gave each line. An item with none
    // groups under the empty key and prints without a heading.
    final sections = <String, List<menu.MenuItem>>{};
    for (final item in items.where((i) => i.isAvailable)) {
      sections.putIfAbsent(item.section ?? '', () => []).add(item);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in sections.entries) ...[
            const SizedBox(height: 8),
            if (entry.key.isNotEmpty) ...[
              Text(
                entry.key,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final item in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF3D3D3D),
                            ),
                          ),
                          if ((item.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description!,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // A dish with no fixed price shows none, rather than ₪0.
                    if (item.priceLabel != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        item.priceLabel!,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const Divider(color: Color(0xFFE7E7E7), height: 24),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Photos tab
  // ─────────────────────────────────────────────
  Widget _buildPhotosTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A photo-upload tile sat here. It opened the picker and
          // toasted "Photo X selected for upload" — nothing was ever
          // uploaded. Resident-contributed photos need storage and table
          // policies of their own and somewhere to moderate them, and
          // `entity_media` has no status column, so the control is gone
          // rather than continuing to claim an upload that never happens.

          // A gallery and a user-photo grid used to sit here, both drawn as
          // coloured squares — ten of them, the same ten for every business.
          // The real photographs are in `media` now; see
          // businessGalleryProvider.
          _GalleryGrid(businessId: business.id),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reviews tab (full reviews with reply)
  // ─────────────────────────────────────────────
  Widget _buildReviewsTab() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // ── Write a Review prompt (Google-style) ── the app's; see above.
        // Gone once they have reviewed: their review is in the list below,
        // and a second one is refused anyway ("already reviewed").
        if (!kIsWeb &&
            ref.watch(hasReviewedProvider(business.id)).valueOrNull != true)
          _buildWriteReviewPrompt(),

        const SizedBox(height: 16),

        // ── Review form (expanded when tapped) ──
        if (_showReviewForm) _buildReviewForm(),

        const SizedBox(height: 8),

        _buildRatingSummary(),

        const SizedBox(height: 24),

        // Reviews used to be inserted into a list held in memory and
        // rendered above this one, with a "Review submitted! Thank you 🎉"
        // toast. Nothing was written and it vanished on the next rebuild.
        // A review goes to the database now and appears here once approved.
        _buildReviewList(withReply: true),
      ],
    );
  }

  Future<void> _submitReview(Business business) async {
    final l = L.of(context);
    if (_userRating == 0) {
      _reviewToast(l.chooseRating, error: true);
      return;
    }
    if (ref.read(authProvider) == null) {
      _reviewToast(l.signInToReview, error: true, signIn: true);
      return;
    }

    setState(() => _savingReview = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .addReview(
            businessId: business.id,
            rating: _userRating,
            body: _reviewTextController.text,
          );

      ref.invalidate(hasReviewedProvider(business.id));
      ref.invalidate(businessReviewsProvider(business.id));
      if (!mounted) return;
      setState(() {
        _savingReview = false;
        _showReviewForm = false;
        _userRating = 0;
      });
      _reviewTextController.clear();
      // It arrives as `pending`, so saying "thank you" alone would leave
      // someone wondering why their review is not on the page.
      _reviewToast(l.reviewSubmitted);
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _savingReview = false);
      _reviewToast(
        e.message == 'already-reviewed' ? l.alreadyReviewed : l.signInToReview,
        error: true,
      );
    } catch (e) {
      final blocked = await refusedAsBlocked(e);
      if (!mounted) return;
      setState(() => _savingReview = false);
      _reviewToast(
        blocked ? accountBlockedMessage(context) : l.errCouldNotSave,
        error: true,
      );
    }
  }

  /// Opens the reply box for one review. Signed out, it says sign-in is
  /// needed, as the review form does.
  Future<void> _replyTo(String reviewId) async {
    final l = L.of(context);
    if (ref.read(authProvider) == null) {
      _reviewToast(l.signInToReply, error: true, signIn: true);
      return;
    }
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ReplySheet(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      final live = await addReviewReply(reviewId: reviewId, body: text);
      ref.invalidate(reviewRepliesProvider(business.id));
      if (mounted) _reviewToast(live ? l.replySent : l.replySentForApproval);
    } catch (e) {
      final blocked = await refusedAsBlocked(e);
      if (!mounted) return;
      _reviewToast(
        blocked ? accountBlockedMessage(context) : l.couldNotSendReply,
        error: true,
      );
    }
  }

  Future<void> _deleteReply(String replyId) async {
    try {
      await deleteReviewReply(replyId);
      ref.invalidate(reviewRepliesProvider(business.id));
    } catch (_) {
      if (mounted) {
        _reviewToast(L.of(context).couldNotSendReply, error: true);
      }
    }
  }

  void _reviewToast(String message, {bool error = false, bool signIn = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        action: signIn ? signInAction(context) : null,
        backgroundColor: error ? AppColors.error : AppColors.midBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Google-style "Rate & Review" prompt ──
  Widget _buildWriteReviewPrompt() {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Column(
          children: [
            Text(
              l.howWasExperience,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.rateAndShare,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D6D6D),
              ),
            ),
            const SizedBox(height: 16),

            // Star selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _userRating = starIndex;
                      _showReviewForm = true;
                    });
                  },
                  // The gap and the star's motion lines follow the reading
                  // direction: set on the right, the last two stars touched
                  // in Hebrew, their lines running into each other.
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(end: i < 4 ? 12 : 0),
                    child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      _userRating >= starIndex
                          ? IconsaxPlusBold.star_1
                          : IconsaxPlusLinear.star,
                      size: 36,
                      color: _userRating >= starIndex
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFBDBDBD),
                    ),
                    ),
                  ),
                );
              }),
            ),

            if (_userRating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _userRating == 1
                    ? l.ratePoor
                    : _userRating == 2
                    ? l.rateFair
                    : _userRating == 3
                    ? l.rateGood
                    : _userRating == 4
                    ? l.rateVeryGood
                    : l.rateExcellent,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Expanded review form ──
  Widget _buildReviewForm() {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.writeYourReview,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewTextController,
              maxLines: 4,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13),
              decoration: InputDecoration(
                hintText: l.reviewHint,
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: const Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.midBlue),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showReviewForm = false;
                          _userRating = 0;
                          _reviewTextController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE7E7E7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        l.cancel,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit button
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _savingReview
                          ? null
                          : () => _submitReview(business),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.midBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        l.submit,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Overview section (About + Working Hours)
  // ─────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return Container(
      // The frame's content sits 16 from the edge. A margin and a padding of
      // 16 each put it at 32.
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          Text(
            L.of(context).about(business.name),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          // The full About text where there is one; the one-liner otherwise.
          _ExpandableText(text: business.about ?? business.description ?? ''),

          // Opening hours, only when this business has them. The section
          // used to state Mon-Sat 12:00-9:30 and closed Sunday for every
          // business in the directory, whatever its real hours were —
          // something a resident would act on and turn up to a shut shop.
          if (business.hours.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              _isHe ? L.of(context).openingHours : 'Working Hours',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 20),
            ..._buildHoursRows(),
          ],
        ],
      ),
    );
  }

  /// Monday first, as the design lays it out. The model normalises the
  /// table's 0 = Sunday to Dart's 1 = Monday .. 7 = Sunday.
  static const _dayNames = {
    DateTime.monday: 'יום שני',
    DateTime.tuesday: 'יום שלישי',
    DateTime.wednesday: 'יום רביעי',
    DateTime.thursday: 'יום חמישי',
    DateTime.friday: 'יום שישי',
    DateTime.saturday: 'שבת',
    DateTime.sunday: 'יום ראשון',
  };

  List<Widget> _buildHoursRows() {
    final l = L.of(context);
    final byDay = {for (final h in business.hours) h.dayOfWeek: h};
    final dayNames = _isHe
        ? _dayNames
        : {
            DateTime.monday: l.weekdayMon,
            DateTime.tuesday: l.weekdayTue,
            DateTime.wednesday: l.weekdayWed,
            DateTime.thursday: l.weekdayThu,
            DateTime.friday: l.weekdayFri,
            DateTime.saturday: l.weekdaySat,
            DateTime.sunday: l.weekdaySun,
          };

    final hours = [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        (
          dayNames[day]!,
          byDay[day] == null || byDay[day]!.isClosed
              ? l.closed
              : '${byDay[day]!.openTime} - ${byDay[day]!.closeTime}',
          byDay[day] == null || byDay[day]!.isClosed,
        ),
    ];

    return hours.asMap().entries.map((entry) {
      final (day, time, isClosed) = entry.value;
      return Padding(
        padding: EdgeInsets.only(bottom: entry.key < 6 ? 20 : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isClosed
                    ? const Color(0xFFF21C1C)
                    : const Color(0xFF3D3D3D),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // Gallery section
  // ─────────────────────────────────────────────
  Widget _buildGallerySection() {
    final photos =
        ref.watch(businessGalleryProvider(business.id)).valueOrNull ??
        const <String>[];
    if (photos.isEmpty && kIsWeb) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Business Gallery": the frame's strip of 100px squares, 10 apart.
          if (photos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                L.of(context).businessGallery,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.92),
                    builder: (_) => _PhotoViewer(urls: photos, start: i),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: NetworkPhoto(
                      url: photos[i],
                      radius: BorderRadius.circular(8),
                      icon: IconsaxPlusLinear.gallery,
                    ),
                  ),
                ),
              ),
            ),
            if (!kIsWeb) const SizedBox(height: 24),
          ],
          // Review prompt card — the thumbs lead to the Reviews tab, where
          // the review is written (it was two icons that did nothing).
          if (!kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 3),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.of(context).haveYouVisited(business.name),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        L.of(context).shareRecommendation,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            IconsaxPlusLinear.like_1,
                            size: 20,
                            color: AppColors.midBlue,
                          ),
                          SizedBox(width: 22),
                          Icon(
                            IconsaxPlusLinear.dislike,
                            size: 20,
                            color: Color(0xFF888888),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reviews section
  // ─────────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              L.of(context).reviewsFor(business.name),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rating summary
          _buildRatingSummary(),

          const SizedBox(height: 24),

          _buildReviewList(withReply: false),
        ],
      ),
    );
  }

  static const _monthNames = [
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

  /// The reviews this business actually has.
  ///
  /// Both places that listed reviews carried the same four invented ones, so
  /// they share this now. An empty table shows an empty state: a business with
  /// no reviews should look like one, not like a place four people praised.
  Widget _buildReviewList({required bool withReply}) {
    final reviews = ref.watch(businessReviewsProvider(business.id));

    return reviews.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ErrorRetry(
          onRetry: () => ref.invalidate(businessReviewsProvider(business.id)),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const _NoReviewsYet();
        final repliesValue = ref.watch(reviewRepliesProvider(business.id));
        final replies =
            repliesValue.valueOrNull ?? const <String, List<ReviewReply>>{};
        // Scroll once both the reviews and their replies are on screen, and
        // not while they are being read again (a notification reloads them).
        if (widget.focusReviewId != null &&
            repliesValue.hasValue &&
            !repliesValue.isLoading &&
            !reviews.isLoading) {
          _scrollToFocus();
        }
        final me = ref.watch(authProvider)?.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++)
                _ReviewCard(
                  initials: list[i].initials,
                  name: list[i].authorName.isEmpty
                      ? L.of(context).resident
                      : list[i].authorName,
                  date: _formatReviewDate(list[i].createdAt),
                  rating: list[i].rating,
                  text: list[i].body,
                  pending: !list[i].isApproved,
                  removed: list[i].isRemoved,
                  // The review itself is the target unless a reply is.
                  key: list[i].id == widget.focusReviewId && widget.focusReplyId == null
                      ? _focusKey
                      : null,
                  marked: _focusMarked &&
                      list[i].id == widget.focusReviewId &&
                      widget.focusReplyId == null,
                  focusReplyId: widget.focusReviewId == list[i].id
                      ? widget.focusReplyId
                      : null,
                  focusReplyKey: _focusKey,
                  replyMarked: _focusMarked,
                  replies: replies[list[i].id] ?? const [],
                  myId: me,
                  formatDate: _formatReviewDate,
                  // Replying needs an account, and accounts are the app's:
                  // the website shows the replies but offers no button. Nor
                  // on one's own review still waiting: nobody else sees it.
                  onReply: kIsWeb || !list[i].isApproved
                      ? null
                      : () => _replyTo(list[i].id),
                  onDeleteReply: _deleteReply,
                  // Someone else's review, in the app (accounts are the
                  // app's): to the panel's Reports queue.
                  onReport: kIsWeb || list[i].authorId == me
                      ? null
                      : () => showReportSheet(
                          context,
                          entityType: 'review',
                          entityId: list[i].id,
                        ),
                  isLast: i == list.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }

  /// "12 בספטמבר 2026" in Hebrew, "September 12, 2026" in English.
  String _formatReviewDate(DateTime? date) {
    if (date == null) return '';
    if (_isHe) return '${date.day} ב${_monthNames[date.month - 1]} ${date.year}';
    return '${L.of(context).monthLong(date.month)} ${date.day}, ${date.year}';
  }

  Widget _buildRatingSummary() {
    final summary = ref.watch(businessReviewSummaryProvider(business.id));

    // No reviews means no score. This drew "0.0", five hollow stars and a
    // distribution of five 0% bars, which reads as a business rated badly by
    // people rather than one nobody has rated.
    if (summary.total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          L.of(context).notRatedYet,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: overall score
          Container(
            width: 153,
            // Directional, so the rule stays between the score and the bars
            // in Hebrew too (it sat on the outer edge there).
            padding: const EdgeInsetsDirectional.only(
              end: 16,
              top: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              border: BorderDirectional(
                end: BorderSide(color: Color(0xFFE7E7E7)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.average.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 5.83 : 0),
                      child: Icon(
                        IconsaxPlusBold.star_1,
                        size: 20,
                        color: i < summary.average.round()
                            ? const Color(0xFFFFC107)
                            : const Color(0xFFD1D1D1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  L.of(context).basedOnReviews(summary.total),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right panel: rating bars
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  for (var score = 5; score >= 1; score--) ...[
                    _RatingBar(
                      label: '$score',
                      percent: (summary.shareOf(score) * 100).round(),
                    ),
                    if (score > 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// White circle button (hero overlay)
// ═══════════════════════════════════════════════
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 20, color: const Color(0xFF3D3D3D)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Outlined circle button (action row)
// ═══════════════════════════════════════════════
class _OutlineCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Null when the business has nothing to open — the button then dims
  /// instead of leading nowhere.
  final VoidCallback? onTap;

  const _OutlineCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Center(child: Icon(icon, size: 20, color: color)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Rating bar row (5-star breakdown)
// ═══════════════════════════════════════════════
class _RatingBar extends StatelessWidget {
  final String label;
  final int percent;

  const _RatingBar({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          // Number
          SizedBox(
            width: 12,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Star icon
          const Icon(
            IconsaxPlusBold.star_1,
            size: 12,
            color: Color(0xFFFFC107),
          ),
          const SizedBox(width: 11),
          // Progress bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFE7E7E7),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.turquoise,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          // Percentage
          SizedBox(
            width: 38,
            child: Text(
              '$percent%',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6D6D6D),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Review card
// ═══════════════════════════════════════════════
// ═══════════════════════════════════════════════
// Review card with reply functionality
// ═══════════════════════════════════════════════
class _ReviewCard extends StatefulWidget {
  final String initials;
  final String name;
  final String date;
  final int rating;
  final String text;

  /// The writer's own review, not yet approved — or [removed] by the team.
  final bool pending;
  final bool removed;

  /// Highlighted because a notification pointed here; and the reply under
  /// it that one pointed at, keyed with [focusReplyKey].
  final bool marked;
  final String? focusReplyId;
  final GlobalKey? focusReplyKey;
  final bool replyMarked;

  /// Residents' replies to this review (approved, and the signed-in
  /// person's own while it waits). Modiin4u and the businesses do not reply
  /// at this stage, so the panel's `admin_response` is no longer shown.
  final List<ReviewReply> replies;
  final String? myId;
  final String Function(DateTime?) formatDate;
  final VoidCallback? onReply;
  final VoidCallback? onReport;
  final void Function(String replyId) onDeleteReply;
  final bool isLast;

  const _ReviewCard({
    required this.initials,
    required this.name,
    required this.date,
    required this.rating,
    required this.text,
    super.key,
    this.pending = false,
    this.removed = false,
    this.marked = false,
    this.focusReplyId,
    this.focusReplyKey,
    this.replyMarked = false,
    this.replies = const [],
    this.myId,
    required this.formatDate,
    this.onReply,
    this.onReport,
    required this.onDeleteReply,
    this.isLast = false,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  @override
  Widget build(BuildContext context) {
    // Animated, so the mark a notification put here fades rather than blinks.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: widget.marked ? _markColor : _markColor.withValues(alpha: 0),
        border: widget.isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.turquoise,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.initials,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + date; wraps, as a reply's does, when "Pending
                // approval" joins them on a narrow phone.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.date,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    // As on a reply of one's own that waits.
                    if (widget.pending) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.removed
                            ? _removedLabel(context)
                            : L.of(context).pendingApproval,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD68200),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 7),

                // Stars
                Row(
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 4.08 : 0),
                      child: Icon(
                        IconsaxPlusBold.star_1,
                        size: 14,
                        color: i < widget.rating
                            ? const Color(0xFFFFC107)
                            : const Color(0xFFD1D1D1),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 7),

                // Review text
                Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                    height: 1.4,
                  ),
                ),
                for (final reply in widget.replies)
                  _ReplyTile(
                    key: reply.id == widget.focusReplyId ? widget.focusReplyKey : null,
                    marked: widget.replyMarked && reply.id == widget.focusReplyId,
                    reply: reply,
                    date: widget.formatDate(reply.createdAt),
                    isMine: reply.authorId == widget.myId,
                    onDelete: () => widget.onDeleteReply(reply.id),
                  ),
                if (widget.onReply != null || widget.onReport != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        if (widget.onReply != null)
                          GestureDetector(
                            onTap: widget.onReply,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                L.of(context).replyToReview,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.midBlue,
                                ),
                              ),
                            ),
                          ),
                        if (widget.onReply != null && widget.onReport != null)
                          const SizedBox(width: 20),
                        if (widget.onReport != null)
                          GestureDetector(
                            onTap: widget.onReport,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                Localizations.localeOf(context).languageCode == 'he'
                                    ? 'דיווח'
                                    : 'Report',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6D6D6D),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the business page: the 260px cover, the overlapping
/// avatar, then the name, rating, address and action row in their places.
class _BusinessDetailSkeleton extends StatelessWidget {
  const _BusinessDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const SkeletonBox(height: 260, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 12),
                  SkeletonLine(width: 220, fontSize: 28),
                  SizedBox(height: 12),
                  SkeletonLine(width: 280, fontSize: 14),
                  SizedBox(height: 18),
                  SkeletonLine(width: 150, fontSize: 14),
                  SizedBox(height: 16),
                  SkeletonLine(width: 260, fontSize: 14),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 40, radius: 20)),
                      SizedBox(width: 12),
                      SkeletonCircle(size: 40),
                      SizedBox(width: 8),
                      SkeletonCircle(size: 40),
                      SizedBox(width: 8),
                      SkeletonCircle(size: 40),
                    ],
                  ),
                  SizedBox(height: 24),
                  SkeletonBox(height: 2, radius: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The description with a working "See More".
///
/// The control was there and the text was never shortened, so it sat under a
/// full paragraph doing nothing. This clamps to four lines and only offers
/// the control when there is something hidden behind it — a two-line
/// description keeps no "See More" it cannot honour.
class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final style = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF3D3D3D),
      height: 1.6,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            if (overflows)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _expanded ? l.seeLess : l.seeMore,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Shown where the photographs would be, until `media` has rows.
/// A business's logo, in a white circle.
///
/// This circle drew a gold gradient with a restaurant bell in it — the same
/// for every business, whether it was a pizzeria or a lawyer — though 137 of
/// the 200 carry a logo. The logo is fitted, not cropped: logos have their own
/// margins and transparent corners, and cropping cuts the name off the edge.
class _BusinessLogo extends StatelessWidget {
  final String? url;
  final double size;
  const _BusinessLogo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final has = url != null && url!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        gradient: has
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: has
          ? ClipOval(
              child: Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: NetworkPhoto(
                  url: url,
                  fit: BoxFit.contain,
                  gradient: const [Colors.white, Colors.white],
                  icon: IconsaxPlusLinear.shop,
                  iconColor: const Color(0xFFB0B0B0),
                ),
              ),
            )
          : Center(
              child: Icon(
                IconsaxPlusLinear.shop,
                size: size * 0.36,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
    );
  }
}

/// A business's photographs, from the WordPress gallery.
class _GalleryGrid extends ConsumerWidget {
  final String businessId;
  const _GalleryGrid({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(businessGalleryProvider(businessId));
    return photos.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const _NoPhotosYet(),
      data: (urls) {
        if (urls.isEmpty) return const _NoPhotosYet();
        return LayoutBuilder(
          builder: (context, c) {
            // Three across on a phone, four on anything wider.
            final perRow = c.maxWidth > 700 ? 4 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urls.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: perRow,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openViewer(context, urls, i),
                child: NetworkPhoto(
                  url: urls[i],
                  radius: BorderRadius.circular(10),
                  icon: IconsaxPlusLinear.gallery,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openViewer(BuildContext context, List<String> urls, int start) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _PhotoViewer(urls: urls, start: start),
    );
  }
}

/// Full-size photographs, swiped through.
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int start;
  const _PhotoViewer({required this.urls, required this.start});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.start);
  late int _at = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_at + delta).clamp(0, widget.urls.length - 1);
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pages,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _at = i),
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(
              child: NetworkPhoto(
                url: widget.urls[i],
                fit: BoxFit.contain,
                icon: IconsaxPlusLinear.gallery,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${_at + 1} / ${widget.urls.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
        // Arrows, for a mouse — a swipe is not something a desktop offers.
        if (_at > 0)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _go(-1),
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
              ),
            ),
          ),
        if (_at < widget.urls.length - 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _go(1),
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoPhotosYet extends StatelessWidget {
  const _NoPhotosYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.gallery,
              size: 28,
              color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            L.of(context).noPhotosYet,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown where reviews would be, when a business has none.
class _NoReviewsYet extends StatelessWidget {
  const _NoReviewsYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.message_text_1,
              size: 28,
              color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            L.of(context).noReviewsYet,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L.of(context).noReviewsHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

/// No business at this address: says so, and leads back to the directory.
/// On the website it keeps the navbar and footer, like any other page.
class _BusinessNotFound extends StatelessWidget {
  const _BusinessNotFound();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: webIsHebrew,
      builder: (context, hebrewOnWeb, _) {
        // The website follows its own switch; the app follows the language
        // chosen in Settings, where this used to stay Hebrew regardless.
        final hebrew = kIsWeb
            ? hebrewOnWeb
            : Localizations.localeOf(context).languageCode == 'he';
        String t(String en, String he) => hebrew ? he : en;
        final message = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.shop, size: 48, color: AppColors.midBlue),
              const SizedBox(height: 20),
              Text(
                t('This business is not listed', 'העסק הזה לא נמצא באתר'),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue),
              ),
              const SizedBox(height: 12),
              Text(
                t('It may have closed or moved. The directory has others like it.',
                    'ייתכן שנסגר או עבר. במדריך העסקים יש עוד רבים כמותו.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF5F5E5A)),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.go('/businesses'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                ),
                child: Text(t('Back to Businesses', 'חזרה לעסקים'),
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );

        return Directionality(
          textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: LayoutBuilder(
              builder: (context, c) => kIsWeb && c.maxWidth > 1100
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          WebNavbar(isHebrew: hebrew, activeId: 'businesses'),
                          Center(child: message),
                          WebFooter(isHebrew: hebrew),
                        ],
                      ),
                    )
                  : SafeArea(child: Center(child: SingleChildScrollView(child: message))),
            ),
          ),
        );
      },
    );
  }
}

/// One reply under a review: set in with a rule at its start, the author's
/// initials, name and date, then the text. The author's own reply says when
/// it is still waiting for approval, and can be deleted.
/// The light blue behind a review or reply a notification opened. It fades
/// to the same blue made clear — from transparent black it passed through grey.
const _markColor = Color(0xFFE8F1FB);

/// What a writer sees on their own review or reply that the team took down:
/// it is not waiting, so "Pending Approval" would mislead.
String _removedLabel(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'he'
        ? 'הוסתר על ידי הצוות'
        : 'Hidden by the team';

class _ReplyTile extends StatelessWidget {
  final ReviewReply reply;
  final String date;
  final bool isMine;
  final VoidCallback onDelete;

  /// Highlighted because a notification pointed here.
  final bool marked;

  const _ReplyTile({
    super.key,
    this.marked = false,
    required this.reply,
    required this.date,
    required this.isMine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final name = reply.authorName.isEmpty ? l.resident : reply.authorName;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      margin: const EdgeInsetsDirectional.only(top: 10),
      padding: const EdgeInsetsDirectional.only(start: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: marked ? _markColor : _markColor.withValues(alpha: 0),
        border: BorderDirectional(
          start: BorderSide(
            color: marked ? AppColors.midBlue : const Color(0xFFE7E7E7),
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFE8EEF7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                reply.authorName.isEmpty ? '?' : reply.initials,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    if (!reply.isApproved)
                      Text(
                        reply.isRemoved
                            ? _removedLabel(context)
                            : l.pendingApproval,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD68200),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.body,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    color: const Color(0xFF3D3D3D),
                    height: 1.4,
                  ),
                ),
                if (isMine)
                  GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.delete,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 11,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  )
                // Replies go live without approval (00063), so anyone can
                // send one that should not be there to the Reports queue.
                // In the app only, where there are accounts.
                else if (!kIsWeb)
                  GestureDetector(
                    onTap: () => showReportSheet(
                      context,
                      entityType: 'comment',
                      entityId: reply.id,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'he'
                            ? 'דיווח'
                            : 'Report',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 11,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The reply box: one field and Send, above the keyboard. Returns the text.
class _ReplySheet extends StatefulWidget {
  const _ReplySheet();

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                minLines: 1,
                maxLines: 5,
                maxLength: 1000,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l.writeReplyHint,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                l.sendReply,
                style: TextStyle(fontFamily: AppFonts.inter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
