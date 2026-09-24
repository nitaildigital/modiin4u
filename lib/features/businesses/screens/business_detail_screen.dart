import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/error_retry.dart';
import '../models/menu_item.dart' as menu;
import '../../../shared/widgets/skeleton.dart';
import '../models/business.dart';
import '../providers/business_providers.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';

class BusinessDetailScreen extends ConsumerWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = businessByIdProvider(businessId);

    return ref
        .watch(provider)
        .when(
          loading: () => const _BusinessDetailSkeleton(),
          error: (error, _) => Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: ErrorRetry(onRetry: () => ref.invalidate(provider)),
            ),
          ),
          data: (business) => _BusinessDetailContent(business: business),
        );
  }
}

class _BusinessDetailContent extends ConsumerStatefulWidget {
  final Business business;

  const _BusinessDetailContent({required this.business});

  @override
  ConsumerState<_BusinessDetailContent> createState() =>
      _BusinessDetailContentState();
}

class _BusinessDetailContentState
    extends ConsumerState<_BusinessDetailContent> {
  Business get business => widget.business;

  /// The page has two share controls — one on the photograph, one in the
  /// action row — and they now send the same thing.
  void _shareBusiness() {
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image area ──
            _buildHero(topPadding),

            // ── Profile circle + Kosher badge overlap area ──
            _buildProfileAndKosher(),

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
                      fontFamily: AppFonts.rubik,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    business.description ?? '',
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

            const SizedBox(height: 20),

            // ── Action buttons ──
            _buildActionButtons(),

            const SizedBox(height: 20),

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
                // Placeholder icon
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

          // Back button
          Positioned(
            left: 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: IconsaxPlusLinear.arrow_left,
              onTap: () => context.pop(),
            ),
          ),

          // Share button
          Positioned(
            right: 56 + 12,
            top: topPadding + 7,
            child: _CircleButton(
              icon: IconsaxPlusLinear.export_1,
              onTap: _shareBusiness,
            ),
          ),

          // Favorite button
          Positioned(
            right: 12,
            top: topPadding + 7,
            child: FavoriteButton(
              kind: FavoriteKind.business,
              id: business.id,
              size: 40,
              iconSize: 20,
              color: const Color(0xFF3D3D3D),
            ),
          ),

          // The "Show all photos" control used to sit here doing nothing.
          // A business carries a single cover image; a gallery needs the
          // `media` table, which is empty (A5b). Restore it with the gallery.
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Profile circle + Kosher badge
  // ─────────────────────────────────────────────
  Widget _buildProfileAndKosher() {
    return Transform.translate(
      offset: const Offset(0, -50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Profile circle (100x100, 3px white border)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B6914), Color(0xFFC49B2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  IconsaxPlusLinear.reserve,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),

            const Spacer(),

            // Kosher badge — only shown when the business is certified
            if (business.kosherLabel != null)
              Container(
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
                      business.kosherLabel!,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
          // Star + rating
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
              business.isOpenNow ? 'פתוח עכשיו' : 'סגור',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
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
  // Action buttons: Call, Website, Instagram, Navigate, Share
  // ─────────────────────────────────────────────
  Widget _buildActionButtons() {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Call Now button
          Expanded(
            child: GestureDetector(
              onTap: business.phone == null
                  ? null
                  : () => launchUrl(Uri.parse('tel:${business.phone}')),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      IconsaxPlusLinear.call,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.callNow,
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

          const SizedBox(width: 12),

          // Website button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.global,
            color: AppColors.turquoise,
            onTap: business.website == null
                ? null
                : () => launchUrl(Uri.parse(business.website!)),
          ),

          const SizedBox(width: 8),

          // Instagram button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.instagram,
            color: AppColors.turquoise,
            onTap: business.instagram == null
                ? null
                : () => launchUrl(Uri.parse(business.instagram!)),
          ),

          const SizedBox(width: 8),

          // Navigate button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.routing,
            color: AppColors.turquoise,
            onTap: () => launchUrl(
              Uri.parse(
                'https://waze.com/ul?ll=${business.latitude},'
                '${business.longitude}&navigate=yes',
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Share button
          _OutlineCircleButton(
            icon: IconsaxPlusLinear.export_1,
            color: AppColors.turquoise,
            onTap: _shareBusiness,
          ),
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
          children: [
            _buildOverviewSection(),
            _buildGallerySection(),
            _buildReviewsSection(),
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
          // Photos come from `media`, which has no rows yet (A5b).
          const _NoPhotosYet(),
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

        // ── Write a Review prompt (Google-style) ──
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
      _reviewToast(l.signInToReview, error: true);
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingReview = false);
      _reviewToast(l.errCouldNotSave, error: true);
    }
  }

  void _reviewToast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
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
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 12 : 0),
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // About section
          Text(
            'אודות ${business.name}',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          _ExpandableText(text: business.description ?? ''),

          // Opening hours, only when this business has them. The section
          // used to state Mon-Sat 12:00-9:30 and closed Sunday for every
          // business in the directory, whatever its real hours were —
          // something a resident would act on and turn up to a shut shop.
          if (business.hours.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'שעות פתיחה',
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
    final byDay = {for (final h in business.hours) h.dayOfWeek: h};

    final hours = [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        (
          _dayNames[day]!,
          byDay[day] == null || byDay[day]!.isClosed
              ? 'סגור'
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review prompt card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ביקרתם ב${business.name}?',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share your recommendation with the Modi\'in community.',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Thumbs up/down
                        Row(
                          children: [
                            const Icon(
                              IconsaxPlusLinear.like_1,
                              size: 20,
                              color: AppColors.midBlue,
                            ),
                            const SizedBox(width: 22),
                            Icon(
                              IconsaxPlusLinear.dislike,
                              size: 20,
                              color: const Color(0xFF888888),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
              'ביקורות על ${business.name}',
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++)
                _ReviewCard(
                  initials: list[i].initials,
                  name: list[i].authorName,
                  date: _formatReviewDate(list[i].createdAt),
                  rating: list[i].rating,
                  text: list[i].body,
                  isLast: i == list.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day} ב${_monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildRatingSummary() {
    final summary = ref.watch(businessReviewSummaryProvider(business.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: overall score
          Container(
            width: 153,
            padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFE7E7E7))),
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
                  'מבוסס על ${summary.total} ביקורות',
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
  final bool isLast;

  const _ReviewCard({
    required this.initials,
    required this.name,
    required this.date,
    required this.rating,
    required this.text,
    this.isLast = false,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
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
                // Name + date
                Row(
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
                // A reply control sat here: it stored the text in a
                // String on the widget and announced "Reply sent!".
                // Nothing was written. `reviews` carries
                // `admin_response` — the business's or an
                // administrator's reply — and a resident replying to
                // another resident's review has no home in the schema
                // at all, so the control is gone rather than lying.
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
            'אין עדיין תמונות',
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
            'אין עדיין ביקורות',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'היו הראשונים לכתוב ביקורת על המקום הזה',
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
