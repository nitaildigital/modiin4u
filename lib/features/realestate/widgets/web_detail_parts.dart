import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../models/listing.dart';
import '../screens/my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Pieces the two web detail pages share — the listing page (Figma
// "Appartments", 123:2271) and the neighbourhood page ("Neighborhood",
// 233:1292). Both draw the same photo mosaic, the same carousel arrows and
// the same apartment and business cards, at two sizes.
// ═══════════════════════════════════════════════════════════

const kDetailAsset = 'assets/web/realestate';
const kDetailLine = Color(0xFFE7E7E7);
const kDetailGrey = Color(0xFF5F5E5A);
const kDetailBody = Color(0xFF3D3D3D);
const kDetailMuted = Color(0xFF6D6D6D);

/// The design's headings are Avenir Next Rounded Pro Demi, drawn here in
/// Nunito. Nunito's own line box is taller than Avenir's, so the height is
/// pinned to the design's (a 24px heading sits in a 30px box) or every
/// section below would drift down a few pixels at a time.
TextStyle detailDisplay(
  double size, {
  Color color = AppColors.midBlue,
  double height = 1.25,
}) => TextStyle(
  fontFamily: AppFonts.nunito,
  fontSize: size,
  fontWeight: FontWeight.w600,
  color: color,
  height: height,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Inter at the design's line height, 1.21 of the size — Inter's own.
///
/// It is pinned rather than left to the font because a line that reaches
/// for a fallback font takes that font's taller line box: the ₪ in a price,
/// or a Hebrew street name, pushed each line a few pixels past the design.
TextStyle detailInter(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double height = 1.21,
}) => TextStyle(
  fontFamily: AppFonts.inter,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  leadingDistribution: TextLeadingDistribution.even,
);

final _hebrew = RegExp(r'[֐-׿]');

/// Text from the database reads in its own direction whatever the page does:
/// a Hebrew street name on the English page, an English agency on the Hebrew.
TextDirection detailDirOf(String s) =>
    _hebrew.hasMatch(s) ? TextDirection.rtl : TextDirection.ltr;

/// A line of database text, in its own direction, lined up with the page.
class DetailText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;
  const DetailText(this.text, {super.key, required this.style, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final pageIsRtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textDirection: detailDirOf(text),
      textAlign: pageIsRtl ? TextAlign.right : TextAlign.left,
    );
  }
}

/// A description as the client wrote it, one entry per paragraph.
List<String> detailParagraphs(String? text) => (text ?? '')
    .split(RegExp(r'\n\s*\n'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .toList();

/// Half rooms are normal here, so 3.5 must not print as 3.
String detailRooms(double rooms) =>
    rooms == rooms.roundToDouble() ? '${rooms.toInt()}' : '$rooms';

/// The page's content column at a fixed width, centred, with the site's
/// gutter either side when the window is narrower than the design.
///
/// [bleed] widens the box by that much on each side, for content that hangs
/// past the column's edge — the carousel arrows sit half outside the row of
/// cards, and a pointer is only delivered inside a widget's own box, so the
/// box has to reach them or their outer halves would not take a click. The
/// child then pads itself back in by [bleed].
class DetailColumn extends StatelessWidget {
  final double maxWidth;
  final double bleed;
  final Widget child;
  const DetailColumn({super.key, required this.maxWidth, this.bleed = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final gutter = webGutter(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: (gutter - bleed).clamp(0.0, gutter)),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth + 2 * bleed),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// A heading over a carousel, laid out in a [DetailColumn] with room for
/// the carousel's arrows either side.
class DetailStrip extends StatelessWidget {
  final double maxWidth;
  final String title;
  final double titleGap;
  final DetailCarousel carousel;
  const DetailStrip({
    super.key,
    required this.maxWidth,
    required this.title,
    required this.titleGap,
    required this.carousel,
  });

  @override
  Widget build(BuildContext context) {
    return DetailColumn(
      maxWidth: maxWidth,
      bleed: DetailCarousel.bleed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DetailCarousel.bleed),
            child: DetailHeading(title),
          ),
          SizedBox(height: titleGap),
          carousel,
        ],
      ),
    );
  }
}

/// The 16px location pin the design puts before every address.
class DetailPin extends StatelessWidget {
  const DetailPin({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 16,
    height: 16,
    child: Center(
      child: SvgPicture.asset('$kDetailAsset/detail_pin.svg', width: 12, height: 16),
    ),
  );
}

/// "Pin + text", as the title blocks and the cards draw an address.
class DetailPlace extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double gap;
  const DetailPlace(this.text, {super.key, required this.style, this.gap = 8});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const DetailPin(),
      SizedBox(width: gap),
      Flexible(child: DetailText(text, style: style)),
    ],
  );
}

// ─────────────────────────────────────────────
// PHOTO MOSAIC
// ─────────────────────────────────────────────

/// The photo block at the top of both pages.
///
/// The listing draws one large panel and, beside it, a wide one over two
/// small ones (four photos). The neighbourhood draws one large panel and two
/// stacked beside it (three). With fewer photos on file the block draws what
/// there is — two side by side, or one across — rather than grey stand-ins,
/// and with none it draws the brand panel once.
class DetailPhotoMosaic extends StatelessWidget {
  final List<String> photos;
  final double height;
  final double radius;

  /// Gap between the two columns, and between rows.
  final double gap;

  /// Four panels (the listing) or three (the neighbourhood).
  final bool fourUp;
  final double buttonInset;
  final String showAllLabel;
  final IconData fallbackIcon;

  const DetailPhotoMosaic({
    super.key,
    required this.photos,
    required this.height,
    required this.radius,
    required this.gap,
    required this.fourUp,
    required this.buttonInset,
    required this.showAllLabel,
    required this.fallbackIcon,
  });

  void _open(BuildContext context, int index) {
    if (photos.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => DetailPhotoViewer(photos: photos, initial: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget panel(int i, {double iconSize = 32}) {
      final photo = NetworkPhoto(
        url: i < photos.length ? photos[i] : null,
        icon: fallbackIcon,
        iconSize: iconSize,
      );
      if (i >= photos.length) return photo;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: () => _open(context, i), child: photo),
      );
    }

    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          Expanded(child: children[i]),
        ],
      ],
    );

    Widget row(List<Widget> children) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );

    final n = photos.length;
    final Widget grid;
    if (n <= 1) {
      grid = panel(0, iconSize: 80);
    } else if (n == 2) {
      grid = row([panel(0), panel(1)]);
    } else if (n == 3 || !fourUp) {
      grid = row([panel(0), column([panel(1), panel(2)])]);
    } else {
      grid = row([
        panel(0),
        column([panel(1), row([panel(2), panel(3)])]),
      ]);
    }

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            grid,
            // Opens the photos at full size, all of them — the mosaic only
            // ever shows the first three or four.
            if (n > 1)
              PositionedDirectional(
                end: buttonInset,
                bottom: buttonInset,
                child: DetailPillButton(
                  label: showAllLabel,
                  onTap: () => _open(context, 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The white "Show all photos" pill that sits on a photograph.
class DetailPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const DetailPillButton({super.key, required this.label, required this.onTap});

  @override
  State<DetailPillButton> createState() => _DetailPillButtonState();
}

class _DetailPillButtonState extends State<DetailPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _hovered ? 1 : 0.9),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Text(
            widget.label,
            style: detailInter(14, weight: FontWeight.w500, color: AppColors.navy, height: 24 / 14),
          ),
        ),
      ),
    );
  }
}

/// Every photograph, one at a time, over a dark page.
class DetailPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initial;
  const DetailPhotoViewer({super.key, required this.photos, required this.initial});

  @override
  State<DetailPhotoViewer> createState() => _DetailPhotoViewerState();
}

class _DetailPhotoViewerState extends State<DetailPhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.photos.length - 1);
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    // Photographs page left to right in either language; only the chrome
    // around them would flip, and there is none worth flipping.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 64),
              child: Image.network(widget.photos[i], fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ),
          if (_index > 0)
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _go(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 48),
                ),
              ),
            ),
          if (_index < widget.photos.length - 1)
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _go(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 48),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_index + 1} / ${widget.photos.length}',
                style: detailInter(14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CAROUSEL
// ─────────────────────────────────────────────

/// A row of cards that pages sideways, with the design's round arrows
/// straddling its two edges.
///
/// The cards are sized so [perView] of them fill the column exactly, as the
/// design draws four across; on a narrower window they narrow rather than
/// being cut off at the edge. The arrows only appear when there is more than
/// one view's worth to page through.
///
/// It expects to be laid out [bleed] wider than the row on each side (see
/// [DetailStrip]), which is where the arrows hang.
class DetailCarousel extends StatefulWidget {
  static const double bleed = 20;

  final int itemCount;
  final double height;
  final double gap;

  /// Cards across; a function of the row's width, so a page can show fewer
  /// on a narrow window.
  final int Function(double rowWidth) perView;
  final double arrowTop;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const DetailCarousel({
    super.key,
    required this.itemCount,
    required this.height,
    required this.gap,
    required this.perView,
    required this.arrowTop,
    required this.itemBuilder,
  });

  @override
  State<DetailCarousel> createState() => _DetailCarouselState();
}

class _DetailCarouselState extends State<DetailCarousel> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _page(int direction, double step) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + direction * step)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const bleed = DetailCarousel.bleed;
        final width = constraints.maxWidth - 2 * bleed;
        final perView = widget.perView(width);
        final itemWidth = (width - widget.gap * (perView - 1)) / perView;
        final step = (itemWidth + widget.gap) * perView;
        final paged = widget.itemCount > perView;

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PositionedDirectional(
                start: bleed,
                end: bleed,
                top: 0,
                bottom: 0,
                child: ListView.separated(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: widget.itemCount,
                  separatorBuilder: (_, _) => SizedBox(width: widget.gap),
                  itemBuilder: (context, i) =>
                      SizedBox(width: itemWidth, child: widget.itemBuilder(context, i)),
                ),
              ),
              // Centred on the row's two edges, as the design draws them.
              if (paged) ...[
                PositionedDirectional(
                  start: bleed - 20,
                  top: widget.arrowTop,
                  child: DetailArrowButton(forward: false, onTap: () => _page(-1, step)),
                ),
                PositionedDirectional(
                  end: bleed - 20,
                  top: widget.arrowTop,
                  child: DetailArrowButton(forward: true, onTap: () => _page(1, step)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The design's 40px round arrow: white, a hairline border, a soft shadow.
///
/// [forward] is the way the row moves rather than the way the glyph points —
/// in Hebrew the row reads from the right, so "forward" points left.
class DetailArrowButton extends StatefulWidget {
  final bool forward;
  final VoidCallback onTap;
  const DetailArrowButton({super.key, required this.forward, required this.onTap});

  @override
  State<DetailArrowButton> createState() => _DetailArrowButtonState();
}

class _DetailArrowButtonState extends State<DetailArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final pointsLeft = widget.forward == rtl;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8F8F8) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Transform.flip(
            flipX: pointsLeft,
            child: SvgPicture.asset('$kDetailAsset/detail_arrow.svg', width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}

/// A section heading, the way both pages set "Highlights", "Properties in
/// Moriah" and the rest.
class DetailHeading extends StatelessWidget {
  final String text;
  const DetailHeading(this.text, {super.key});

  /// Set in the page's direction, not the name's: "Businesses in מרכז העיר"
  /// is an English sentence with a Hebrew name in it, and read as Hebrew it
  /// comes out back to front.
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: detailDisplay(24),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}

// ─────────────────────────────────────────────
// APARTMENT CARD
// ─────────────────────────────────────────────

/// An apartment, as the two pages draw it.
///
/// The listing page's "Properties in …" strip draws the small card (288 by
/// 261): a 150px photo, then price, figures and place. The neighbourhood
/// page draws the large one (382 by 321): a 200px photo carrying the "New"
/// and "Via Broker" badges, then price, address and figures.
///
/// The heart in the photo's corner is not drawn: saving needs an account,
/// and accounts are the app's.
class DetailListingCard extends StatefulWidget {
  final Listing listing;
  final bool isHebrew;
  final bool large;
  const DetailListingCard({
    super.key,
    required this.listing,
    required this.isHebrew,
    this.large = false,
  });

  @override
  State<DetailListingCard> createState() => _DetailListingCardState();
}

class _DetailListingCardState extends State<DetailListingCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final large = widget.large;
    final isRent = l.kind == ListingKind.rent;
    final price = l.effectivePrice;
    final place = l.address ?? l.neighborhoodName;

    // A listing with no price is not a free one, so the line says so rather
    // than printing ₪0.
    final priceRow = Row(
      children: [
        Expanded(
          child: price == null
              ? Text(
                  _t('Price on request', 'מחיר לפי בקשה'),
                  style: detailInter(14, color: kDetailGrey),
                  overflow: TextOverflow.ellipsis,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatShekels(price),
                      style: detailDisplay(20, color: AppColors.navy),
                      textDirection: TextDirection.ltr,
                    ),
                    if (isRent) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _t('/ In the month', '/ לחודש'),
                          style: detailInter(14, color: kDetailGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(width: 8),
        Text(
          isRent ? _t('FOR RENT', 'להשכרה') : _t('FOR SALE', 'למכירה'),
          style: detailInter(12, weight: FontWeight.w500, color: AppColors.turquoise),
        ),
      ],
    );

    final stats = <Widget>[
      if (l.sqm != null) _stat('detail_card_area.svg', _t('${l.sqm} m²', '${l.sqm} מ״ר')),
      if (l.rooms != null)
        _stat('detail_card_rooms.svg', _t('${detailRooms(l.rooms!)} Rooms', '${detailRooms(l.rooms!)} חדרים')),
      if (l.floor != null) _stat('detail_card_floor.svg', _t('Floor ${l.floor}', 'קומה ${l.floor}')),
    ];
    final statsRow = Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 31),
          stats[i],
        ],
      ],
    );

    final placeRow = place == null
        ? const SizedBox(height: 17)
        : DetailPlace(place, style: detailInter(14, color: kDetailGrey), gap: large ? 8 : 6);

    final photo = SizedBox(
      height: large ? 200 : 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(url: l.coverUrl, icon: IconsaxPlusBold.home_2, iconSize: 40),
          if (large && l.isNew)
            PositionedDirectional(
              top: 15,
              end: 14,
              child: _Badge(
                label: _t('New', 'חדש'),
                background: AppColors.turquoise,
                color: Colors.white,
                horizontal: 8,
              ),
            ),
          if (large && l.isBroker)
            PositionedDirectional(
              top: 161,
              start: 12,
              child: _Badge(
                label: _t('Via Broker', 'דרך מתווך'),
                background: const Color(0xFFCCD6EE),
                color: const Color(0xFF0033AC),
                horizontal: 16,
              ),
            ),
        ],
      ),
    );

    final body = Padding(
      padding: EdgeInsets.all(large ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: large
            ? [priceRow, const SizedBox(height: 16), placeRow, const SizedBox(height: 16), statsRow]
            : [priceRow, const SizedBox(height: 14), statsRow, const SizedBox(height: 14), placeRow],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/listing/${l.id}'),
        child: _CardFrame(
          hovered: _hovered,
          borderTakesSpace: !large,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [photo, body],
          ),
        ),
      ),
    );
  }

  Widget _stat(String asset, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset('$kDetailAsset/$asset', width: 14, height: 14),
      const SizedBox(width: 8),
      Text(text, style: detailInter(12, color: kDetailBody)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;
  final double horizontal;
  const _Badge({
    required this.label,
    required this.background,
    required this.color,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 6),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(50)),
    child: Text(label, style: detailInter(12, weight: FontWeight.w500, color: color)),
  );
}

/// The white card with the grey hairline and 12px corners.
///
/// The small cards in the design lay their contents inside the border (a
/// 286px photo in a 288px card); the large ones lay them under it (a 382px
/// photo in a 382px card). [borderTakesSpace] picks which.
class _CardFrame extends StatelessWidget {
  final bool hovered;
  final bool borderTakesSpace;
  final Widget child;
  const _CardFrame({required this.hovered, required this.borderTakesSpace, required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final border = BoxDecoration(
      border: Border.all(color: hovered ? const Color(0xFFCFCFCF) : kDetailLine),
      borderRadius: radius,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.all(borderTakesSpace ? 1 : 0),
      foregroundDecoration: border,
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// BUSINESS CARD
// ─────────────────────────────────────────────

/// A business filed under the neighbourhood.
///
/// The listing page draws the small card (288 by 248): photo, name, what it
/// is, where. The neighbourhood page draws the large one (301 by 348), which
/// adds the round café or restaurant badge on the photo's edge and the star
/// rating.
///
/// Left out of the large card: the heart (accounts are the app's), and the
/// "187 Views" beside the rating — `businesses` keeps no view count. The
/// rating line is only drawn once someone has reviewed the place; a rating of
/// nought out of nought would read as a bad score rather than no score.
class DetailBusinessCard extends ConsumerStatefulWidget {
  final Business business;
  final bool isHebrew;
  final bool large;
  const DetailBusinessCard({
    super.key,
    required this.business,
    required this.isHebrew,
    this.large = false,
  });

  @override
  ConsumerState<DetailBusinessCard> createState() => _DetailBusinessCardState();
}

class _DetailBusinessCardState extends ConsumerState<DetailBusinessCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final large = widget.large;
    final kind = ref.watch(businessPrimaryCategoryProvider).valueOrNull?[b.id];
    // What the place is: its category, as the design prints "Restaurant"
    // and "Coffee Shop". A business not yet filed under one falls back to
    // its own one-line description.
    final subtitle = kind?.category.name ?? (b.description ?? '').trim();
    final address = b.address.isNotEmpty ? b.address : b.neighborhood;
    final badge = switch (kind?.rootSlug) {
      'cafe-bakery' => ('detail_badge_ring_blue.svg', 'detail_badge_cafe.svg'),
      'restaurants' => ('detail_badge_ring_green.svg', 'detail_badge_restaurant.svg'),
      _ => null,
    };

    final photo = SizedBox(
      height: large ? 200 : 150,
      width: double.infinity,
      child: NetworkPhoto(url: b.imageUrl ?? b.logoUrl, icon: IconsaxPlusLinear.shop, iconSize: 36),
    );

    final body = Padding(
      padding: EdgeInsets.all(large ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailText(b.name, style: detailDisplay(large ? 20 : 18, color: AppColors.navy, height: large ? 1.25 : 22 / 18)),
          SizedBox(height: large ? 8 : 4),
          if (subtitle.isNotEmpty)
            DetailText(subtitle, style: detailInter(14, color: kDetailGrey))
          else
            const SizedBox(height: 17),
          SizedBox(height: large ? 16 : 12),
          if (address.isNotEmpty)
            DetailPlace(address, style: detailInter(14, color: kDetailGrey), gap: large ? 8 : 6),
          if (large && b.reviewCount > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SvgPicture.asset('$kDetailAsset/detail_star.svg', width: 16, height: 16),
                const SizedBox(width: 8),
                Text(b.rating.toStringAsFixed(1), style: detailInter(14, weight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('(${b.reviewCount})', style: detailInter(14, color: kDetailMuted)),
              ],
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/business/${b.id}'),
        child: _CardFrame(
          hovered: _hovered,
          borderTakesSpace: !large,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [photo, body],
              ),
              // Half over the photograph's bottom edge, as the design sets
              // it: 40 across, 16px in from the end.
              if (large && badge != null)
                PositionedDirectional(
                  top: 178,
                  end: 14,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset('$kDetailAsset/${badge.$1}', width: 44, height: 44),
                        SvgPicture.asset('$kDetailAsset/${badge.$2}', width: 20, height: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
