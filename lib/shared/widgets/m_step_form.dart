import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_fonts.dart';

/// The pieces of the phone's step-by-step forms, drawn for Add Apartment
/// (Figma) and shared with the business sign-up, which the design asks to
/// look the same: a three-step bar, white bordered cards each holding one
/// field, the mid-blue pill at the bottom, and dashed photo slots.

const mStepMid = Color(0xFF123A72);
const mStepGrey = Color(0xFF6D6D6D);
const mStepHairline = Color(0xFFE7E7E7);
const mStepInk = Color(0xFF1F1F1F);

class MStepProgressBar extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  /// Going back to a step already done, which the design draws as a link.
  final ValueChanged<int> onStepTap;

  const MStepProgressBar({
    super.key,
    required this.currentStep,
    required this.labels,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    // The frames draw the line to "Details" in mid blue from the first step
    // on; the line to "Photos" turns blue once the photographs are reached.
    final second = currentStep >= 2 ? mStepMid : mStepHairline;
    return SizedBox(
      width: 268,
      height: 47,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Connecting line
          PositionedDirectional(
            start: 40,
            top: 11,
            child: Container(
              width: 186,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [mStepMid, mStepMid, second, second],
                  stops: const [0.0, 0.52, 0.58, 1.0],
                ),
              ),
            ),
          ),

          // Step circles + labels
          for (int i = 0; i < labels.length; i++)
            PositionedDirectional(
              start: i * 106.0,
              top: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: i < currentStep ? () => onStepTap(i) : null,
                child: SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      // A white ring outside each circle, so the line stops
                      // short of it as drawn.
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: i <= currentStep
                              ? mStepMid
                              : const Color(0xFFF6F6F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: Center(
                          child: i < currentStep
                              // Completed: the design's ticked circle, which
                              // carries its own ring and so is 32 across.
                              ? OverflowBox(
                                  maxWidth: 32,
                                  maxHeight: 32,
                                  child: SvgPicture.asset(
                                    'assets/icons/m_realestate_step_done.svg',
                                    width: 32,
                                    height: 32,
                                  ),
                                )
                              // Current or future: show number
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: i <= currentStep
                                        ? Colors.white
                                        : mStepGrey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Label — centred under its circle even where it is
                      // wider than the 56 the circle's column is drawn at.
                      SizedBox(
                        height: 15,
                        child: OverflowBox(
                          maxWidth: 106,
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: i <= currentStep ? mStepMid : mStepGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Form card wrapper
// ═══════════════════════════════════════════════════

class MFormCard extends StatelessWidget {
  final String label;
  final Widget child;
  const MFormCard({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: mStepInk,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Text input row (placeholder only, no chevron)
// ═══════════════════════════════════════════════════

/// A text field with a controller behind it.
///
/// It had none, so everything typed into the form was discarded on the way to
/// the next step.
class MInputRow extends StatelessWidget {
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  /// A unit shown at the end of the line, such as m² beside the area.
  final String? suffix;

  /// For a password; [onToggleObscure] puts the eye at the end of the line.
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  const MInputRow({
    super.key,
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.suffix,
    this.obscureText = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final hint = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: mStepGrey,
    );
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              // iOS autocorrects an address like any word (signup_screen).
              autocorrect: keyboardType != TextInputType.emailAddress && onToggleObscure == null,
              enableSuggestions: keyboardType != TextInputType.emailAddress && onToggleObscure == null,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: mStepInk,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: hint,
                // The theme fills inputs grey and rounds them; these sit
                // inside the white bordered cards.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (suffix != null) Text(suffix!, style: hint),
          if (onToggleObscure != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleObscure,
              child: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: mStepGrey,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dropdown-style row (placeholder + chevron)
// ═══════════════════════════════════════════════════

/// A dropdown, rather than a line of text with an arrow drawn next to it.
///
/// The mock version took only a placeholder and could not be opened, so every
/// choice on the form — property type, rooms, floor — was unreachable.
class MDropdownRow<T> extends StatelessWidget {
  final String placeholder;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const MDropdownRow({
    super.key,
    required this.placeholder,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // A dense drop-down is still 24 tall; the design's line is 20, as tall
    // as the arrow, so the button is let overhang by two either side rather
    // than making every card four taller than drawn.
    return SizedBox(
      height: 20,
      child: OverflowBox(
        maxHeight: 24,
        child: _button(),
      ),
    );
  }

  Widget _button() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: items.any((i) => i.value == value) ? value : null,
        isExpanded: true,
        isDense: true,
        hint: Text(
          placeholder,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: mStepGrey,
          ),
        ),
        icon: SvgPicture.asset(
          'assets/icons/m_account_chevron.svg',
          width: 20,
          height: 20,
        ),
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mStepInk,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Bottom bar button
// ═══════════════════════════════════════════════════

/// The 44px mid-blue pill in the bottom bar, with the forward arrow on the
/// steps that lead on (turned round for right-to-left).
class MStepButton extends StatelessWidget {
  final String label;
  final bool arrow;
  final bool loading;
  final VoidCallback? onTap;

  const MStepButton({
    super.key,
    required this.label,
    required this.arrow,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: mStepMid,
          borderRadius: BorderRadius.circular(60),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 24 / 14,
                      color: Colors.white,
                    ),
                  ),
                  if (arrow) ...[
                    const SizedBox(width: 12),
                    Transform.flip(
                      flipX: rtl,
                      child: SvgPicture.asset(
                        'assets/icons/m_realestate_arrow_next.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Dashed border painter
// ═══════════════════════════════════════════════════

class MDashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = mStepGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    // Extract path from rounded rect and draw dashes along it
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
