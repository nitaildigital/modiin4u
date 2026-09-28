import 'package:flutter/material.dart';

/// The field the design sets its page heroes in — Restaurants, Events, Real
/// Estate: white, with a faint grid of dots and a pale blue rising from the
/// bottom, the whole layer at 40%.
///
/// The dots are the design's own image, 3173 × 836 and centred, so they sit
/// where they sit in the frame whatever the width of the window.
class WebDottedBand extends StatelessWidget {
  const WebDottedBand({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Opacity(
        opacity: 0.4,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 3173,
          maxWidth: 3173,
          minHeight: 836,
          maxHeight: 836,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x33BFE7F6), Color(0x00C4C4C4)],
                  ),
                ),
              ),
              Opacity(
                opacity: 0.5,
                child: Image.asset('assets/web/common/dots_mask.png', fit: BoxFit.cover),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
