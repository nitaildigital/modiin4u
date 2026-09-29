import 'package:flutter/widgets.dart';

abstract final class AppIcons {
  /// Iconsax's back arrow, marked to mirror in right-to-left text.
  ///
  /// `IconsaxPlusLinear.arrow_left` is not marked, so in Hebrew it kept
  /// pointing left — forward, for a reader going right to left. An `Icon`
  /// flips a glyph marked like this one on its own, which also covers the
  /// buttons that take an `IconData` rather than a widget. Same glyph, same
  /// font; it has to stay a literal so the web build can still tree-shake
  /// the icon font.
  static const IconData back = IconData(
    0xe92f,
    fontFamily: 'IconsaxPlusLinear',
    fontPackage: 'iconsax_plus',
    matchTextDirection: true,
  );
}
