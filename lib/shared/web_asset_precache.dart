import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fetches the website's pictures as the app starts, rather than one by one
/// as each is first drawn.
///
/// The pictures are the app's own files — built into `assets/`, served from
/// our server beside main.dart.js — but a browser does not have them until
/// it asks, and Flutter asks for an asset the first time a widget paints it.
/// So the home page came up bare and filled in: the palms, then the torch,
/// then each icon in the navbar, a moment apart.
///
/// Both caches it fills are the ones the widgets read: [AssetImage] resolves
/// to the same key an `Image.asset` builds (no resolution variants, the root
/// bundle), and [SvgAssetLoader] to the same key an `SvgPicture.asset` does.
///
/// The returned future completes when what the home page's first screen shows
/// is in. Everything else keeps loading behind it.
Future<void> precacheWebAssets() async {
  if (!kIsWeb) return;

  final List<String> assets;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    assets = manifest
        .listAssets()
        .where((a) =>
            a.startsWith('assets/web/') ||
            a.startsWith('assets/icons/') ||
            a == 'assets/images/logo_white.svg')
        .toList();
  } catch (_) {
    return;
  }

  // Every web SVG, with room to spare; the default holds a hundred.
  svg.cache.maximumSize = 300;

  // What the first screen shows, so it opens whole: the navbar's logo and
  // chevron everywhere; on the home page the hero's line art, search, pills
  // and the seven category icons (about twenty files, 70 KB); on Restaurants,
  // Real Estate or Events that page's photograph and the dotted field behind
  // it. Asking for all 111 at once had them queue behind one another, and on
  // a slow line the first screen came up three seconds later for it.
  const home = 'assets/web/home/';
  const firstCards = {'news', 'events', 'community', 'professionals', 'maps', 'businesses', 'realestate'};
  final page = Uri.base.path;
  final pageFolder = const {
    '/restaurants': 'assets/web/restaurants/',
    '/realestate': 'assets/web/realestate/',
    '/events': 'assets/web/events/',
  }[page];

  bool firstScreen(String a) {
    if (a == 'assets/images/logo_white.svg' || a == 'assets/icons/chevron_down.svg') return true;
    if (page == '/' || page.isEmpty) {
      return a.startsWith('${home}hero_') ||
          a.startsWith('${home}pill_') ||
          a == '${home}search.svg' ||
          a == '${home}ai.svg' ||
          firstCards.any((c) => a == '${home}card_$c.svg');
    }
    if (pageFolder != null) {
      return a.startsWith(pageFolder) ||
          a == 'assets/web/common/dots_tile.png' ||
          a.startsWith('assets/web/common/search');
    }
    return false;
  }

  bool photo(String a) => a.endsWith('.webp') || a.endsWith('.png') || a.endsWith('.jpg');

  final now = assets.where(firstScreen).toList();
  final rest = assets.where((a) => !firstScreen(a)).toList();

  await Future.wait(now.map(_load));
  // Then the other pages' photographs, which are what a visitor waits on
  // when they click through; the small icons after them.
  unawaited(() async {
    await Future.wait(rest.where(photo).map(_load));
    await Future.wait(rest.where((a) => !photo(a)).map(_load));
  }());
}

/// Loads one asset into its cache. A preload is only ever a head start, so
/// nothing here may fail the app: an asset that will not load is named in the
/// console and left for the page to fetch itself.
Future<void> _load(String asset) async {
  try {
    if (asset.endsWith('.svg')) {
      await SvgAssetLoader(asset).loadBytes(null);
    } else if (asset.endsWith('.png') || asset.endsWith('.jpg') || asset.endsWith('.jpeg') || asset.endsWith('.webp')) {
      await _image(asset);
    }
  } catch (e) {
    debugPrint('Preload skipped $asset: $e');
  }
}

/// Resolves an asset image into the image cache and waits for it to decode.
///
/// The listener is never removed, so the image stays live. Flutter's image
/// cache holds 100 MB and drops the least recently used; the businesses and
/// restaurants pages fill it with directory photos, and the heroes preloaded
/// at start were being pushed out — the Restaurants hero came up blank on the
/// way back from Events. A live image is kept however full the cache gets.
/// The site's own photographs come to about 18 MB decoded.
Future<void> _image(String asset) {
  final done = Completer<void>();
  final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
  stream.addListener(ImageStreamListener(
    (_, _) {
      if (!done.isCompleted) done.complete();
    },
    onError: (_, _) {
      if (!done.isCompleted) done.complete();
    },
  ));
  return done.future;
}
