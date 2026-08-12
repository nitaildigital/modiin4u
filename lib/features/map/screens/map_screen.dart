import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

final _modiinCenter = LatLng(31.8928, 35.0104);

class _MapPoi {
  final String name;
  final String category;
  final LatLng position;
  final IconData icon;
  final Color color;
  final String layer;
  final String? route;

  const _MapPoi({
    required this.name,
    required this.category,
    required this.position,
    required this.icon,
    required this.color,
    required this.layer,
    this.route,
  });
}

final _pois = [
  _MapPoi(name: 'קפה גרג', category: 'בית קפה', position: LatLng(31.8935, 35.0110), icon: Icons.coffee, color: AppColors.turquoise, layer: 'עסקים', route: '/business/demo_2'),
  _MapPoi(name: 'פיצה פרגו', category: 'מסעדה', position: LatLng(31.8920, 35.0080), icon: Icons.local_pizza, color: AppColors.turquoise, layer: 'עסקים', route: '/business/demo_1'),
  _MapPoi(name: 'מסעדת נאיתאי', category: 'תאילנדי', position: LatLng(31.8945, 35.0125), icon: Icons.restaurant, color: AppColors.turquoise, layer: 'עסקים', route: '/business/demo_0'),
  _MapPoi(name: 'סושי מודיעין', category: 'סושי', position: LatLng(31.8910, 35.0095), icon: Icons.restaurant, color: AppColors.turquoise, layer: 'עסקים', route: '/business/demo_4'),
  _MapPoi(name: 'בורגרס בר', category: 'המבורגרים', position: LatLng(31.8955, 35.0070), icon: Icons.lunch_dining, color: AppColors.turquoise, layer: 'עסקים', route: '/business/demo_3'),
  _MapPoi(name: 'סופר יוחננוף', category: 'מרכול', position: LatLng(31.8940, 35.0060), icon: Icons.shopping_cart, color: AppColors.turquoise, layer: 'עסקים'),
  _MapPoi(name: 'חניון היכל התרבות', category: '~600 מקומות', position: LatLng(31.8930, 35.0140), icon: Icons.local_parking, color: AppColors.midBlue, layer: 'חניה'),
  _MapPoi(name: 'חניון הרכבת', category: '~450 מקומות', position: LatLng(31.8960, 35.0050), icon: Icons.local_parking, color: AppColors.midBlue, layer: 'חניה'),
  _MapPoi(name: 'חניון גריי', category: '~500 מקומות', position: LatLng(31.8918, 35.0115), icon: Icons.local_parking, color: AppColors.midBlue, layer: 'חניה'),
  _MapPoi(name: 'פסטיבל אוכל רחוב', category: 'יום ה׳ 14.08', position: LatLng(31.8900, 35.0130), icon: Icons.event, color: AppColors.gold, layer: 'אירועים', route: '/event/demo_0'),
  _MapPoi(name: 'הופעה — עידן רייכל', category: 'שבת 16.08', position: LatLng(31.8932, 35.0145), icon: Icons.music_note, color: AppColors.gold, layer: 'אירועים', route: '/event/demo_1'),
  _MapPoi(name: '4 חד׳ · 2,450,000 ₪', category: 'הפרחים', position: LatLng(31.8950, 35.0100), icon: Icons.apartment, color: AppColors.navy, layer: 'נדל"ן', route: '/listing/demo_0'),
  _MapPoi(name: '5 חד׳ · 3,100,000 ₪', category: 'אבני חן', position: LatLng(31.8905, 35.0065), icon: Icons.apartment, color: AppColors.navy, layer: 'נדל"ן', route: '/listing/demo_1'),
  _MapPoi(name: '3 חד׳ · 1,950,000 ₪', category: 'המע"ר', position: LatLng(31.8925, 35.0090), icon: Icons.apartment, color: AppColors.navy, layer: 'נדל"ן', route: '/listing/demo_2'),
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _activeLayers = <String>{'עסקים'};
  final _mapController = MapController();
  _MapPoi? _selectedPoi;

  final _layers = [
    ('עסקים', Icons.store, AppColors.turquoise),
    ('חניה', Icons.local_parking, AppColors.midBlue),
    ('אירועים', Icons.event, AppColors.gold),
    ('נדל"ן', Icons.apartment, AppColors.navy),
  ];

  List<_MapPoi> get _visiblePois =>
      _pois.where((p) => _activeLayers.contains(p.layer)).toList();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _modiinCenter,
              initialZoom: 15.0,
              minZoom: 12,
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selectedPoi = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.modiin4u.app',
                maxZoom: 20,
              ),
              MarkerLayer(
                markers: _visiblePois.map((poi) {
                  final isSelected = _selectedPoi == poi;
                  return Marker(
                    point: poi.position,
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPoi = poi),
                      child: Container(
                        decoration: BoxDecoration(
                          color: poi.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: poi.color.withValues(alpha: 0.4),
                              blurRadius: isSelected ? 10 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(poi.icon, size: isSelected ? 22 : 18, color: AppColors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'חפשו מקום, עסק, כתובת...',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight),
                        prefixIcon: const Icon(Icons.search, color: AppColors.grayLight, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _layers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final (label, icon, color) = _layers[index];
                      final active = _activeLayers.contains(label);
                      final count = _pois.where((p) => p.layer == label).length;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (active) {
                              _activeLayers.remove(label);
                            } else {
                              _activeLayers.add(label);
                            }
                            _selectedPoi = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: active ? color.withValues(alpha: 0.12) : AppColors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: active ? color : AppColors.border),
                            boxShadow: const [
                              BoxShadow(color: AppColors.cardShadow, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: active ? color : AppColors.grayMeta),
                              const SizedBox(width: 6),
                              Text(
                                '$label ($count)',
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  color: active ? color : AppColors.grayMeta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            bottom: _selectedPoi != null ? 190 : 110,
            child: Column(
              children: [
                _MapFab(Icons.my_location, () {
                  _mapController.move(_modiinCenter, 15);
                }),
                const SizedBox(height: 8),
                _MapFab(Icons.add, () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                }),
                const SizedBox(height: 8),
                _MapFab(Icons.remove, () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                }),
              ],
            ),
          ),

          if (_selectedPoi != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _PoiCard(
                poi: _selectedPoi!,
                onClose: () => setState(() => _selectedPoi = null),
                onTap: () {
                  if (_selectedPoi?.route != null) {
                    context.push(_selectedPoi!.route!);
                  }
                },
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                itemCount: _visiblePois.length > 8 ? 8 : _visiblePois.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final poi = _visiblePois[index];
                  return GestureDetector(
                    onTap: () {
                      _mapController.move(poi.position, 16.5);
                      setState(() => _selectedPoi = poi);
                    },
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedPoi == poi ? poi.color : AppColors.border,
                          width: _selectedPoi == poi ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: poi.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(poi.icon, size: 18, color: poi.color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  poi.name,
                                  style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  poi.category,
                                  style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayMeta),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFab(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: AppColors.midBlue, size: 22),
      ),
    );
  }
}

class _PoiCard extends StatelessWidget {
  final _MapPoi poi;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _PoiCard({required this.poi, required this.onClose, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: poi.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(poi.icon, size: 24, color: poi.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  poi.name,
                  style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                Text(
                  poi.category,
                  style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayMeta),
                ),
              ],
            ),
          ),
          if (poi.route != null)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: poi.color,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'פרטים',
                  style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 20, color: AppColors.grayLight),
          ),
        ],
      ),
    );
  }
}
