import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/urban_profile.dart';
import 'urban_profile_card.dart';

/// The Urban Profile on the Profile screen (the spec's "Complete your
/// Profile Later" and launch additions): the card, how complete it is with
/// the way to finish it (gone once it is complete), Copy Profile Link, Share
/// Profile, Top Picks and Privacy Settings.
class UrbanProfileSection extends ConsumerWidget {
  const UrbanProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(myUrbanProfileProvider).valueOrNull;
    if (p == null) return const SizedBox.shrink();

    final step = p.firstIncompleteStep;
    final incomplete = step != null || !p.hasUsername;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MSectionLabel(mTr(context, 'Urban Profile', 'פרופיל עירוני')),
        const SizedBox(height: 10),
        UrbanProfileCard(profile: p, onPlace: (place) => context.push('/business/${place.id}')),
        if (incomplete) ...[
          const SizedBox(height: 12),
          UrbanProfileCompletion(
            profile: p,
            // Straight to the first step still missing something, not the
            // whole onboarding again; with only the link missing, to the
            // finished profile, which makes it.
            onComplete: () => context.push(
              step == null ? '/urban-profile/done?from=profile' : '/urban-profile/$step?from=profile',
            ),
          ),
        ],
        const SizedBox(height: 12),
        MCard(
          children: [
            if (p.hasUsername)
              _Row(
                icon: IconsaxPlusLinear.copy,
                title: mTr(context, 'Copy Profile Link', 'העתקת הקישור לפרופיל'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: urbanProfileLink(p.username!)));
                  if (context.mounted) mToast(context, mTr(context, 'Link copied', 'הקישור הועתק'));
                },
              ),
            _Row(
              icon: IconsaxPlusLinear.export_1,
              title: mTr(context, 'Share Profile', 'שיתוף הפרופיל'),
              onTap: () => context.push('/urban-profile/done?from=profile'),
            ),
            _Row(
              icon: IconsaxPlusLinear.edit_2,
              title: mTr(context, 'Edit Urban Profile', 'עריכת הפרופיל העירוני'),
              onTap: () => context.push('/urban-profile/1?from=profile'),
            ),
            if (p.places.length >= 3)
              _Row(
                icon: IconsaxPlusLinear.star_1,
                title: mTr(context, 'My Top Picks in Modiin', 'הבחירות שלי במודיעין'),
                onTap: () => context.push('/urban-profile/top-picks'),
              ),
            _Row(
              icon: IconsaxPlusLinear.lock_1,
              title: mTr(context, 'Privacy Settings', 'הגדרות פרטיות'),
              trailing: p.isVisible ? mTr(context, 'Visible', 'גלוי') : mTr(context, 'Private', 'פרטי'),
              onTap: () => context.push('/urban-profile/privacy'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            MIconTile(icon: icon),
            const SizedBox(width: 13),
            Expanded(child: Text(title, style: mText(14, weight: FontWeight.w500))),
            if (trailing != null) ...[
              Text(trailing!, style: mText(12.5, color: mStepGrey)),
              const SizedBox(width: 6),
            ],
            const MChevron(),
          ],
        ),
      ),
    );
  }
}
