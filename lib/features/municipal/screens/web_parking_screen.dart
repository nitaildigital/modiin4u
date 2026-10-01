import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import '../../../shared/widgets/app_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/parking_providers.dart';
import '../widgets/parking_widgets.dart';

// ═══════════════════════════════════════════════════════════
// Web Parking — the city's car parks, on a map beside their list
//
// The sibling of web_municipal_screen.dart, and reached from its parking
// card. The lots are the ones the client enters in the panel (חניונים); the
// page used to print eight written into the source, with capacities, rates,
// paid hours and permit rules nobody could correct from the panel. Those are
// gone rather than kept as "general information": the client runs the
// content, and none of it was his.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);

/// The map and the list side by side, at one height, so the list scrolls
/// inside it and the map never leaves the screen.
const _kPaneHeight = 640.0;

class WebParkingContent extends ConsumerStatefulWidget {
  const WebParkingContent({super.key});

  @override
  ConsumerState<WebParkingContent> createState() => _WebParkingContentState();
}

class _WebParkingContentState extends ConsumerState<WebParkingContent>
    with WebLanguageState<WebParkingContent> {
  bool get _isHebrew => webIsHebrew.value;

  /// The navbar's toggle is this page's language, not the app's locale, so
  /// both string tables are held and the page reads the one it is in.
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));
  L get _l => _isHebrew ? _he : _en;

  final _map = AppMapController();
  final _listScroll = ScrollController();
  final _cardKeys = <String, GlobalKey>{};
  String? _selectedId;

  @override
  void dispose() {
    _listScroll.dispose();
    super.dispose();
  }

  void _selectFromMap(ParkingLot? lot) {
    setState(() => _selectedId = lot?.id);
    // Scrolls the list alone. `Scrollable.ensureVisible` would scroll the
    // page as well, and take the map half off the screen with it.
    final card = lot == null
        ? null
        : _cardKeys[lot.id]?.currentContext?.findRenderObject();
    if (card == null || !_listScroll.hasClients) return;
    final target = RenderAbstractViewport.of(card)
        .getOffsetToReveal(card, 0.05)
        .offset
        .clamp(0.0, _listScroll.position.maxScrollExtent);
    _listScroll.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _selectFromList(ParkingLot lot) {
    setState(() => _selectedId = lot.id);
    _map.moveTo(lot.position);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: _isHebrew),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildBody(),
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
  // HEADER — back to city services, title
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    final l = _l;
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
                      l.municipalServices,
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
              l.parkingInModiin,
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
              l.parkingIntro,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY — the list and the map, or why there is neither
  // ─────────────────────────────────────────────
  Widget _buildBody() {
    final l = _l;
    final lots = ref.watch(parkingLotsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: WebSection(
        child: lots.when(
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _messageBox(
            ParkingMessage(
              icon: IconsaxPlusLinear.warning_2,
              text: l.parkingLoadError,
              action: TextButton(
                onPressed: () => ref.invalidate(parkingLotsProvider),
                child: Text(l.tryAgain),
              ),
            ),
          ),
          data: (lots) => lots.isEmpty
              ? _messageBox(
                  ParkingMessage(
                    icon: IconsaxPlusLinear.car,
                    text: l.parkingEmpty,
                  ),
                )
              : _buildPanes(lots),
        ),
      ),
    );
  }

  Widget _messageBox(Widget child) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.midBlue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildPanes(List<ParkingLot> lots) {
    final l = _l;
    return SizedBox(
      height: _kPaneHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.parkingLotsHeading,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.parkingLotCount(lots.length),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: _kGreyText,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  // A column rather than a lazy list, so a pin far down the
                  // list still has a card built to scroll to.
                  child: SingleChildScrollView(
                    controller: _listScroll,
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final lot in lots) ...[
                          ParkingLotCard(
                            key: _cardKeys.putIfAbsent(lot.id, GlobalKey.new),
                            lot: lot,
                            l: l,
                            english: !_isHebrew,
                            selected: lot.id == _selectedId,
                            onTap: () => _selectFromList(lot),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // The car parks came from OpenStreetMap's data,
                        // whose licence asks for this credit.
                        const SizedBox(height: 8),
                        ParkingDataCredit(text: l.mapDataCredit),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ParkingMap(
                  lots: lots,
                  controller: _map,
                  selectedId: _selectedId,
                  onSelect: _selectFromMap,
                  websiteTiles: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
