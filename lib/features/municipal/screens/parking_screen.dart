import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/parking_providers.dart';
import '../widgets/parking_widgets.dart';
import 'web_parking_screen.dart';

/// Parking — the car parks the client enters in the panel (חניונים), on a
/// map and in a list.
///
/// The screen used to list eight car parks written into the source, with
/// capacities, rates, an occupancy bar and a notice that residents with a
/// permit park two hours free. None of it came from anywhere the client could
/// correct, and nothing measures occupancy, so it is all gone: what shows now
/// is what he entered, and nothing where he entered nothing.
class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebParkingContent();
        return const _MobileParking();
      },
    );
  }
}

class _MobileParking extends ConsumerStatefulWidget {
  const _MobileParking();

  @override
  ConsumerState<_MobileParking> createState() => _MobileParkingState();
}

class _MobileParkingState extends ConsumerState<_MobileParking> {
  final _map = MapController();
  final _cardKeys = <String, GlobalKey>{};
  String? _selectedId;

  /// A pin brings its card into view below the map.
  void _selectFromMap(ParkingLot? lot) {
    setState(() => _selectedId = lot?.id);
    final card = lot == null ? null : _cardKeys[lot.id]?.currentContext;
    if (card != null) {
      Scrollable.ensureVisible(
        card,
        duration: const Duration(milliseconds: 300),
        alignment: 0.05,
      );
    }
  }

  /// A card brings its pin into view on the map.
  void _selectFromList(ParkingLot lot) {
    setState(() => _selectedId = lot.id);
    final zoom = _map.camera.zoom;
    _map.move(lot.position, zoom < 16 ? 16 : zoom);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final lots = ref.watch(parkingLotsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l.parkingInModiin,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: lots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: ParkingMessage(
            icon: IconsaxPlusLinear.warning_2,
            text: l.parkingLoadError,
            action: TextButton(
              onPressed: () => ref.invalidate(parkingLotsProvider),
              child: Text(l.tryAgain),
            ),
          ),
        ),
        data: (lots) {
          if (lots.isEmpty) {
            return Center(
              child: ParkingMessage(
                icon: IconsaxPlusLinear.car,
                text: l.parkingEmpty,
              ),
            );
          }
          return Column(
            children: [
              SizedBox(
                height: 260,
                child: ParkingMap(
                  lots: lots,
                  controller: _map,
                  selectedId: _selectedId,
                  onSelect: _selectFromMap,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(parkingLotsProvider.future),
                  // A column rather than a lazy list, so a pin far down the
                  // list still has a card built to scroll to. The city has
                  // dozens of lots, not thousands.
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.parkingLotCount(lots.length),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: const Color(0xFF5F5E5A),
                          ),
                        ),
                        for (final lot in lots) ...[
                          const SizedBox(height: 12),
                          ParkingLotCard(
                            key: _cardKeys.putIfAbsent(lot.id, GlobalKey.new),
                            lot: lot,
                            l: l,
                            english: english,
                            selected: lot.id == _selectedId,
                            onTap: () => _selectFromList(lot),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
