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

/// Businesses in one category, or all of them when [categoryId] is null.
class BusinessListScreen extends ConsumerWidget {
  final String? categoryId;
  final String title;

  const BusinessListScreen({super.key, this.categoryId, required this.title});

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
          );
        }
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) =>
      _MobileBusinessList(categoryId: categoryId, title: _title(ref));
}

/// The phone's category page — the mobile "Bars" frame: back and title, a
/// search field with the filter control, the count, then one card a row.
///
/// The filter control opens the same two filters the website's category
/// page has (Kosher, Delivery) — the two a column can answer. This page had
/// no filter at all on a phone. The search narrows the loaded list by name
/// and address as you type.
class _MobileBusinessList extends ConsumerStatefulWidget {
  final String? categoryId;
  final String title;

  const _MobileBusinessList({required this.categoryId, required this.title});

  @override
  ConsumerState<_MobileBusinessList> createState() =>
      _MobileBusinessListState();
}

class _MobileBusinessListState extends ConsumerState<_MobileBusinessList> {
  final _search = TextEditingController();
  String _query = '';
  bool _kosher = false;
  bool _delivery = false;

  bool get _isHe => Localizations.localeOf(context).languageCode == 'he';
  String _t(String en, String he) => _isHe ? he : en;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Business> _visible(List<Business> rows) {
    final q = _query.trim().toLowerCase();
    return rows.where((b) {
      if (_kosher && b.kosherStatus == null) return false;
      if (_delivery && !b.hasDelivery) return false;
      if (q.isEmpty) return true;
      return b.name.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Widget chip(String label, bool on, VoidCallback toggle) {
            return GestureDetector(
              onTap: () {
                toggle();
                setSheet(() {});
                setState(() {});
              },
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

          return SafeArea(
            child: Container(
              // Full width: without it the sheet shrank to its two chips.
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Filter', 'סינון'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      chip(
                        _t('Kosher', 'כשר'),
                        _kosher,
                        () => _kosher = !_kosher,
                      ),
                      chip(
                        _t('Delivery', 'משלוחים'),
                        _delivery,
                        () => _delivery = !_delivery,
                      ),
                    ],
                  ),
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
    final provider = businessesByCategoryProvider(widget.categoryId);
    final businesses = ref.watch(provider);
    final filtering = _kosher || _delivery;

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
                              hintText: _t(
                                'Search ${widget.title}...',
                                'חיפוש ב${widget.title}...',
                              ),
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _t('Filter', 'סינון'),
                          onPressed: _openFilters,
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
                        return const EmptyState(
                          icon: IconsaxPlusLinear.shop,
                          title: 'אין עסקים להצגה',
                          subtitle: 'עסקים יופיעו כאן ברגע שיתווספו',
                        );
                      }
                      final list = _visible(all);
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(provider);
                          await ref.read(provider.future);
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          children: [
                            _CountRow(count: list.length, title: widget.title),
                            const SizedBox(height: 16),
                            if (list.isEmpty)
                              EmptyState(
                                icon: IconsaxPlusLinear.filter_remove,
                                title: _t(
                                  'Nothing here matches that filter',
                                  'אין תוצאות לסינון הזה',
                                ),
                                actionLabel: _t('Clear filter', 'נקו סינון'),
                                onAction: () => setState(() {
                                  _kosher = false;
                                  _delivery = false;
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

  const _CountRow({required this.count, required this.title});

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            IconsaxPlusLinear.shop,
            size: 18,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$count $title',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midBlue,
                  ),
                ),
                TextSpan(
                  text: isHe ? ' במודיעין' : ' in Modiin',
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
