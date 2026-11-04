import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The clock and battery drawn white, for a dark photo or header behind them.
/// Only the status bar's own fields: the ready-made
/// `SystemUiOverlayStyle.light` would also paint Android's navigation bar
/// black.
const _iconsLight = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Android
  statusBarBrightness: Brightness.dark, // iOS: the background is dark
);

/// The clock and battery drawn dark, on the white pages — the app's default
/// (`main.dart`), and this page's once its white strip is in.
const statusBarIconsDark = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// The phone's status bar over a page whose photo runs up under it.
///
/// The detail pages (a business, an article, an event, a neighbourhood, a
/// listing, a deal) run their photo up under the status bar, with no bar of
/// their own, as the Figma frames draw them. Two things keep the clock and
/// the battery readable there:
///
/// - At rest, they are white, over a soft shade at the top of the photo
///   ([shade]). Black, as the light theme draws them, they could hardly be
///   seen on a dark photo (Harshit, 4 Nov). A page whose header is dark
///   already (home's blue, the profile's veiled photo) leaves the shade out.
/// - Scrolled, the text went on under the clock and the two were drawn over
///   each other (found on a device, 21 Oct). A white strip comes in when the
///   photo — [hero] tall from the top of the screen — has gone up past the
///   status bar, and the clock turns dark on it.
///
/// It listens to the page's own vertical scrolling only: a row of cards
/// scrolling sideways inside the page is ignored.
class StatusBarScrim extends StatefulWidget {
  final Widget child;
  final double hero;
  final bool shade;

  const StatusBarScrim({super.key, required this.child, this.hero = 260, this.shade = true});

  @override
  State<StatusBarScrim> createState() => _StatusBarScrimState();
}

class _StatusBarScrimState extends State<StatusBarScrim> {
  bool _shown = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final top = MediaQuery.paddingOf(context).top;
    final show = n.metrics.pixels > widget.hero - top;
    if (show != _shown) setState(() => _shown = show);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _shown ? statusBarIconsDark : _iconsLight,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            // The shade ends just past the status bar, so the page's round
            // buttons beneath it keep their white. No status bar (a browser),
            // no shade.
            if (widget.shade && top > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: top + 12,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _shown ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x73000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: top,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _shown ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
