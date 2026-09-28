import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
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

  // What the home page shows before anyone scrolls: the navbar's logo and
  // chevron, the hero's line art, search and pills, and the seven category
  // icons — about twenty files, 70 KB. Everything else waits until these are
  // in: asking for all 111 at once had them queue behind one another, and on
  // a slow line the first screen came up three seconds later for it.
  const home = 'assets/web/home/';
  const firstCards = {'news', 'events', 'community', 'professionals', 'maps', 'businesses', 'realestate'};
  bool firstScreen(String a) =>
      a == 'assets/images/logo_white.svg' ||
      a == 'assets/icons/chevron_down.svg' ||
      a.startsWith('${home}hero_') ||
      a.startsWith('${home}pill_') ||
      a == '${home}search.svg' ||
      a == '${home}ai.svg' ||
      firstCards.any((c) => a == '${home}card_$c.svg');

  final now = assets.where(firstScreen);
  final later = assets.where((a) => !firstScreen(a));

  await Future.wait(now.map(_load));
  unawaited(Future.wait(later.map(_load)));
}

Future<void> _load(String asset) {
  if (asset.endsWith('.svg')) {
    return SvgAssetLoader(asset).loadBytes(null).then((_) {}, onError: (_) {});
  }
  if (asset.endsWith('.png') || asset.endsWith('.jpg') || asset.endsWith('.jpeg')) {
    return _image(asset);
  }
  return Future.value();
}

/// Resolves an asset image into the image cache and waits for it to decode.
Future<void> _image(String asset) {
  final done = Completer<void>();
  final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    if (!done.isCompleted) done.complete();
    stream.removeListener(listener);
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return done.future;
}
