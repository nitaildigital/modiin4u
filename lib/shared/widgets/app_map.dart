import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import '../../features/map/screens/web_map_screen.dart' show WebMapPin;
import '../../features/map/widgets/map_pin_bitmap.dart';
import 'web_map_tiles.dart';

/// One place on an [AppMap]: where it is and which of the design's pins
/// marks it — a teardrop SVG (assets/web/map/, assets/web/events/), or the
/// phone restaurants map's round pin, a coloured disc with a glyph.
class AppMapPin {
  final String id;
  final LatLng position;
  final String? asset;
  final Color? circleColor;
  final IconData? icon;

  const AppMapPin({
    required this.id,
    required this.position,
    required String this.asset,
  }) : circleColor = null,
       icon = null;

  const AppMapPin.circle({
    required this.id,
    required this.position,
    required Color color,
    required IconData this.icon,
  }) : asset = null,
       circleColor = color;

  bool get isCircle => asset == null;
}

/// Moves an [AppMap]'s camera from outside it — the parking list centring
/// the lot that was tapped.
class AppMapController {
  _AppMapState? _map;

  void moveTo(LatLng position, {double zoom = 16}) =>
      _map?._moveTo(position, zoom);
}

/// Google's map, on every screen that shows one.
///
/// The client chose Google Maps. The app's main map already was; the other
/// maps — a listing's, an event's, the restaurants, events, real-estate and
/// parking maps — drew OpenStreetMap. Each now draws this:
///
///  * in the app, Google's own map widget (Maps SDK for Android and iOS),
///    with the design's pins drawn as bitmaps (MapPinBitmap) — the native
///    map, at no charge per view, with the Android key in local.properties;
///  * in a browser, the website's renderer over Google's roadmap tiles
///    (WebMapTiles, the Map Tiles API with the site's key), which keeps the
///    pins and cards the website's design lays over the map.
///
/// A small map on a detail page is a picture of the place, not something to
/// pan: [interactive] false freezes it (on Android, Google's lite mode, a
/// static image of the map).
class AppMap extends StatefulWidget {
  final List<AppMapPin> pins;
  final String? selectedId;

  /// A pin's id when it is tapped; null when the map around the pins is.
  final ValueChanged<String?>? onSelect;
  final LatLng center;
  final double zoom;

  /// With two or more pins, open framed on all of them rather than on
  /// [center].
  final bool fitPins;
  final bool interactive;

  /// Off where the map sits in a page that scrolls, so the wheel moves the
  /// page rather than zooming the map (the website's parking page).
  final bool scrollWheelZoom;
  final double minZoom;
  final double maxZoom;
  final AppMapController? controller;

  /// Room kept clear at the foot of the map — for a card laid over it — so
  /// Google's logo and credit stay visible.
  final double bottomPadding;

  const AppMap({
    super.key,
    required this.pins,
    required this.center,
    this.zoom = 14.5,
    this.selectedId,
    this.onSelect,
    this.fitPins = false,
    this.interactive = true,
    this.scrollWheelZoom = true,
    this.minZoom = 11,
    this.maxZoom = 18,
    this.controller,
    this.bottomPadding = 0,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  gm.GoogleMapController? _google;
  final fm.MapController _flutterMap = fm.MapController();

  // Markers are bitmaps drawn off to the side; the map takes them up when
  // they are ready. A build that finishes after a newer one started is
  // thrown away.
  Set<gm.Marker> _markers = {};
  int _ticket = 0;
  Set<String> _drawnKey = {};

  /// Google's own shops and restaurants would crowd the directory's pins
  /// and name places it does not list — hidden, as on the website's map.
  static const _style =
      '[{"featureType":"poi.business","stylers":[{"visibility":"off"}]}]';

  /// Whether the iPhone build was given a Google Maps key (AppDelegate),
  /// asked once. Google's SDK closes the app when a map opens without one,
  /// so until the answer is yes an iPhone draws the website's renderer: the
  /// pins on the map's plain background, as the website shows them without
  /// its key (WebMapTiles) — no other provider's map, as the client asked.
  /// Null while the question is out.
  static bool? _iosHasKey;
  static Future<bool>? _iosKeyQuestion;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// The website's renderer: always in a browser, and on an iPhone that
  /// has no Google key.
  bool get _flutterMapDraws => kIsWeb || (_isIos && _iosHasKey != true);

  @override
  void initState() {
    super.initState();
    widget.controller?._map = this;
    if (_isIos && _iosHasKey == null) {
      _iosKeyQuestion ??= const MethodChannel('modiin4u/maps')
          .invokeMethod<bool>('hasKey')
          .then((v) => _iosHasKey = v ?? false)
          .catchError((_) => _iosHasKey = false);
      _iosKeyQuestion!.then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(AppMap old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._map = null;
      widget.controller?._map = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._map = null;
    super.dispose();
  }

  void _moveTo(LatLng p, double zoom) {
    if (_flutterMapDraws) {
      _flutterMap.move(p, zoom);
    } else {
      _google?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(gm.LatLng(p.latitude, p.longitude), zoom),
      );
    }
  }

  Future<void> _drawMarkers() async {
    final ticket = ++_ticket;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final built = <gm.Marker>{};
    for (final pin in widget.pins) {
      final selected = pin.id == widget.selectedId;
      built.add(
        gm.Marker(
          markerId: gm.MarkerId(pin.id),
          position: gm.LatLng(pin.position.latitude, pin.position.longitude),
          icon: pin.isCircle
              ? await MapPinBitmap.ofCircle(
                  color: pin.circleColor!,
                  icon: pin.icon!,
                  isSelected: selected,
                  devicePixelRatio: ratio,
                )
              : await MapPinBitmap.ofAsset(
                  asset: pin.asset!,
                  isSelected: selected,
                  devicePixelRatio: ratio,
                ),
          anchor: pin.isCircle ? const Offset(0.5, 0.45) : MapPinBitmap.anchor,
          zIndexInt: selected ? 1 : 0,
          consumeTapEvents: true,
          onTap: widget.onSelect == null
              ? null
              : () => widget.onSelect!(pin.id),
        ),
      );
    }
    if (!mounted || ticket != _ticket) return;
    setState(() => _markers = built);
  }

  gm.LatLngBounds? get _bounds {
    if (!widget.fitPins || widget.pins.length < 2) return null;
    var s = widget.pins.first.position.latitude, n = s;
    var w = widget.pins.first.position.longitude, e = w;
    for (final p in widget.pins) {
      s = p.position.latitude < s ? p.position.latitude : s;
      n = p.position.latitude > n ? p.position.latitude : n;
      w = p.position.longitude < w ? p.position.longitude : w;
      e = p.position.longitude > e ? p.position.longitude : e;
    }
    return gm.LatLngBounds(
      southwest: gm.LatLng(s, w),
      northeast: gm.LatLng(n, e),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A moment's plain background on an iPhone while it is asked whether it
    // has a key, rather than opening Google's map and closing the app.
    if (_isIos && _iosHasKey == null) {
      return const ColoredBox(color: Color(0xFFF9F5ED));
    }
    return _flutterMapDraws ? _web() : _app();
  }

  Widget _app() {
    // Redraw when the pins on the map or the chosen one change.
    final key = {
      for (final p in widget.pins) '${p.id}|${p.id == widget.selectedId}',
    };
    if (!setEquals(key, _drawnKey)) {
      _drawnKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _drawMarkers();
      });
    }
    final interactive = widget.interactive;
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(widget.center.latitude, widget.center.longitude),
        zoom: widget.zoom,
      ),
      onMapCreated: (c) {
        _google = c;
        final b = _bounds;
        if (b != null) {
          // After the first layout, when the map knows its size.
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) c.moveCamera(gm.CameraUpdate.newLatLngBounds(b, 48));
          });
        }
      },
      style: _style,
      markers: _markers,
      minMaxZoomPreference: gm.MinMaxZoomPreference(
        widget.minZoom,
        widget.maxZoom,
      ),
      onTap: widget.onSelect == null ? null : (_) => widget.onSelect!(null),
      liteModeEnabled: !interactive,
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      // The designs draw no buttons over a map; pinching zooms.
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
    );
  }

  Widget _web() {
    final pins = widget.pins;
    final fit = widget.fitPins && pins.length >= 2;
    return fm.FlutterMap(
      mapController: _flutterMap,
      options: fm.MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        initialCameraFit: fit
            ? fm.CameraFit.coordinates(
                coordinates: [for (final p in pins) p.position],
                padding: const EdgeInsets.all(48),
                maxZoom: 16,
              )
            : null,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        backgroundColor: const Color(0xFFF9F5ED),
        interactionOptions: fm.InteractionOptions(
          flags: !widget.interactive
              ? fm.InteractiveFlag.none
              : widget.scrollWheelZoom
              ? fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate
              : fm.InteractiveFlag.all &
                    ~fm.InteractiveFlag.rotate &
                    ~fm.InteractiveFlag.scrollWheelZoom,
        ),
        onTap: widget.onSelect == null
            ? null
            : (_, _) => widget.onSelect!(null),
      ),
      children: [
        const WebMapTiles(),
        fm.MarkerLayer(
          markers: [
            for (final pin in pins)
              fm.Marker(
                point: pin.position,
                width: 40,
                height: pin.isCircle ? 40 : 44,
                // A teardrop's point, not its middle, sits on the place; a
                // round pin sits centred on it.
                alignment: pin.isCircle
                    ? Alignment.center
                    : Alignment.topCenter,
                child: MouseRegion(
                  cursor: widget.onSelect == null
                      ? MouseCursor.defer
                      : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onSelect == null
                        ? null
                        : () => widget.onSelect!(pin.id),
                    child: pin.isCircle
                        ? _CirclePin(
                            color: pin.circleColor!,
                            icon: pin.icon!,
                            selected: pin.id == widget.selectedId,
                          )
                        : AnimatedScale(
                            scale: pin.id == widget.selectedId ? 1.2 : 1,
                            alignment: Alignment.bottomCenter,
                            duration: const Duration(milliseconds: 150),
                            child: WebMapPin(asset: pin.asset!),
                          ),
                  ),
                ),
              ),
          ],
        ),
        const WebMapCredit(),
      ],
    );
  }
}

/// The round pin as a widget, for the browser's map; MapPinBitmap.ofCircle
/// draws the same for Google's.
class _CirclePin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool selected;
  const _CirclePin({
    required this.color,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2.28,
            offset: const Offset(0, 2.28),
          ),
        ],
        border: selected
            ? Border.all(color: const Color(0xFF123A72), width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}
