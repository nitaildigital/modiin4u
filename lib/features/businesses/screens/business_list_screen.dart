import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../models/business.dart';
import '../providers/business_providers.dart';
import '../widgets/business_card.dart';
import '../widgets/m_business_place_card.dart';
import '../../../core/theme/app_colors.dart';
import 'web_business_list_screen.dart';
import '../../../shared/providers/nav_categories_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../restaurants/providers/restaurant_providers.dart';

/// Businesses in one category, or all of them when [categoryId] is null.
class BusinessListScreen extends ConsumerWidget {
  final String? categoryId;
  final String title;

  /// The city's parks rather than a business category — the Municipal
  /// page's Parks tile. Kosher and delivery mean nothing for a park, so
  /// those filters are left out.
  final bool parks;

  const BusinessListScreen({
    super.key,
    this.categoryId,
    required this.title,
    this.parks = false,
  });

  /// The category's own name, or whatever the caller passed if the row
  /// cannot be read. The name lives on the row; the link only carries an id.
  String _title(WidgetRef ref) {
    final id = categoryId;
    if (id == null) return title;
    return ref.watch(categoryNameProvider(id)).valueOrNull ?? title;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebBusinessListContent(
            categoryId: categoryId,
            title: _title(ref),
            parks: parks,
          );
        }
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) =>
      _MobileBusinessList(
        categoryId: categoryId,
        title: _title(ref),
        parks: parks,
      );
}

/// The phone's category page — the mobile "Bars" frame: back and title, a
/// search field with the filter control, the count, then one card a row.
///
/// The filter control opens the filters the website's restaurants listing
/// has — cuisine, kosher or not, a minimum rating, delivery, and the order —
/// with cuisine offered on the restaurants list, where it can narrow
/// something. It had only Kosher and Delivery, and the client asked for the
/// website's set. Figma draws the control but no sheet, so the sheet is built
/// from the page's own pills. The search narrows the loaded list by name and
/// address as you type.
class _MobileBusinessList extends ConsumerStatefulWidget {
  final String? categoryId;
  final String title;
  final bool parks;

  const _MobileBusinessList({
    required this.categoryId,
    required this.title,
    this.parks = false,
  });

  @override
  ConsumerState<_MobileBusinessList> createState() =>
      _MobileBusinessListState();
}

class _MobileBusinessListState extends ConsumerState<_MobileBusinessList> {
  final _search = TextEditingController();
  String _query = '';

  /// `all`, `kosher` or `not`, as on the website.
  String _kosher = 'all';
  bool _delivery = false;

  /// 0 for any rating, otherwise the fewest stars a place may have.
  int _minRating = 0;

  /// Cuisine slugs; empty means every cuisine.
  final Set<String> _cuisines = {};
  _Sort _sort = _Sort.newest;

  bool get _isHe => Localizations.localeOf(context).languageCode == 'he';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtering =>
      _kosher != 'all' || _delivery || _minRating > 0 || _cuisines.isNotEmpty;

  void _clearFilters() {
    _kosher = 'all';
    _delivery = false;
    _minRating = 0;
    _cuisines.clear();
    _sort = _Sort.newest;
  }

  /// [slugs] holds each place's food categories, for the cuisine filter.
  List<Business> _visible(List<Business> rows, Map<String, Set<String>> slugs) {
    final q = _query.trim().toLowerCase();
    final kept = rows.where((b) {
      if (_kosher == 'kosher' && b.kosherStatus == null) return false;
      if (_kosher == 'not' && b.kosherStatus != null) return false;
      if (_delivery && !b.hasDelivery) return false;
      if (_minRating > 0 && b.rating < _minRating) return false;
      if (_cuisines.isNotEmpty &&
          !_cuisines.any((c) => slugs[b.id]?.contains(c) ?? false)) {
        return false;
      }
      if (q.isEmpty) return true;
      return b.name.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q);
    }).toList();

    // The rows arrive newest first; the website sorts the same three ways,
    // rating ties going to the place with more reviews.
    return switch (_sort) {
      _Sort.newest => kept,
      _Sort.rating =>
        kept..sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0
              ? byRating
              : b.reviewCount.compareTo(a.reviewCount);
        }),
      _Sort.name => kept..sort((a, b) => a.name.compareTo(b.name)),
    };
  }

  Future<void> _openFilters(List<BusinessCategory> cuisines) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        minWidth: double.infinity,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final l = L.of(context);
          void apply(VoidCallback change) {
            change();
            setSheet(() {});
            setState(() {});
          }

          Widget chip(String label, bool on, VoidCallback change) {
            return GestureDetector(
              onTap: () => apply(change),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: on ? AppColors.midBlue : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: on ? AppColors.midBlue : const Color(0xFFE7E7E7),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: on ? Colors.white : const Color(0xFF3D3D3D),
                  ),
                ),
              ),
            );
          }

          Widget section(String title, List<Widget> chips) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
            ),
          );

          return SafeArea(
            child: SingleChildScrollView(
              // Full width: without it the sheet shrank to its chips.
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.filter,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (_filtering || _sort != _Sort.newest)
                        TextButton(
                          onPressed: () => apply(_clearFilters),
                          child: Text(
                            l.clearFilter,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (cuisines.isNotEmpty)
                    section(l.filterCuisine, [
                      chip(l.allCuisines, _cuisines.isEmpty, _cuisines.clear),
                      for (final c in cuisines)
                        chip(
                          c.name,
                          _cuisines.contains(c.slug),
                          () => _cuisines.contains(c.slug)
                              ? _cuisines.remove(c.slug)
                              : _cuisines.add(c.slug),
                        ),
                    ]),
                  if (!widget.parks)
                  section(l.filterKosher, [
                    chip(l.all, _kosher == 'all', () => _kosher = 'all'),
                    chip(
                      l.kosher,
                      _kosher == 'kosher',
                      () => _kosher = 'kosher',
                    ),
                    chip(l.notKosher, _kosher == 'not', () => _kosher = 'not'),
                  ]),
                  section(l.filterRating, [
                    chip(l.all, _minRating == 0, () => _minRating = 0),
                    for (final stars in const [4, 3, 2, 1])
                      chip(
                        '$stars★ ${l.ratingAndUp}',
                        _minRating == stars,
                        () => _minRating = stars,
                      ),
                  ]),
                  if (!widget.parks)
                  section(l.diningOptions, [
                    chip(l.delivery, _delivery, () => _delivery = !_delivery),
                  ]),
                  section(l.sortBy, [
                    chip(
                      l.sortNewest,
                      _sort == _Sort.newest,
                      () => _sort = _Sort.newest,
                    ),
                    chip(
                      l.sortRating,
                      _sort == _Sort.rating,
                      () => _sort = _Sort.rating,
                    ),
                    chip(
                      l.sortName,
                      _sort == _Sort.name,
                      () => _sort = _Sort.name,
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A food category — restaurants, one of its cuisines, or cafés — reads
    // the food places, which carry each place's categories with their
    // parents. Read straight, "restaurants" left out a pizzeria filed only
    // under פיצה, which the website's list includes.
    final categories = ref.watch(categoriesBySlugProvider);
    final category = categories.valueOrNull?.values
        .where((c) => c.id == widget.categoryId)
        .firstOrNull;
    final parent = categories.valueOrNull?['restaurants'];
    final foodSlug =
        category != null &&
            (category.slug == 'restaurants' ||
                category.slug == 'cafe-bakery' ||
                (parent != null && category.parentId == parent.id))
        ? category.slug
        : null;

    final ProviderBase<Object?> provider;
    final AsyncValue<List<Business>> businesses;
    var slugs = const <String, Set<String>>{};
    if (widget.parks) {
      provider = parksProvider;
      businesses = ref.watch(parksProvider);
    } else if (widget.categoryId != null && categories.isLoading) {
      provider = categoriesBySlugProvider;
      businesses = const AsyncLoading();
    } else if (foodSlug != null) {
      provider = foodMapPlacesProvider;
      final places = ref.watch(foodMapPlacesProvider);
      businesses = places.whenData(
        (all) => [
          for (final p in all)
            if (p.slugs.contains(foodSlug)) p.business,
        ],
      );
      slugs = {
        for (final p in places.valueOrNull ?? const <FoodPlace>[])
          p.business.id: p.slugs,
      };
    } else {
      provider = businessesByCategoryProvider(widget.categoryId);
      businesses = ref.watch(businessesByCategoryProvider(widget.categoryId));
    }

    // Cuisine only narrows the restaurants list, and only to cuisines that
    // have a place in it.
    final cuisines = foodSlug == 'restaurants'
        ? [
            for (final c
                in ref.watch(cuisineCategoriesProvider).valueOrNull ??
                    const <BusinessCategory>[])
              if (slugs.values.any((s) => s.contains(c.slug))) c,
          ]
        : const <BusinessCategory>[];
    final filtering = _filtering;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                // ── Back + title ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PositionedDirectional(
                        start: 4,
                        child: IconButton(
                          icon: Icon(
                            _isHe
                                ? IconsaxPlusLinear.arrow_right_3
                                : IconsaxPlusLinear.arrow_left,
                            color: Colors.black,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56),
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // ── Search + filter control ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.search_normal_1,
                          size: 18,
                          color: Color(0xFF6D6D6D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (v) => setState(() => _query = v),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isCollapsed: true,
                              hintText: L
                                  .of(context)
                                  .searchInPlace(widget.title),
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: L.of(context).filter,
                          onPressed: () => _openFilters(cuisines),
                          icon: Badge(
                            isLabelVisible: filtering,
                            smallSize: 8,
                            backgroundColor: AppColors.turquoise,
                            child: const Icon(
                              IconsaxPlusLinear.setting_4,
                              size: 20,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: businesses.when(
                    loading: () => ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) => const BusinessCardSkeleton(),
                    ),
                    error: (error, _) =>
                        ErrorRetry(onRetry: () => ref.invalidate(provider)),
                    data: (all) {
                      if (all.isEmpty) {
                        return EmptyState(
                          icon: IconsaxPlusLinear.shop,
                          title: widget.parks
                              ? L.of(context).noParksYet
                              : L.of(context).noBusinessesToShow,
                          subtitle: widget.parks
                              ? L.of(context).parksAppearHere
                              : L.of(context).businessesAppearHere,
                        );
                      }
                      final list = _visible(all, slugs);
                      return RefreshIndicator(
                        onRefresh: () async => ref.invalidate(provider),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          children: [
                            _CountRow(
                              count: list.length,
                              title: widget.title,
                              // "1 park" / "3 parks", with a tree for parks.
                              label: widget.parks
                                  ? L.of(context).parksCount(list.length)
                                  : null,
                              icon: widget.parks
                                  ? IconsaxPlusLinear.tree
                                  : IconsaxPlusLinear.shop,
                            ),
                            const SizedBox(height: 16),
                            if (list.isEmpty)
                              EmptyState(
                                icon: IconsaxPlusLinear.filter_remove,
                                title: L.of(context).nothingMatchesFilter,
                                actionLabel: L.of(context).clearFilter,
                                onAction: () => setState(() {
                                  _clearFilters();
                                  _query = '';
                                  _search.clear();
                                }),
                              ),
                            for (final b in list) ...[
                              MBusinessPlaceCard(business: b),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "24 Bars in Modiin" — the count in the page's colour, beside a small
/// tinted square with the shop mark.
class _CountRow extends StatelessWidget {
  final int count;
  final String title;

  /// Replaces "count title" when the words need their own grammar.
  final String? label;
  final IconData icon;

  const _CountRow({
    required this.count,
    required this.title,
    this.label,
    this.icon = IconsaxPlusLinear.shop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: AppColors.midBlue),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label ?? '$count $title',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midBlue,
                  ),
                ),
                TextSpan(
                  text: L.of(context).inModiinSuffix,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// One business, rendered with the shared card.
class BusinessListTile extends StatelessWidget {
  final Business business;

  const BusinessListTile({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return BusinessCard(
      name: business.name,
      category: business.category.isNotEmpty
          ? business.category
          : (business.description ?? ''),
      rating: business.rating,
      reviewCount: business.reviewCount,
      // No hours on record yet, so the open/closed tag stays hidden.
      isOpen: business.hours.isEmpty ? null : business.isOpenNow,
      kosher: business.kosherLabel,
      neighborhood: business.neighborhood,
      imageUrl: business.imageUrl,
      onTap: () => context.push('/business/${business.id}'),
    );
  }
}

/// The orders the website's restaurants listing offers.
enum _Sort { newest, rating, name }
