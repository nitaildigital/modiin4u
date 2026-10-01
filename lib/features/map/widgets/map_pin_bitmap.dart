import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Draws the pin as an image, because Google Maps takes bitmaps for markers
/// rather than widgets.
///
/// The pin is the Figma frame's own — the white teardrop with a coloured
/// disc and a white glyph — read from the SVG the website's map already
/// draws, so the two maps show one pin. It used to be a round white disc
/// with an icon-font glyph, which the design never had and which had no
/// glyph for a car park.
abstract final class MapPinBitmap {
  /// Built pins, keyed by asset and whether they are selected. Drawing one
  /// costs a canvas and an image encode, and the map rebuilds often, so each
  /// distinct pin is drawn once and kept.
  static final Map<String, BitmapDescriptor> _cache = {};

  /// The SVGs' own size.
  static const _width = 40.0;
  static const _height = 42.9027;

  /// A selected pin is drawn larger; the frame shows no selected state, and
  /// the card that opens is what says which pin it belongs to.
  static const _selectedScale = 1.25;

  /// Where the teardrop's point sits, as a fraction of the image, so the
  /// point rather than the centre lands on the place.
  static const anchor = Offset(0.5, 38.33 / _height);

  static Future<BitmapDescriptor> ofAsset({
    required String asset,
    required bool isSelected,
    required double devicePixelRatio,
  }) async {
    final key = '$asset|$isSelected|${devicePixelRatio.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final built = await _draw(
      asset: asset,
      scale: devicePixelRatio * (isSelected ? _selectedScale : 1),
      logicalScale: isSelected ? _selectedScale : 1,
    );
    _cache[key] = built;
    return built;
  }

  static Future<BitmapDescriptor> _draw({
    required String asset,
    required double scale,
    required double logicalScale,
  }) async {
    final svg = await vg.loadPicture(SvgAssetLoader(asset), null);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    // The design's drop shadow — y 2.29, blur 1.14, black at 25% — which
    // flutter_svg does not draw, since it ignores SVG filters. The pin is
    // painted once more underneath, blackened and blurred.
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0x40000000),
          BlendMode.srcIn,
        )
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 1.14, sigmaY: 1.14),
    );
    canvas.translate(0, 2.29);
    canvas.drawPicture(svg.picture);
    canvas.restore();

    canvas.drawPicture(svg.picture);
    svg.picture.dispose();

    final image = await recorder.endRecording().toImage(
      (_width * scale).ceil(),
      (_height * scale).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: _width * logicalScale,
      height: _height * logicalScale,
    );
  }

  /// The phone restaurants map's pin: a white disc with a coloured centre
  /// and a white glyph, ringed in navy when chosen (Figma's mobile frame).
  /// Anchored at its middle, as it sits centred on the place.
  static Future<BitmapDescriptor> ofCircle({
    required Color color,
    required IconData icon,
    required bool isSelected,
    required double devicePixelRatio,
  }) async {
    final key =
        'circle|${color.toARGB32()}|${icon.codePoint}|$isSelected|'
        '${devicePixelRatio.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    const size = 40.0;
    final scale = devicePixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    const centre = Offset(size / 2, size / 2 - 2);

    // Shadow — y 2.28, blur 2.28 — then the white disc, the ring, the
    // coloured centre and the glyph.
    canvas.drawCircle(
      centre.translate(0, 2.28),
      17,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.28),
    );
    canvas.drawCircle(centre, 17, Paint()..color = Colors.white);
    if (isSelected) {
      canvas.drawCircle(
        centre,
        16,
        Paint()
          ..color = const Color(0xFF123A72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(centre, 11, Paint()..color = color);
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, centre - Offset(glyph.width / 2, glyph.height / 2));

    final image = await recorder.endRecording().toImage(
      (size * scale).ceil(),
      (size * scale).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final built = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: size,
      height: size,
    );
    _cache[key] = built;
    return built;
  }
}
