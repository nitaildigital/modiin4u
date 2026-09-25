import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Parking — desktop car parks and payment rules
//
// The sibling of web_municipal_screen.dart, and reached from its parking
// card. The phone screen stacks the permit notice, eight car parks and a
// map placeholder in one 430px column; here the car parks take a two-up
// grid and the payment rules sit beside them, which is what the stack was
// standing in for.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);
const _kParkingBg = Color(0xFFF0F7FD);
const _kParkingBorder = Color(0xFFD9E8F4);

class WebParkingContent extends StatefulWidget {
  const WebParkingContent({super.key});

  @override
  State<WebParkingContent> createState() => _WebParkingContentState();
}

class _WebParkingContentState extends State<WebParkingContent> {
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The car parks the phone screen lists, with the capacity and the rate it
  /// prints for each.
  ///
  /// The occupancy bar and the "free / filling up / almost full" tag the phone
  /// screen draws are not here: nothing in the database or on any endpoint
  /// knows how full a car park is right now, and at desktop size a progress
  /// bar per park reads as a live feed. The same reasoning took the "Open Now"
  /// badge off the business cards.
  List<_Lot> get _lots => [
    _Lot(
      name: _t('Heichal HaTarbut car park', 'חניון היכל התרבות'),
      capacity: _t('~600 spaces', '~600 מקומות'),
      rate: _t('Free', 'חינם'),
    ),
    _Lot(
      name: _t(
        'Train station car park (by the mall)',
        'חניון הרכבת (סמוך לקניון)',
      ),
      capacity: _t('~450 spaces', '~450 מקומות'),
      rate: _t('Free', 'חינם'),
    ),
    _Lot(
      name: _t('"Gray" underground car park', 'חניון תת-קרקעי "גריי"'),
      capacity: _t('~500 spaces', '~500 מקומות'),
      rate: _t('First 2 hours free', 'חינם ל-2 שעות ראשונות'),
    ),
    _Lot(
      name: _t('Sports centre car park', 'חניון מרכז הספורט'),
      capacity: _t('~300 spaces', '~300 מקומות'),
      rate: _t('Free', 'חינם'),
    ),
    _Lot(
      name: _t('Emek Zvulun North car park', 'חניון עמק זבולון צפון'),
      capacity: _t('~200 spaces', '~200 מקומות'),
      rate: _t('Free', 'חינם'),
    ),
    _Lot(
      name: _t('By the Maccabi clinic', 'חניון ליד קופת חולים מכבי'),
      capacity: _t('55 spaces', '55 מקומות'),
      rate: _t('Free', 'חינם'),
    ),
    _Lot(
      name: _t('By the Tiltan/Dafna junction', 'חניון ליד צומת תלתן/דפנה'),
      capacity: _t('21 spaces', '21 מקומות'),
      rate: _t('Free', 'חינם'),
    ),
    _Lot(
      name: _t('Railway station car parks', 'חניוני תחנת הרכבת'),
      capacity: '—',
      rate: _t('₪70 per day', '70 ₪ ליממה'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildColumns(),
                    _buildMapPlaceholder(),
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
  // HEADER — back to city services, title, permit notice
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/municipal'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isHebrew
                          ? IconsaxPlusLinear.arrow_right_3
                          : IconsaxPlusLinear.arrow_left,
                      size: 22,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Municipal Services', 'שירותים עירוניים'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Parking in Modiin', 'חניה וחניונים'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Where to leave the car, and what it costs.',
                'איפה להשאיר את הרכב, וכמה זה עולה.',
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
            ),
            const SizedBox(height: 28),
            // The notice the phone screen opens with, at full width.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.turquoise.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.info_circle,
                    size: 20,
                    color: AppColors.turquoise,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t(
                        'Residents holding a valid city parking permit are exempt from payment, and get the first two hours free in every car park in the city.',
                        'תושבים עם תו חניה עירוני תקף פטורים מתשלום ומקבלים שעתיים ראשונות חינם בכל חניון בעיר',
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 15,
                        color: AppColors.midBlue,
                        height: 1.4,
                      ),
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
  // TWO COLUMNS — the car parks, and how paying works
  // ─────────────────────────────────────────────
  Widget _buildColumns() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: WebSection(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildLots()),
            const SizedBox(width: 40),
            Expanded(flex: 2, child: _buildPaymentColumn()),
          ],
        ),
      ),
    );
  }

  Widget _buildLots() {
    final lots = _lots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Car Parks', 'חניונים'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lots.length == 1
              ? _t('1 car park', 'חניון אחד')
              : _t('${lots.length} car parks', '${lots.length} חניונים'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
            height: 1.21,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 20.0;
            // Two across in this column at every desktop width; one below,
            // where the column itself is narrow.
            final perRow = constraints.maxWidth >= 560 ? 2 : 1;
            final cardWidth =
                (constraints.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final lot in lots)
                  SizedBox(
                    width: cardWidth,
                    // Fixed so a two-line name still lines its card up with
                    // the one beside it.
                    height: 132,
                    child: _LotCard(lot: lot),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Paying for Parking', 'תשלום על חניה'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t('What applies across the city.', 'מה שתקף בכל רחבי העיר.'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
            height: 1.21,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kParkingBg,
            border: Border.all(color: _kParkingBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paymentRow(
                IconsaxPlusLinear.clock,
                _t('Paid hours', 'שעות תשלום'),
                '08:00–19:00',
                // Two numbers either side of a dash are bidi-neutral, so in
                // Hebrew the range read back to front: "19:00–08:00".
                isLtr: true,
              ),
              _paymentRow(
                IconsaxPlusLinear.car,
                _t('Blue-and-white', 'כחול-לבן'),
                _t('Free with a permit', 'חינם עם תו'),
              ),
              _paymentRow(
                IconsaxPlusLinear.ticket,
                _t('Resident permit', 'תו תושב'),
                _t('First 2 hours free', '2 שעות ראשונות חינם'),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.midBlue.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        IconsaxPlusLinear.call,
                        size: 22,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _t('Municipal Hotline', 'המוקד העירוני'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _t('The city hotline, 24/7.', 'המוקד העירוני, 24/7.'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kGreyText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Always LTR — a phone number reads left to right in Hebrew too.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '106',
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t('or 08-9726000', 'או 08-9726000'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: _kGreyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
    bool isLtr = false,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _kParkingBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kIconGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Builder(
            builder: (context) {
              final text = Text(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                ),
                textAlign: TextAlign.end,
              );
              return isLtr
                  ? Directionality(
                      textDirection: TextDirection.ltr,
                      child: text,
                    )
                  : text;
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP — still a placeholder, as on the phone
  // ─────────────────────────────────────────────
  Widget _buildMapPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: WebSection(
        child: Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.midBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusLinear.map_1,
                size: 44,
                color: AppColors.midBlue.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _t('Parking map', 'מפת חניונים'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                ),
              ),
              const SizedBox(height: 10),
              // The phone screen draws the same empty frame. Nothing holds
              // coordinates for the car parks, so there is nothing to plot yet.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _t('Coming soon', 'בקרוב'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kGreyText,
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

class _Lot {
  final String name, capacity, rate;
  const _Lot({required this.name, required this.capacity, required this.rate});
}

class _LotCard extends StatelessWidget {
  final _Lot lot;
  const _LotCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.midBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    IconsaxPlusLinear.car,
                    size: 22,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  lot.name,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kHeading,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                IconsaxPlusLinear.element_3,
                size: 15,
                color: _kIconGrey,
              ),
              const SizedBox(width: 6),
              Text(
                lot.capacity,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: _kGreyText,
                ),
              ),
              const Spacer(),
              Text(
                lot.rate,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
