import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../screens/my_apartments_screen.dart' show formatShekels;

/// A listing card's price as the phone design sets it: the amount in the
/// rounded face, and for a rental the "per month" part smaller and grey
/// beside it ("₪7,500 / month").
///
/// The suffix is taken from the same localised string the rest of the app
/// uses, so both languages keep their own wording.
class MPriceText extends StatelessWidget {
  final int amount;
  final ListingKind kind;
  final double size;
  final Color color;

  const MPriceText({
    super.key,
    required this.amount,
    required this.kind,
    this.size = 20,
    this.color = const Color(0xFF0A1230),
  });

  @override
  Widget build(BuildContext context) {
    final price = formatShekels(amount);
    final suffix = kind == ListingKind.rent
        ? L.of(context).pricePerMonthValue(price).replaceFirst(price, '').trim()
        : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          price,
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (suffix.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            suffix,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5F5E5A),
            ),
          ),
        ],
      ],
    );
  }
}
