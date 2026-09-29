import 'package:flutter/material.dart';

/// The field the design sets its page heroes in — Restaurants, Events, Real
/// Estate: white, a faint grid of small crosses joined by dotted lines, and a
/// pale blue rising from the bottom.
///
/// The design draws the grid as one 4096 × 1505 image. That is 14 KB on the
/// wire but 24 MB once decoded, and the page waited on it. The grid repeats
/// exactly every seven cells (199 px), so it is drawn from that one tile
/// instead — 5 KB, next to nothing to decode — at the scale the design shows
/// it, and at the design's strength: the layer is 40%, the grid within it 50%.
class WebDottedBand extends StatelessWidget {
  const WebDottedBand({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              // 0x33 (20%) at the bottom, under the layer's 40%.
              colors: [Color(0x14BFE7F6), Color(0x00C4C4C4)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/web/common/dots_tile.png'),
              repeat: ImageRepeat.repeat,
              alignment: Alignment.topCenter,
              // The design fits the 4096-wide grid into a 3173-wide frame.
              scale: 4096 / 3173,
              opacity: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
