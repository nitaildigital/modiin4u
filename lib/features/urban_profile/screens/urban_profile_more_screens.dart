import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/report_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/urban_profile.dart';
import '../widgets/urban_profile_card.dart';
import 'urban_profile_done_screen.dart' show UrbanProfileVisibilitySwitch;

/// A resident's Urban Profile by its link (`/u/<username>`): read-only, with
/// Report. `urban_profile()` answers only what its owner allowed — a private
/// profile, or one seen signed out, says so and shows nothing.
class UrbanProfileViewScreen extends ConsumerWidget {
  final String username;
  const UrbanProfileViewScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider) != null;
    final restoring = ref.watch(authRestoringProvider);
    final async = ref.watch(urbanProfileByUsernameProvider(username.toLowerCase()));
    final p = async.valueOrNull;

    return MPage(
      title: mTr(context, 'Urban Profile', 'פרופיל עירוני'),
      background: const Color(0xFFF6F8FB),
      action: p == null || p.isOwner || p.id == null
          ? null
          : IconButton(
              tooltip: mTr(context, 'Report', 'דיווח'),
              icon: const Icon(IconsaxPlusLinear.flag, size: 20, color: Color(0xFF3D3D3D)),
              // A profile is reported as its owner's account (reports'
              // `user` type), which the panel opens from Reports.
              onPressed: () => showReportSheet(context, entityType: 'user', entityId: p.id!),
            ),
      body: async.isLoading || restoring
          ? const Center(child: CircularProgressIndicator(color: mStepMid))
          : p == null
          ? MEmpty(
              icon: IconsaxPlusLinear.lock_1,
              title: mTr(context, 'This profile is private', 'הפרופיל הזה פרטי'),
              text: signedIn
                  ? mTr(context, 'Its owner has not shared it with other residents.', 'בעליו לא שיתפו אותו עם תושבים אחרים.')
                  : mTr(context, 'Sign in to see residents’ profiles.', 'התחברו כדי לראות פרופילים של תושבים.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: UrbanProfileCard(
                profile: p,
                onPlace: (place) => context.push('/business/${place.id}'),
              ),
            ),
    );
  }
}

/// Top Picks (the spec's "My Top Picks in Modiin"): up to three of the
/// favourite places, each under one label — My Coffee Spot, My Restaurant,
/// My Place in the City.
class UrbanProfileTopPicksScreen extends ConsumerStatefulWidget {
  const UrbanProfileTopPicksScreen({super.key});

  @override
  ConsumerState<UrbanProfileTopPicksScreen> createState() => _TopPicksState();
}

class _TopPicksState extends ConsumerState<UrbanProfileTopPicksScreen> {
  Map<TopPick, String?>? _picks;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(urbanProfileRepositoryProvider).saveTopPicks(_picks!);
      ref.invalidate(myUrbanProfileProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        mToast(context, mTr(context, 'Could not save. Please try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(myUrbanProfileProvider).valueOrNull;
    final he = Localizations.localeOf(context).languageCode == 'he';
    if (p != null && _picks == null) {
      _picks = {
        for (final pick in TopPick.values)
          pick: p.places.where((pl) => pl.topPick == pick).firstOrNull?.id,
      };
    }
    return MPage(
      title: mTr(context, 'My Top Picks in Modiin', 'הבחירות שלי במודיעין'),
      bottom: p == null || p.places.length < 3
          ? null
          : MButton(label: mTr(context, 'Save', 'שמירה'), loading: _saving, onTap: _saving ? null : _save),
      body: p == null
          ? const Center(child: CircularProgressIndicator(color: mStepMid))
          : p.places.length < 3
          ? MEmpty(
              icon: IconsaxPlusLinear.heart,
              title: mTr(context, 'Choose at least 3 places first', 'בחרו קודם לפחות 3 מקומות'),
              text: mTr(context, 'Top Picks come from your favourite places.', 'הבחירות נלקחות מהמקומות האהובים עליכם.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                for (final pick in TopPick.values) ...[
                  Row(
                    children: [
                      Icon(pick.icon, size: 18, color: mStepMid),
                      const SizedBox(width: 8),
                      Text(pick.label(he), style: mText(15, weight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PickChip(
                        label: mTr(context, 'None', 'ללא'),
                        selected: _picks![pick] == null,
                        onSelected: () => setState(() => _picks![pick] = null),
                      ),
                      for (final place in p.places)
                        _PickChip(
                          label: place.label(he),
                          selected: _picks![pick] == place.id,
                          // One label per place: choosing it here takes it
                          // off the label it had.
                          onSelected: () => setState(() {
                            _picks!.updateAll((k, v) => v == place.id ? null : v);
                            _picks![pick] = place.id;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
    );
  }
}

/// One choice under a Top Pick label, in the app's own colours — the
/// theme's chips draw their label white, which on a white chip is nothing.
class _PickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _PickChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? mStepMid : Colors.white,
          border: Border.all(color: selected ? mStepMid : mStepHairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: mText(13.5, weight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? Colors.white : mStepInk),
        ),
      ),
    );
  }
}

/// Privacy Settings (the spec's §9): who may see the Urban Profile. Private
/// until the resident turns it on.
class UrbanProfilePrivacyScreen extends ConsumerWidget {
  const UrbanProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(myUrbanProfileProvider).valueOrNull;
    return MPage(
      title: mTr(context, 'Privacy Settings', 'הגדרות פרטיות'),
      body: p == null
          ? const Center(child: CircularProgressIndicator(color: mStepMid))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                UrbanProfileVisibilitySwitch(
                  profile: p,
                  onChanged: (on) async {
                    try {
                      await ref.read(urbanProfileRepositoryProvider).setVisible(on);
                      ref.invalidate(myUrbanProfileProvider);
                    } catch (_) {
                      if (context.mounted) {
                        mToast(context, mTr(context, 'Could not save. Please try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
                      }
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  p.isVisible
                      ? mTr(context, 'Signed-in residents can open your profile link.', 'תושבים מחוברים יכולים לפתוח את הקישור לפרופיל שלכם.')
                      : mTr(context, 'Only you can see your profile. Its link shows “This profile is private”.',
                          'רק אתם רואים את הפרופיל. הקישור אליו מציג ״הפרופיל הזה פרטי״.'),
                  style: mText(13, color: mStepGrey, height: 1.45),
                ),
              ],
            ),
    );
  }
}
