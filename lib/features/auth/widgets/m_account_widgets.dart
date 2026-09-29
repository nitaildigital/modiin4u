import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Shared pieces of the phone account screens (Profile, Settings, Help,
/// Edit Profile …), built to the mobile Figma frames: white page, a back
/// arrow with a centred title, grey upper-case section labels and white
/// bordered cards whose rows are split by hairlines.

/// Picks the English or Hebrew copy for text the translation files do not
/// carry yet, following the locale the app is running in.
String mTr(BuildContext context, String en, String he) =>
    Localizations.localeOf(context).languageCode == 'he' ? he : en;

abstract final class MAccountColors {
  static const label = Color(0xFF6D6D6D);
  static const border = Color(0xFFE7E7E7);
  static const title = Color(0xFF1F1F1F);
  static const value = Color(0xFF3D3D3D);
  static const tile = Color(0xFFE7ECF7);
  static const circle = Color(0xFFEEF3FB);
}

/// The Figma back arrow, mirrored for right-to-left text so it still points
/// the way the screen came from.
class MBackArrow extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;
  const MBackArrow({super.key, this.color = AppColors.navy, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          onTap ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
      child: SizedBox(
        width: 24,
        height: 24,
        child: Transform.flip(
          flipX: rtl,
          child: SvgPicture.asset(
            'assets/icons/m_account_back.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

/// Back arrow at the start, title centred (Inter 16 medium), 15px sides.
class MAccountTopBar extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback? onBack;
  const MAccountTopBar({
    super.key,
    required this.title,
    this.color = Colors.black,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Row(
        children: [
          MBackArrow(
            color: color == Colors.black ? const Color(0xFF3D3D3D) : color,
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

/// Grey upper-case label above a card (Inter 12 semibold, #6D6D6D).
class MSectionLabel extends StatelessWidget {
  final String text;
  const MSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppFonts.inter,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: MAccountColors.label,
      ),
    );
  }
}

/// White card, 1px #E7E7E7 border, radius 8, 12px side padding; rows are
/// separated by a bottom hairline except the last.
class MCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const MCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: MAccountColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == children.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: MAccountColors.border),
                      ),
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

/// A section: label, 12px gap (8 on Profile), card.
class MSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  final double gap;
  const MSection({
    super.key,
    required this.label,
    required this.children,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MSectionLabel(label),
        SizedBox(height: gap),
        MCard(children: children),
      ],
    );
  }
}

/// 36px square tile (#E7ECF7, radius 9) holding a 20px mid-blue icon —
/// either a Figma SVG from `assets/icons/` or an [IconData].
class MIconTile extends StatelessWidget {
  final String? svg;
  final IconData? icon;
  const MIconTile({super.key, this.svg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: MAccountColors.tile,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: svg != null
          ? SvgPicture.asset(svg!, width: 20, height: 20)
          : Icon(icon, size: 20, color: AppColors.midBlue),
    );
  }
}

/// 36px round badge (#EEF3FB) used by the Settings rows. The Figma SVGs
/// already carry the circle; an [IconData] gets one drawn around it.
class MIconCircle extends StatelessWidget {
  final String? svg;
  final IconData? icon;
  const MIconCircle({super.key, this.svg, this.icon});

  @override
  Widget build(BuildContext context) {
    if (svg != null) return SvgPicture.asset(svg!, width: 36, height: 36);
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: MAccountColors.circle,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: AppColors.midBlue),
    );
  }
}

/// Profile row: icon tile, grey label over the value.
class MInfoRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  const MInfoRow({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: MAccountColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: MAccountColors.value,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 20px grey chevron, pointing toward the end of the line.
class MChevron extends StatelessWidget {
  const MChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RotatedBox(
      quarterTurns: rtl ? 1 : 3,
      child: SvgPicture.asset(
        'assets/icons/m_account_chevron.svg',
        width: 20,
        height: 20,
      ),
    );
  }
}

/// Settings row: badge, bold title over a grey subtitle, then an optional
/// value (mid blue), a chevron or any trailing widget such as a switch.
class MSettingsRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;
  final Color? titleColor;
  const MSettingsRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? MAccountColors.title,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: MAccountColors.label,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 4),
            Text(
              value!,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.midBlue,
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          if (trailing == null && showChevron) ...[
            const SizedBox(width: 4),
            const MChevron(),
          ],
        ],
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: onTap == null
          ? row
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? onTap : null,
              child: row,
            ),
    );
  }
}

/// The 44×24 pill switch from the design: mid blue when on, grey when off.
class MSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const MSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? AppColors.midBlue : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width mid-blue pill button (Inter 16 medium, 12px vertical padding).
class MPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? svgIcon;
  final bool loading;
  const MPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.svgIcon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.midBlue.withValues(alpha: 0.5)
              : AppColors.midBlue,
          borderRadius: BorderRadius.circular(60),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (svgIcon != null) ...[
                    SvgPicture.asset(svgIcon!, width: 20, height: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
