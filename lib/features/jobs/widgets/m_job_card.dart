import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/job.dart';

/// The chip grey of the job frames (`user_side/Jobs.png`), a shade lighter
/// than the kit's.
const mJobChipBg = Color(0xFFF6F6F6);

/// A job in a list — Jobs, and both tabs of My Jobs: the business's logo, the
/// title, the business, where and what kind, the pay, and the grey chips, with
/// the heart on the end.
///
/// My Jobs adds to it: [action] sits under the chips in the text's column
/// ("Apply Now"), [footer] runs the full width under the whole row (the
/// application's status).
class MJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;
  final Widget? action;
  final Widget? footer;

  const MJobCard({super.key, required this.job, this.onTap, this.action, this.footer});

  @override
  Widget build(BuildContext context) {
    final business = job.businessName;
    final location = (job.location ?? '').trim();
    final salary = job.salaryLabel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MAvatar(url: job.businessLogo, name: business ?? job.title, size: 56),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        // Keeps the title clear of the heart, which sits over
                        // the end of this column.
                        padding: const EdgeInsetsDirectional.only(end: 30),
                        child: Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: mHeading(18),
                        ),
                      ),
                      if (business != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          business,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mText(13, color: const Color(0xFF3D3D3D)),
                        ),
                      ],
                      if (location.isNotEmpty || job.jobType != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 20,
                          runSpacing: 6,
                          children: [
                            if (location.isNotEmpty) MJobMeta(IconsaxPlusLinear.location, location),
                            if (job.jobType != null) MJobMeta(IconsaxPlusLinear.briefcase, job.jobType!.label),
                          ],
                        ),
                      ],
                      if (salary != null) ...[
                        const SizedBox(height: 6),
                        MJobMeta(IconsaxPlusLinear.money_send, salary),
                      ],
                      if (job.chips.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final c in job.chips) MChip(c, background: mJobChipBg)],
                        ),
                      ],
                      if (action != null) ...[const SizedBox(height: 14), action!],
                    ],
                  ),
                ),
              ],
            ),
            if (footer != null) ...[const SizedBox(height: 14), footer!],
          ],
        ),
      ),
    );
  }
}

/// The heart on a job, as the frames draw it: bare, grey until saved.
class MJobHeart extends StatelessWidget {
  final String jobId;
  final double iconSize;
  const MJobHeart({super.key, required this.jobId, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    return FavoriteButton(
      kind: FavoriteKind.job,
      id: jobId,
      size: iconSize + 8,
      iconSize: iconSize,
      color: const Color(0xFF4A4A4A),
    );
  }
}

/// A card with its heart over the top end corner, so the heart is a tap of its
/// own and not the card's.
class MJobCardWithHeart extends StatelessWidget {
  final MJobCard card;
  const MJobCardWithHeart({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        card,
        PositionedDirectional(top: 12, end: -4, child: MJobHeart(jobId: card.job.id)),
      ],
    );
  }
}

/// An icon and a line of grey text, as on a job's meta lines.
class MJobMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final double size;
  const MJobMeta(this.icon, this.text, {super.key, this.size = 12.5});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 3.5, color: mStepGrey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mText(size, color: const Color(0xFF4A4A4A)),
          ),
        ),
      ],
    );
  }
}

/// The hairline between cards, inset to the page's margins.
class MJobDivider extends StatelessWidget {
  const MJobDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: mStepHairline);
}

/// The square tick box of the frames: a grey-blue edge, filled mid blue with
/// a white tick when ticked.
class MJobTickBox extends StatelessWidget {
  final bool checked;
  final double size;
  const MJobTickBox({super.key, required this.checked, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? mStepMid : Colors.white,
        border: Border.all(color: checked ? mStepMid : const Color(0xFF7A8BA3), width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: checked ? Icon(Icons.check_rounded, size: size - 4, color: Colors.white) : null,
    );
  }
}
