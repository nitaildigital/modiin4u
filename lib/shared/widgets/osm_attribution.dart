import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The credit OpenStreetMap's tile policy requires, on every map that draws
/// its tiles.
///
/// Fourteen screens pull from `tile.openstreetmap.org` and not one of them
/// said where the map came from. The policy is not vague about it — the
/// attribution must be visible, and must not be hidden behind a toggle or
/// pushed off-screen — and the consequence is not vague either: "access may
/// be blocked without prior notice". Being blocked would empty every map in
/// the app at once, on the phone and on the web, with nothing in the code to
/// explain it.
///
/// `RichAttributionWidget` shows a small "i" that opens the credit, which
/// reads as hidden. This is the plain one: always on screen, bottom corner,
/// legible against the map.
///
/// It is one widget rather than fourteen copies so that the day the client
/// moves to a paid tile provider — which he should before any real traffic,
/// since the policy offers no SLA — the credit changes in one place.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              // The map underneath can be any colour, so the credit carries
              // its own background rather than hoping for contrast.
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Color(0xFF3A3A3A)),
            ),
          ),
        ),
      ),
    );
  }
}
