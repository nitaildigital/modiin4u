import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Draws the pin as an image, because Google Maps takes bitmaps for markers
/// rather than widgets.
///
/// This is the same shape the map drew before — a white disc with a coloured
/// inner circle and a glyph — so nothing about the design changes with the
/// map underneath it.
abstract final class MapPinBitmap {
  /// Built pins, keyed by colour, glyph and whether they are selected. Drawing
  /// one costs a canvas and an image encode, and the map rebuilds often, so
  /// each distinct pin is drawn once and kept.
  static final Map<String, BitmapDescriptor> _cache = {};

  static const _size = 40.0;
  static const _innerSize = 22.0;
  static const _glyphSize = 13.0;

  static Future<BitmapDescriptor> of({
    required Color color,
    required IconData icon,
    required bool isSelected,
    required double devicePixelRatio,
  }) async {
    final key = '${color.toARGB32()}|${icon.codePoint}|$isSelected'
        '|${devicePixelRatio.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final built = await _draw(
      color: color,
      icon: icon,
      isSelected: isSelected,
      scale: devicePixelRatio,
    );
    _cache[key] = built;
    return built;
  }

  static Future<BitmapDescriptor> _draw({
    required Color color,
    required IconData icon,
    required bool isSelected,
    required double scale,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    const center = Offset(_size / 2, _size / 2);

    // The drop shadow the widget had, drawn first so everything sits over it.
    canvas.drawCircle(
      center.translate(0, 2.29),
      _size / 2 - 1,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          isSelected ? 6 : 2.29,
        ),
    );

    canvas.drawCircle(
      center,
      _size / 2 - 1,
      Paint()..color = Colors.white,
    );

    if (isSelected) {
      canvas.drawCircle(
        center,
        _size / 2 - 2,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.drawCircle(center, _innerSize / 2, Paint()..color = color);

    // The glyph is a character in the icon font, so it paints like text.
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: _glyphSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(
      canvas,
      center - Offset(glyph.width / 2, glyph.height / 2),
    );

    final pixels = (_size * scale).round();
    final image = await recorder.endRecording().toImage(pixels, pixels);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: _size,
      height: _size,
    );
  }
}
