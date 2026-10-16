import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../admin_language.dart';

/// The panel's look, in one place.
///
/// The client asked (6–7 Oct) for the panel to feel like the PersonaAI CRM —
/// white, airy, rounded, a clear header over each list, forms that read as
/// calm cards — in Modiin4u's colours, on every screen. Each screen drew its
/// own boxes and buttons; this is what they share now, so a change here
/// reaches all of them.
class AdminKit {
  const AdminKit._();

  static const AdminKit _k = AdminKit._();
  static AdminKit of(BuildContext context) => _k;

  // Colours: the CRM's neutrals, the brand's blue for anything that acts.
  Color get page => const Color(0xFFF8F9FB);
  Color get surface => Colors.white;
  Color get subtle => const Color(0xFFF9FAFB);
  Color get border => const Color(0xFFE5E7EB);
  /// Under the pointer: a row, a menu entry, a sidebar item.
  Color get hover => const Color(0xFFF3F4F6);
  Color get ink => const Color(0xFF111827);
  Color get inkSoft => const Color(0xFF4B5563);
  Color get muted => const Color(0xFF9CA3AF);
  Color get accent => AppColors.midBlue;
  Color get accentSoft => const Color(0xFFEAF0F8);
  Color get danger => const Color(0xFFDC2626);
  Color get success => const Color(0xFF16A34A);
  Color get warning => const Color(0xFFD97706);

  double get radius => 12;

  /// How long the panel's own movements take — a section coming in, the
  /// sidebar folding — short enough never to keep anyone waiting.
  Duration get motion => const Duration(milliseconds: 220);
  Curve get curve => Curves.easeOutCubic;

  TextStyle get title => TextStyle(fontFamily: AppFonts.rubik, fontSize: 22, fontWeight: FontWeight.w700, color: ink, height: 1.25);
  TextStyle get heading => TextStyle(fontFamily: AppFonts.rubik, fontSize: 15, fontWeight: FontWeight.w600, color: ink);
  TextStyle get body => TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: ink, height: 1.5);
  TextStyle get label => TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, fontWeight: FontWeight.w500, color: inkSoft);
  TextStyle get hint => TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: muted);

  InputDecoration input({String? hint, String? helper, Widget? prefix, Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: this.hint,
    helperText: helper,
    helperMaxLines: 3,
    helperStyle: this.hint.copyWith(fontSize: 12),
    prefixIcon: prefix,
    suffixIcon: suffix,
    isDense: true,
    filled: true,
    fillColor: surface,
    // A field under the pointer was filled with the rows' hover grey.
    hoverColor: subtle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: danger)),
  );

  /// The app's theme with the panel's fields, switches and choices — for the
  /// screens' own widgets that do not use the kit yet. The app's are grey
  /// pills and a black switch when off, made for the phone.
  ///
  /// Since 16 Oct it also dresses the dialogs, messages, menus, buttons,
  /// tabs and chips the 35 sections draw themselves (137 dialogs, 92
  /// messages), the way the PersonaAI CRM's are: white, a thin border, no
  /// Material ripple or pink tint, a soft grey under the pointer.
  ThemeData theme(ThemeData base) {
    OutlineInputBorder line(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: w));
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final buttonText = WidgetStatePropertyAll(
      TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w600),
    );
    final buttonSize = const WidgetStatePropertyAll(Size(0, 40));
    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(rounded);
    final menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: border),
    );
    return base.copyWith(
      // A web tool: a grey under the pointer, no ink spreading on a click.
      splashFactory: NoSplash.splashFactory,
      hoverColor: hover,
      highlightColor: Colors.transparent,
      focusColor: accentSoft,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.18),
        selectionHandleColor: accent,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: const Color(0x33000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: heading.copyWith(fontSize: 18),
        contentTextStyle: body,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: Colors.white, height: 1.4),
        actionTextColor: const Color(0xFF93C5FD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: buttonText,
          minimumSize: buttonSize,
          shape: buttonShape,
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: buttonText,
          minimumSize: buttonSize,
          shape: buttonShape,
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          textStyle: buttonText,
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: WidgetStatePropertyAll(ink),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.hovered) ? hover : surface,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: buttonText,
          minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
          shape: buttonShape,
          foregroundColor: WidgetStatePropertyAll(accent),
          overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.06)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          overlayColor: WidgetStatePropertyAll(ink.withValues(alpha: 0.05)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x26000000),
        shape: menuShape,
        textStyle: body,
        labelTextStyle: WidgetStatePropertyAll(body),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(menuShape),
          elevation: const WidgetStatePropertyAll(8),
          shadowColor: const WidgetStatePropertyAll(Color(0x26000000)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: border,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: inkSoft,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
        labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w500),
        overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.04)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accentSoft : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : inkSoft,
          ),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accentSoft,
        checkmarkColor: accent,
        side: BorderSide(color: border),
        shape: rounded,
        labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: inkSoft),
        secondaryLabelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: accent, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      listTileTheme: ListTileThemeData(
        shape: rounded,
        iconColor: inkSoft,
        selectedColor: accent,
        selectedTileColor: accentSoft,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(6),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.dragged)
              ? const Color(0x55000000)
              : const Color(0x2A000000),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : muted),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        // Material 3 tints white surfaces with the primary colour (menus and
        // dialogs came out lilac); the CRM's are plain white.
        surfaceTint: Colors.transparent,
        surface: surface,
        surfaceContainerLowest: surface,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: surface,
        surfaceContainerHighest: subtle,
        outline: border,
        outlineVariant: border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hoverColor: subtle,
        isDense: true,
        hintStyle: hint,
        labelStyle: label,
        floatingLabelStyle: label.copyWith(color: accent),
        helperStyle: hint.copyWith(fontSize: 12),
        helperMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: line(border),
        enabledBorder: line(border),
        focusedBorder: line(accent, 1.5),
        errorBorder: line(danger),
        focusedErrorBorder: line(danger, 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : const Color(0xFFE5E7EB),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// A labelled text field: the label above, the box under it.
class AdminField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final int maxLines;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  const AdminField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.maxLines = 1,
    this.textDirection,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: k.label)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: 1,
            textDirection: textDirection,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            style: k.body,
            decoration: k.input(hint: hint, helper: helper),
          ),
        ],
      ),
    );
  }
}

/// A white card with a heading, for a group of fields.
class AdminCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final bool collapsible;
  final bool initiallyOpen;

  const AdminCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(18),
    this.collapsible = false,
    this.initiallyOpen = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final header = title == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title!, style: k.heading),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: k.hint),
              ],
            ],
          );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: k.surface,
        border: Border.all(color: k.border),
        borderRadius: BorderRadius.circular(k.radius),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: collapsible && header != null
          ? Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: initiallyOpen,
                tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                childrenPadding: EdgeInsets.zero,
                title: header,
                trailing: action,
                children: [Padding(padding: padding, child: child)],
              ),
            )
          : Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null) ...[
                    Row(children: [Expanded(child: header), ?action]),
                    const SizedBox(height: 14),
                  ],
                  child,
                ],
              ),
            ),
    );
  }
}

/// A switch with its label and an optional line under it.
class AdminSwitchRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminSwitchRow({super.key, required this.label, this.description, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: k.body),
                  if (description != null) Text(description!, style: k.hint.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: k.accent,
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE5E7EB),
              inactiveThumbColor: Colors.white,
              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}

/// The primary and secondary buttons.
class AdminButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool busy;
  final bool danger;

  const AdminButton({super.key, required this.label, this.onPressed, this.icon, this.primary = true, this.busy = false, this.danger = false});

  const AdminButton.secondary({super.key, required this.label, this.onPressed, this.icon, this.busy = false, this.danger = false})
      : primary = false;

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final color = danger ? k.danger : k.accent;
    final child = busy
        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary ? Colors.white : color))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const pad = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
    return primary
        ? FilledButton(
            onPressed: busy ? null : onPressed,
            style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: shape, padding: pad, elevation: 0),
            child: child,
          )
        : OutlinedButton(
            onPressed: busy ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: danger ? k.danger : k.ink,
              side: BorderSide(color: k.border),
              backgroundColor: k.surface,
              shape: shape,
              padding: pad,
            ),
            child: child,
          );
  }
}

/// A status as a soft coloured pill.
class AdminPill extends StatelessWidget {
  final String text;
  final Color color;
  const AdminPill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(40)),
    child: Text(text, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  );
}

/// A full-page editor: a bar with the title and the actions, the main column
/// (what is written) and a side column (how it is filed and shown).
///
/// The editors were dialogs of 850 by 750 with four tabs, so writing an
/// article meant a small box and switching tabs to set its category. A page
/// shows the text large, and everything else beside it at once.
class AdminEditorPage extends StatelessWidget {
  final String title;
  final Widget? status;
  final List<Widget> actions;
  final List<Widget> main;
  final List<Widget> side;
  final VoidCallback onClose;

  const AdminEditorPage({
    super.key,
    required this.title,
    this.status,
    required this.actions,
    required this.main,
    required this.side,
    required this.onClose,
  });

  static Future<T?> open<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 180),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Theme(
      data: k.theme(Theme.of(context)),
      child: Directionality(
      textDirection: adminDir,
      child: Scaffold(
        backgroundColor: k.page,
        body: Column(
          children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: k.surface, border: Border(bottom: BorderSide(color: k.border))),
              child: Row(
                children: [
                  IconButton(
                    tooltip: tr('סגירה', 'Close'),
                    onPressed: onClose,
                    icon: Icon(adminDir == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back, color: k.inkSoft),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(title, style: k.heading.copyWith(fontSize: 17), overflow: TextOverflow.ellipsis),
                  ),
                  if (status != null) ...[const SizedBox(width: 12), status!],
                  // Takes the room left, so the actions sit at the far end.
                  const Expanded(child: SizedBox()),
                  for (final a in actions) Padding(padding: const EdgeInsetsDirectional.only(start: 10), child: a),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth > 1080;
                  final mainCol = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: main);
                  final sideCol = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: side);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: mainCol),
                                  const SizedBox(width: 24),
                                  SizedBox(width: 340, child: sideCol),
                                ],
                              )
                            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [mainCol, sideCol]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A filter for a list, as a bordered chip; filled with the accent's tint
/// when chosen. Each screen drew its own, in four shapes and two blues.
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  const AdminFilterChip(this.label, this.selected, this.onTap, {super.key, this.count});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? k.accentSoft : k.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? k.accent.withValues(alpha: 0.35) : k.border),
          ),
          child: Text(
            count == null ? label : '$label · $count',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? k.accent : k.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// The search box at the start of a list's toolbar.
class AdminSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final double width;

  const AdminSearchField({super.key, required this.hint, required this.onChanged, this.controller, this.width = 300});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: k.body.copyWith(height: 1.2),
        decoration: k.input(
          hint: hint,
          prefix: Icon(Icons.search, size: 18, color: k.muted),
        ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
      ),
    );
  }
}

/// The bar over a list: search, filters, the count and the main action —
/// the same on every screen, white with a line under it.
class AdminListToolbar extends StatelessWidget {
  final Widget? search;
  final List<Widget> filters;
  final String? count;
  final List<Widget> actions;

  const AdminListToolbar({super.key, this.search, this.filters = const [], this.count, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(color: k.surface, border: Border(bottom: BorderSide(color: k.border))),
      child: Row(
        children: [
          if (search != null) ...[search!, const SizedBox(width: 12)],
          // Many filters scroll rather than push the actions off the bar.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: filters),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 12),
            Text(count!, style: k.hint),
          ],
          for (final a in actions) Padding(padding: const EdgeInsetsDirectional.only(start: 12), child: a),
        ],
      ),
    );
  }
}

/// The small button a list's toolbar ends with ("New event"): the kit's
/// primary button, at the bar's height.
class AdminToolbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  const AdminToolbarButton({super.key, required this.label, required this.onPressed, this.icon = Icons.add, this.primary = true});

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final text = Text(label, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w600));
    return SizedBox(
      height: 40,
      child: primary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: text,
              style: FilledButton.styleFrom(backgroundColor: k.accent, foregroundColor: Colors.white, shape: shape, elevation: 0),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: text,
              style: OutlinedButton.styleFrom(foregroundColor: k.ink, side: BorderSide(color: k.border), backgroundColor: k.surface, shape: shape),
            ),
    );
  }
}

