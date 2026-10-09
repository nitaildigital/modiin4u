import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
/// from the app, which sends no address; the app draws Google's own map
/// widget instead (AppMap).
///
/// OpenStreetMap is gone from the site as the client asked: without a key
/// (a local build), or if Google refuses the session, the map shows its
/// plain background and the pins, not another provider's map.
const _key = String.fromEnvironment('MAPS_WEB_KEY');

bool get _googleTiles => kIsWeb && _key.isNotEmpty;

class _GoogleSession {
  final String token;

  /// The credit Google gives for the area — "Map data ©2026 Google, Mapa
  /// GISrael" — which must be shown on the map with its logo.
  final String copyright;

  /// When Google ends the session, in milliseconds since the epoch.
  final int expires;
  const _GoogleSession(this.token, this.copyright, this.expires);

  Map<String, dynamic> toJson() => {'token': token, 'copyright': copyright, 'expires': expires};
}

/// The session is kept in the browser for its life (9 Oct). A new one on
/// every visit gave every tile a new address, so the browser could never
/// reuse a tile it already had, and each visit's map was drawn — and billed
/// — afresh; the credit is kept with it, so its call is made once too.
Future<_GoogleSession?> _storedSession(bool hebrew) async {
  try {
    final raw = (await SharedPreferences.getInstance()).getString('map_session_${hebrew ? 'he' : 'en'}');
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final s = _GoogleSession(j['token'] as String, j['copyright'] as String, (j['expires'] as num).toInt());
    // An hour's margin, so a session never runs out in the middle of a visit.
    return s.expires - 3600000 > DateTime.now().millisecondsSinceEpoch ? s : null;
  } catch (_) {
    return null;
  }
}

/// One session per label language: the English site gets an English map,
/// the Hebrew one a Hebrew map. A session lasts about two weeks, far longer
/// than a visit.
final _sessionProvider = FutureProvider.family<_GoogleSession?, bool>((ref, hebrew) async {
  if (!_googleTiles) return null;
  final kept = await _storedSession(hebrew);
  if (kept != null) return kept;
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
      debugPrint('Google map session refused (${res.statusCode}); no map tiles');
      return null;
    }
    final made = jsonDecode(res.body) as Map<String, dynamic>;
    final token = made['session'] as String;
    // Google gives the expiry in seconds; a week if it says nothing.
    final expires = int.tryParse('${made['expiry'] ?? ''}') != null
        ? int.parse('${made['expiry']}') * 1000
        : DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;

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
    final fresh = _GoogleSession(token, copyright, expires);
    try {
      await (await SharedPreferences.getInstance())
          .setString('map_session_${hebrew ? 'he' : 'en'}', jsonEncode(fresh.toJson()));
    } catch (_) {}
    return fresh;
  } catch (e) {
    debugPrint('Google map session failed ($e); no map tiles');
    return null;
  }
});

/// The map itself, for a `FlutterMap`'s children: Google's roadmap in the
/// page's language, or nothing while it is unavailable.
class WebMapTiles extends ConsumerWidget {
  /// For a page that tints the map, as the listing page greys it.
  final TileBuilder? tileBuilder;
  const WebMapTiles({super.key, this.tileBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_googleTiles) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: webIsHebrew,
      builder: (context, hebrew, _) {
        final session = ref.watch(_sessionProvider(hebrew));
        return session.when(
          // The map's own background for the moment the session takes.
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (s) => s == null
              ? const SizedBox.shrink()
              : TileLayer(
                  urlTemplate: 'https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session=${s.token}&key=$_key',
                  maxZoom: 21,
                  tileBuilder: tileBuilder,
                  // Tiles are asked for once the map settles, not for every
                  // frame of a pan or a zoom — each one is a billed request.
                  tileUpdateTransformer: TileUpdateTransformers.debounce(const Duration(milliseconds: 250)),
                ),
        );
      },
    );
  }
}

/// Whose map it is, in the corner, as Google requires: its logo and the
/// credit it gives for the area.
class WebMapCredit extends ConsumerWidget {
  const WebMapCredit({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_googleTiles) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: webIsHebrew,
      builder: (context, hebrew, _) {
        final session = ref.watch(_sessionProvider(hebrew));
        if (session.isLoading) return const SizedBox.shrink();
        final s = session.valueOrNull;
        if (s == null) return const SizedBox.shrink();
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
