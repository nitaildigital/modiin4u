import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/theme/app_fonts.dart';
import '../../features/auth/widgets/m_account_widgets.dart';
import 'm_step_form.dart';
import 'network_photo.dart';

/// The pieces Kamal's business and job screens share (`business_side/`,
/// `user_side/`, 7 Oct): a white page with a back arrow and a centred title,
/// the mid-blue pill, grey tag chips, coloured status pills, bordered cards
/// with a title and an edit or add icon, and the "posted / published" page
/// that offers to promote.

const mKitGreen = Color(0xFF1E9E4A);
const mKitGreenBg = Color(0xFFDFF5E5);
const mKitOrange = Color(0xFFE5622D);
const mKitOrangeBg = Color(0xFFFFEDE5);
const mKitBlueBg = Color(0xFFEEF4FD);
const mKitChipBg = Color(0xFFF1F1F1);
const mKitRed = Color(0xFFFF3434);

/// The display headings ("Cafe Team Member", "Choose a resume").
TextStyle mHeading(double size) => TextStyle(
  fontFamily: AppFonts.nunito,
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: const Color(0xFF0D1B3E),
  height: 1.2,
);

TextStyle mText(double size, {FontWeight weight = FontWeight.w400, Color color = mStepInk, double? height}) =>
    TextStyle(fontFamily: AppFonts.inter, fontSize: size, fontWeight: weight, color: color, height: height);

/// A page: back arrow, centred title, optional action on the end side, and
/// the body; an optional bar pinned to the bottom.
class MPage extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? action;
  final Widget? bottom;
  final VoidCallback? onBack;
  final Color background;

  const MPage({
    super.key,
    this.title,
    required this.body,
    this.action,
    this.bottom,
    this.onBack,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 6),
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (title != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 72),
                            child: Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mText(16, weight: FontWeight.w500, color: Colors.black),
                            ),
                          ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MBackArrow(color: const Color(0xFF3D3D3D), onTap: onBack),
                        ),
                        if (action != null)
                          Align(alignment: AlignmentDirectional.centerEnd, child: action!),
                      ],
                    ),
                  ),
                ),
                Expanded(child: body),
                if (bottom != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: mStepHairline)),
                    ),
                    child: bottom,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The mid-blue pill. [outlined] is the white one with a blue edge ("Maybe
/// Later"); [disabled] the grey one ("Applied").
class MButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final bool iconAfter;
  final double height;

  const MButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.iconAfter = false,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !loading;
    final fg = outlined ? mStepMid : disabled ? const Color(0xFF6D6D6D) : Colors.white;
    final iconWidget = icon == null ? null : Icon(icon, size: 18, color: fg);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : disabled ? const Color(0xFFE8E8E8) : mStepMid,
          border: outlined ? Border.all(color: mStepMid) : null,
          borderRadius: BorderRadius.circular(60),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: outlined ? mStepMid : Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconWidget != null && !iconAfter) ...[iconWidget, const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mText(15, weight: FontWeight.w500, color: fg),
                    ),
                  ),
                  if (iconWidget != null && iconAfter) ...[const SizedBox(width: 8), iconWidget],
                ],
              ),
      ),
    );
  }
}

/// The floating pill at the foot of a list ("Post a Job", "Create Deal").
class MFloatingAdd extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const MFloatingAdd({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: mStepMid,
          borderRadius: BorderRadius.circular(60),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: mText(15, weight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A grey tag ("No experience", "Shift work").
class MChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  final Color background;
  const MChip(this.label, {super.key, this.onRemove, this.background = mKitChipBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(12, 6, onRemove == null ? 12 : 8, 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: mText(12.5, color: const Color(0xFF3D3D3D))),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: Color(0xFF3D3D3D)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A coloured pill: green Active, orange Draft, grey Closed.
class MStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const MStatusPill(this.label, {super.key, required this.color, required this.background});

  factory MStatusPill.forStatus(String status, String label) => switch (status) {
    'active' || 'approved' => MStatusPill(label, color: mKitGreen, background: mKitGreenBg),
    'draft' || 'pending' => MStatusPill(label, color: mKitOrange, background: mKitOrangeBg),
    _ => MStatusPill(label, color: const Color(0xFF6D6D6D), background: mKitChipBg),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(50)),
      child: Text(label, style: mText(11.5, weight: FontWeight.w500, color: color)),
    );
  }
}

/// A bordered card with a title and an icon on the end (edit or add).
class MSectionCard extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget? child;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const MSectionCard({
    super.key,
    required this.title,
    this.hint,
    this.child,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: mText(14, weight: FontWeight.w500))),
              if (actionIcon != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(actionIcon, size: 20, color: mStepMid),
                  ),
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: mText(12, color: mStepGrey, height: 1.35)),
          ],
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

/// A thin icon and text, as on a job's meta line.
class MMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const MMeta(this.icon, this.text, {super.key, this.color = const Color(0xFF3D3D3D)});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: mStepGrey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: mText(13, color: color)),
        ),
      ],
    );
  }
}

/// A round logo or photo, with a letter when there is none.
class MAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const MAvatar({super.key, this.url, required this.name, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: (url ?? '').isEmpty
            ? Container(
                color: mKitBlueBg,
                alignment: Alignment.center,
                child: Text(
                  name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
                  style: mText(size * 0.38, weight: FontWeight.w600, color: mStepMid),
                ),
              )
            : NetworkPhoto(url: url!, icon: IconsaxPlusBold.user),
      ),
    );
  }
}

/// A centred message where a list has nothing in it.
class MEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? text;
  const MEmpty({super.key, required this.icon, required this.title, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: mKitBlueBg, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: mStepMid),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: mText(16, weight: FontWeight.w600)),
            if (text != null) ...[
              const SizedBox(height: 6),
              Text(text!, textAlign: TextAlign.center, style: mText(13, color: mStepGrey, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Job Posted Successfully!" / "Deal Published!": the green tick, the item,
/// and the offer to promote it.
class MPublishedPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String itemTitle;
  final String? itemImage;
  final String promoteTitle;
  final String promoteText;
  final String promoteLabel;
  final VoidCallback onPromote;
  final VoidCallback onLater;

  const MPublishedPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.itemTitle,
    this.itemImage,
    required this.promoteTitle,
    required this.promoteText,
    required this.promoteLabel,
    required this.onPromote,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text(title, textAlign: TextAlign.center, style: mHeading(22)),
                          const SizedBox(height: 8),
                          Text(subtitle, textAlign: TextAlign.center, style: mText(14, color: mStepGrey, height: 1.4)),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: mStepHairline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 100,
                                    height: 78,
                                    child: (itemImage ?? '').isEmpty
                                        ? Container(
                                            color: mKitBlueBg,
                                            child: const Icon(IconsaxPlusLinear.image, color: mStepMid),
                                          )
                                        : NetworkPhoto(url: itemImage!, icon: IconsaxPlusBold.image),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    itemTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: mText(17, weight: FontWeight.w600, color: mStepMid),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: mKitBlueBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(IconsaxPlusLinear.speaker, size: 22, color: mStepMid),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(promoteTitle, style: mText(14, weight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(promoteText, style: mText(12, color: mStepGrey, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  MButton(label: promoteLabel, onTap: onPromote),
                  const SizedBox(height: 12),
                  MButton(label: mTr(context, 'Maybe Later', 'אולי אחר כך'), outlined: true, onTap: onLater),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A snackbar in the app's style.
void mToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: AppFonts.inter)),
      backgroundColor: error ? const Color(0xFFE74C3C) : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// "2 days ago", "today", in the reader's language.
String mAgo(BuildContext context, DateTime when) {
  final d = DateTime.now().difference(when);
  if (d.inMinutes < 60) return mTr(context, 'Just now', 'הרגע');
  if (d.inHours < 24) {
    final h = d.inHours;
    return mTr(context, h == 1 ? '1 hour ago' : '$h hours ago', h == 1 ? 'לפני שעה' : 'לפני $h שעות');
  }
  final days = d.inDays;
  if (days == 1) return mTr(context, '1 day ago', 'אתמול');
  return mTr(context, '$days days ago', 'לפני $days ימים');
}

/// "Oct 6, 2026" / "6 באוק׳ 2026".
String mDate(BuildContext context, DateTime d) {
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const he = ['ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יוני', 'יולי', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳'];
  return mTr(context, '${en[d.month - 1]} ${d.day}, ${d.year}', '${d.day} ב${he[d.month - 1]} ${d.year}');
}
