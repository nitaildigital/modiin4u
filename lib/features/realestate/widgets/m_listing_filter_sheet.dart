import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';

/// Opens the phone's listing filters over the real-estate map.
///
/// The map frame draws a filter control at the end of its search bar, but the
/// design has no screen behind it. This sheet is built from pieces the design
/// does have: the Bars page's filter sheet for the frame, and the Add
/// Apartment form's cards, For Sale / For Rent toggles, dropdowns and chips
/// for the fields. The fields are exactly what [ListingFilter] can ask the
/// database for — nothing the query cannot answer is offered.
Future<void> showListingFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    // As wide as the phone layout it sits over, rather than the whole window
    // of a narrow browser.
    constraints: const BoxConstraints(maxWidth: 430),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ListingFilterSheet(),
  );
}

const _kBorder = Color(0xFFE7E7E7);
const _kGrey500 = Color(0xFF6D6D6D);
const _kInk = Color(0xFF1F1F1F);

/// The choices are held here as a draft and written to [listingFilterProvider]
/// only on "Show results", so dismissing the sheet leaves the map as it was.
class _ListingFilterSheet extends ConsumerStatefulWidget {
  const _ListingFilterSheet();

  @override
  ConsumerState<_ListingFilterSheet> createState() =>
      _ListingFilterSheetState();
}

class _ListingFilterSheetState extends ConsumerState<_ListingFilterSheet> {
  ListingKind? _kind;
  PropertyType? _type;
  String? _neighborhoodId;
  double? _minRooms;
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();

  /// "Any", then at least one room up to at least five. Half rooms are
  /// normal here, but a floor of "2.5 or more" is not how anyone searches.
  static const _roomSteps = <double>[1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    final f = ref.read(listingFilterProvider);
    _kind = f.kind;
    _type = f.propertyType;
    _neighborhoodId = f.neighborhoodId;
    _minRooms = f.minRooms;
    _minPrice.text = f.minPrice?.toString() ?? '';
    _maxPrice.text = f.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  void _setKind(ListingKind? kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      // A sale is priced in millions and a let by the month, in a different
      // column; a bound typed for one means nothing for the other.
      _minPrice.clear();
      _maxPrice.clear();
    });
  }

  void _reset() {
    setState(() {
      _kind = null;
      _type = null;
      _neighborhoodId = null;
      _minRooms = null;
      _minPrice.clear();
      _maxPrice.clear();
    });
  }

  void _apply() {
    int? read(TextEditingController c) => int.tryParse(c.text);
    // The repository applies a price only once a kind names the column, so
    // a bound kept without one would sit in the filter doing nothing.
    var lo = _kind == null ? null : read(_minPrice);
    var hi = _kind == null ? null : read(_maxPrice);
    if (lo != null && hi != null && lo > hi) (lo, hi) = (hi, lo);

    final f = ref.read(listingFilterProvider);
    ref.read(listingFilterProvider.notifier).state = f.copyWith(
      kind: _kind,
      clearKind: _kind == null,
      propertyType: _type,
      clearPropertyType: _type == null,
      neighborhoodId: _neighborhoodId,
      clearNeighborhoodId: _neighborhoodId == null,
      minPrice: lo,
      clearMinPrice: lo == null,
      maxPrice: hi,
      clearMaxPrice: hi == null,
      minRooms: _minRooms,
      clearMinRooms: _minRooms == null,
    );
    Navigator.of(context).pop();
  }

  static String _typeLabel(L l, PropertyType t) => switch (t) {
    PropertyType.apartment => l.propTypeApartment,
    PropertyType.penthouse => l.propTypePenthouse,
    PropertyType.garden => l.propTypeGarden,
    PropertyType.duplex => l.propTypeDuplex,
    PropertyType.villa => l.propTypeVilla,
    PropertyType.studio => l.propTypeStudio,
    PropertyType.other => l.propTypeOther,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final hoods = ref.watch(listingNeighborhoodsProvider);
    final hoodRows = hoods.valueOrNull ?? const <({String id, String name})>[];

    return Padding(
      // Keeps the price fields above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title + close ──
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.listingFilters,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Listing type ──
                      //
                      // The form's two toggles, with "All" in front: the
                      // map can show both kinds at once, the form cannot
                      // post both.
                      _FilterCard(
                        label: l.listingType,
                        child: Row(
                          children: [
                            Expanded(
                              child: _Toggle(
                                label: l.all,
                                selected: _kind == null,
                                onTap: () => _setKind(null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _Toggle(
                                label: l.forSale,
                                icon: 'assets/icons/m_realestate_tag.svg',
                                selected: _kind == ListingKind.sale,
                                onTap: () => _setKind(ListingKind.sale),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _Toggle(
                                label: l.forRent,
                                icon: 'assets/icons/m_realestate_key.svg',
                                selected: _kind == ListingKind.rent,
                                onTap: () => _setKind(ListingKind.rent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Property type ──
                      _FilterCard(
                        label: l.propertyType,
                        child: _Dropdown<PropertyType>(
                          anyLabel: l.all,
                          value: _type,
                          items: [
                            for (final t in PropertyType.values)
                              (value: t, label: _typeLabel(l, t)),
                          ],
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ),

                      // ── Neighbourhood ──
                      //
                      // The table's own rows, in the order the admin set.
                      // Left out when there are none to choose from, rather
                      // than drawn as a list holding only "All".
                      if (hoods.isLoading || hoodRows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _FilterCard(
                          label: l.neighborhood,
                          child: _Dropdown<String>(
                            anyLabel: l.all,
                            value: _neighborhoodId,
                            items: [
                              for (final h in hoodRows)
                                (value: h.id, label: h.name),
                            ],
                            onChanged: (v) =>
                                setState(() => _neighborhoodId = v),
                          ),
                        ),
                      ],

                      // ── Price ──
                      //
                      // Only once a kind is chosen: a sale's price and a
                      // let's monthly rent are different columns, and the
                      // query has no single one to compare with both.
                      if (_kind != null) ...[
                        const SizedBox(height: 16),
                        _FilterCard(
                          label: _kind == ListingKind.rent
                              ? l.pricePerMonth
                              : l.price,
                          child: Row(
                            children: [
                              Expanded(
                                child: _PriceField(
                                  controller: _minPrice,
                                  hint: l.filterPriceMin,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PriceField(
                                  controller: _maxPrice,
                                  hint: l.filterPriceMax,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Rooms (at least) ──
                      _FilterCard(
                        label: l.roomsLabel,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: l.all,
                              selected: _minRooms == null,
                              onTap: () => setState(() => _minRooms = null),
                            ),
                            for (final n in _roomSteps)
                              _Chip(
                                label: '${n.toInt()}+',
                                ltrDigits: true,
                                selected: _minRooms == n,
                                onTap: () => setState(() => _minRooms = n),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Reset + Show results ──
              //
              // The form's bottom bar: a rule above, the navy pill, and the
              // outlined pill the listing page uses for "Read More".
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Pill(
                        label: l.filterReset,
                        filled: false,
                        onTap: _reset,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Pill(
                        label: l.filterShowResults,
                        filled: true,
                        onTap: _apply,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// The pieces, drawn as the Add Apartment frame draws them
// ═══════════════════════════════════════════════════

/// A labelled white card with a hairline border — the form's field card.
class _FilterCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

/// The For Sale / For Rent toggle: tinted and outlined in navy when chosen.
class _Toggle extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.midBlue : _kGrey500;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF4FD) : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.midBlue.withValues(alpha: 0.8)
                  : _kBorder,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                SvgPicture.asset(
                  icon!,
                  width: 14,
                  height: 14,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The form's dropdown row, with "All" as its first choice and its resting
/// state.
class _Dropdown<T> extends StatelessWidget {
  final String anyLabel;
  final T? value;
  final List<({T value, String label})> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.anyLabel,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _kInk,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<T?>(
        // A saved id the list no longer holds reads as "All" rather than
        // tripping the dropdown's one-matching-item check.
        value: items.any((i) => i.value == value) ? value : null,
        isExpanded: true,
        isDense: true,
        hint: Text(
          anyLabel,
          style: style.copyWith(color: _kGrey500),
        ),
        icon: SvgPicture.asset(
          'assets/icons/m_account_chevron.svg',
          width: 20,
          height: 20,
        ),
        style: style,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(anyLabel)),
          for (final i in items)
            DropdownMenuItem<T?>(value: i.value, child: Text(i.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// A whole-shekel bound, in the same hairline box as a toggle.
class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _PriceField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _kInk,
    );

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Text('₪', style: style.copyWith(color: _kGrey500)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: style,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: style.copyWith(color: _kGrey500),
                // The theme fills inputs grey, which would draw a second box
                // inside this one.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The form's amenity chip, without an icon.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool ltrDigits;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.ltrDigits = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        // No alignment on the box: that would stretch each chip across the
        // card instead of letting it hug its label.
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF4FD) : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.midBlue.withValues(alpha: 0.8)
                  : _kBorder,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                // "3+" keeps its plus after the number in Hebrew too, where
                // the bidi rules would otherwise move it in front.
                textDirection: ltrDigits ? TextDirection.ltr : null,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.midBlue : _kGrey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The design's 44-high pill: filled navy, or outlined in navy.
class _Pill extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.midBlue : Colors.white,
            border: filled ? null : Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: filled ? Colors.white : AppColors.midBlue,
            ),
          ),
        ),
      ),
    );
  }
}
