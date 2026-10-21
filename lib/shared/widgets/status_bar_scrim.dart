import 'package:flutter/material.dart';

/// A white strip behind the phone's status bar, shown once the page's photo
/// has scrolled away.
///
/// The detail pages (a business, an article, an event's neighbourhood, a
/// listing, a deal) run their photo up under the status bar, with no bar of
/// their own. Scrolled, their text went on under the clock and the battery,
/// and the two were drawn over each other (found on a device, 21 Oct). The
/// strip comes in when the photo — [hero] tall from the top of the screen —
/// has gone up past the status bar, so the photo still fills it at rest.
///
/// It listens to the page's own vertical scrolling only: a row of cards
/// scrolling sideways inside the page is ignored.
class StatusBarScrim extends StatefulWidget {
  final Widget child;
  final double hero;

  const StatusBarScrim({super.key, required this.child, this.hero = 260});

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
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
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
    );
  }
}
