import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'osm_attribution.dart';
import 'web_chrome.dart' show webIsHebrew;

/// The website's maps, on Google's map when the build carries a key.
///
/// The client chose "the better-looking map that involves a fee (Google
/// Maps)". The app's main map already is Google's; the website's ten maps
/// drew OpenStreetMap. They keep their own renderer — the design's pins, the
/// hover that lights a row and its pin together, the cards laid over the
/// map — and take Google's map itself through the Map Tiles API, which is
/// Google's way of serving its roadmap to a renderer of your own.
///
/// The key is a browser key, restricted to the site's addresses, given at
/// build time (`--dart-define=MAPS_WEB_KEY=…`, which tool/deploy_web.sh reads
/// from .env.local). It is in the page for anyone to read, as every Maps key
/// in a web page is; the restriction is what protects it. It does not work
/// from the app, which sends no address, so the app's other maps stay on
/// OpenStreetMap until they are moved to the Google map widget.
///
/// Without a key, or if Google refuses the session, the maps draw
/// OpenStreetMap as before rather than nothing.
const _key = String.fromEnvironment('MAPS_WEB_KEY');

bool get _googleTiles => kIsWeb && _key.isNotEmpty;

class _GoogleSession {
  final String token;

  /// The credit Google gives for the area — "Map data ©2026 Google, Mapa
  /// GISrael" — which must be shown on the map with its logo.
  final String copyright;
  const _GoogleSession(this.token, this.copyright);
}

/// One session per label language: the English site gets an English map,
/// the Hebrew one a Hebrew map. A session lasts about two weeks, far longer
/// than a visit.
final _sessionProvider = FutureProvider.family<_GoogleSession?, bool>((ref, hebrew) async {
  if (!_googleTiles) return null;
  try {
    final res = await http.post(
      Uri.parse('https://tile.googleapis.com/v1/createSession?key=$_key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mapType': 'roadmap',
        'language': hebrew ? 'he-IL' : 'en-US',
        'region': 'IL',
        // Sharp on the high-density screens most visitors have; billed the
        // same per tile.
        'scale': 'scaleFactor2x',
        'highDpi': true,
        // Google's own shop and restaurant markers would crowd ours, and
        // could name places the directory does not list.
        'styles': [
          {
            'featureType': 'poi.business',
            'stylers': [
              {'visibility': 'off'},
            ],
          },
        ],
      }),
    );
    if (res.statusCode != 200) {
      debugPrint('Google map session refused (${res.statusCode}); drawing OpenStreetMap');
      return null;
    }
    final token = (jsonDecode(res.body) as Map<String, dynamic>)['session'] as String;

    // The credit for Modiin, which is where every map on the site looks.
    var copyright = 'Map data ©${DateTime.now().year} Google';
    try {
      final v = await http.get(Uri.parse(
        'https://tile.googleapis.com/tile/v1/viewport?session=$token&key=$_key'
        '&zoom=13&north=31.95&south=31.85&east=35.08&west=34.95',
      ));
      final said = v.statusCode == 200 ? (jsonDecode(v.body) as Map<String, dynamic>)['copyright'] as String? : null;
      if (said != null && said.isNotEmpty) copyright = said;
    } catch (_) {}
    return _GoogleSession(token, copyright);
  } catch (e) {
    debugPrint('Google map session failed ($e); drawing OpenStreetMap');
    return null;
  }
});

TileLayer _osm({int maxZoom = 19, TileBuilder? tileBuilder}) => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.modiin4u.app',
      maxZoom: maxZoom.toDouble(),
      tileBuilder: tileBuilder,
    );

/// The map itself, for a `FlutterMap`'s children: Google's roadmap in the
/// page's language, or OpenStreetMap.
class WebMapTiles extends ConsumerWidget {
  /// For a page that tints the map, as the listing page greys it.
  final TileBuilder? tileBuilder;
  const WebMapTiles({super.key, this.tileBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_googleTiles) return _osm(tileBuilder: tileBuilder);
    return ValueListenableBuilder<bool>(
      valueListenable: webIsHebrew,
      builder: (context, hebrew, _) {
        final session = ref.watch(_sessionProvider(hebrew));
        return session.when(
          // A moment of the map's own background, not OpenStreetMap
          // flashing up and being replaced.
          loading: () => const SizedBox.shrink(),
          error: (_, _) => _osm(tileBuilder: tileBuilder),
          data: (s) => s == null
              ? _osm(tileBuilder: tileBuilder)
              : TileLayer(
                  urlTemplate: 'https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session=${s.token}&key=$_key',
                  maxZoom: 21,
                  tileBuilder: tileBuilder,
                ),
        );
      },
    );
  }
}

/// Whose map it is, in the corner, as each provider requires: Google's logo
/// and credit, or OpenStreetMap's.
class WebMapCredit extends ConsumerWidget {
  const WebMapCredit({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_googleTiles) return const OsmAttribution();
    return ValueListenableBuilder<bool>(
      valueListenable: webIsHebrew,
      builder: (context, hebrew, _) {
        final session = ref.watch(_sessionProvider(hebrew));
        if (session.isLoading) return const SizedBox.shrink();
        final s = session.valueOrNull;
        if (s == null) return const OsmAttribution();
        // The logo and credit sit in the same corners whatever the page's
        // language: they belong to the map, which does not mirror.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned(
                left: 6,
                bottom: 4,
                child: Image.asset('assets/web/common/google_logo.png', width: 66, height: 26),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.copyright,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF3A3A3A)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
