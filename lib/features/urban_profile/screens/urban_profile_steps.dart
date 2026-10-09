import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/urban_profile.dart';

/// The Urban Profile onboarding (the onboarding designs of 9 Oct, "Step 01" to
/// "Step 3"; the client's spec §4–6): a photo and a few words, interests,
/// favourite places — three light steps after sign-up, each skippable, then
/// the finished profile. [from] is 'profile' when the Profile screen's
/// "Complete your Urban Profile" opened it, so the end leads back there.

bool _he(BuildContext context) => Localizations.localeOf(context).languageCode == 'he';

/// The next screen after [step]: the next step, or the finished profile.
void _next(BuildContext context, int step, String? from) {
  final q = from == null ? '' : '?from=$from';
  // Pushed, so Back goes one step back.
  context.push(step < 3 ? '/urban-profile/${step + 1}$q' : '/urban-profile/done$q');
}

/// The frame shared by the three steps: back, the three-part progress bar,
/// the title and the line under it, the step's own content, and Skip for Now
/// beside the main button at the foot.
class _StepFrame extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onSkip;
  final bool busy;

  const _StepFrame({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSkip,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MBackArrow(
                            color: const Color(0xFF3D3D3D),
                            // One step back; from the first, out of the
                            // onboarding to wherever it was opened from.
                            onTap: () => context.canPop() ? context.pop() : context.go('/'),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 1; i <= 3; i++)
                              Container(
                                width: 26,
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: i <= step ? mStepMid : const Color(0xFFDADADA),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: mText(24, weight: FontWeight.w700, color: Colors.black)),
                        const SizedBox(height: 8),
                        Text(subtitle, style: mText(13.5, color: mStepGrey, height: 1.4)),
                        const SizedBox(height: 24),
                        body,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: MButton(
                          label: mTr(context, 'Skip for Now', 'דלג בינתיים'),
                          outlined: true,
                          onTap: busy ? null : onSkip,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MButton(
                          label: primaryLabel,
                          icon: Directionality.of(context) == TextDirection.rtl
                              ? IconsaxPlusLinear.arrow_left_1
                              : IconsaxPlusLinear.arrow_right_1,
                          iconAfter: true,
                          loading: busy,
                          onTap: onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: photo and a few words ───

class UrbanProfileStep1 extends ConsumerStatefulWidget {
  final String? from;
  const UrbanProfileStep1({super.key, this.from});

  @override
  ConsumerState<UrbanProfileStep1> createState() => _Step1State();
}

class _Step1State extends ConsumerState<UrbanProfileStep1> {
  final _bio = TextEditingController();
  Uint8List? _photo;
  String? _photoName;
  bool _busy = false;
  bool _filled = false;

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _photoName = image.name;
    });
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(urbanProfileRepositoryProvider);
      if (_photo != null) {
        final url = await repo.uploadPhoto(_photo!, _photoName ?? 'photo.jpg');
        await ref.read(authProvider.notifier).updateProfile(avatarUrl: url);
      }
      await repo.saveBio(_bio.text);
      ref.invalidate(myUrbanProfileProvider);
      if (mounted) _next(context, 1, widget.from);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        mToast(context, mTr(context, 'Could not save. Please try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    // Coming back to finish the profile: what is already there is shown.
    final mine = ref.watch(myUrbanProfileProvider).valueOrNull;
    if (!_filled && mine != null) {
      _filled = true;
      _bio.text = mine.bio ?? '';
    }
    final avatar = user?.avatarUrl ?? '';

    return _StepFrame(
      step: 1,
      title: mTr(context, 'Make Your Profile Yours', 'הפרופיל שלכם, בסגנון שלכם'),
      subtitle: mTr(
        context,
        'Add a photo and a little about yourself to personalize your M4U profile.',
        'הוסיפו תמונה וכמה מילים על עצמכם כדי להתאים את הפרופיל שלכם במודיעין בשבילך.',
      ),
      primaryLabel: mTr(context, 'Continue', 'המשך'),
      busy: _busy,
      onPrimary: _busy ? null : _continue,
      onSkip: () => _next(context, 1, widget.from),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pick,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEEF2F7)),
                    child: _photo != null
                        ? Image.memory(_photo!, fit: BoxFit.cover)
                        : avatar.isNotEmpty
                        ? CachedNetworkImage(imageUrl: avatar, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              user?.initials ?? '',
                              style: mText(30, weight: FontWeight.w600, color: mStepMid),
                            ),
                          ),
                  ),
                  PositionedDirectional(
                    end: -2,
                    bottom: 2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: mStepMid,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(IconsaxPlusLinear.camera, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              border: Border.all(color: mStepHairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mTr(context, 'Short Bio', 'כמה מילים עליי'), style: mText(13, weight: FontWeight.w500)),
                TextField(
                  controller: _bio,
                  minLines: 6,
                  maxLines: 8,
                  maxLength: bioMax,
                  onChanged: (_) => setState(() {}),
                  style: mText(14.5),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(top: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                    hintText: mTr(
                      context,
                      'Tell us in a few words what you love about the city…',
                      'ספרו במילים ספורות מה אתם אוהבים בעיר…',
                    ),
                    hintStyle: mText(14, color: const Color(0xFF9A9A9A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('${_bio.text.characters.length}/$bioMax', style: mText(12, color: mStepGrey)),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: interests ───

class UrbanProfileStep2 extends ConsumerStatefulWidget {
  final String? from;
  const UrbanProfileStep2({super.key, this.from});

  @override
  ConsumerState<UrbanProfileStep2> createState() => _Step2State();
}

class _Step2State extends ConsumerState<UrbanProfileStep2> {
  final _chosen = <String>[];
  bool _busy = false;
  bool _filled = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await ref.read(urbanProfileRepositoryProvider).saveInterests(List.of(_chosen));
      ref.invalidate(myUrbanProfileProvider);
      if (mounted) _next(context, 2, widget.from);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        mToast(context, mTr(context, 'Could not save. Please try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myUrbanProfileProvider).valueOrNull;
    if (!_filled && mine != null) {
      _filled = true;
      _chosen.addAll(mine.interests.where((k) => interestOf(k) != null));
    }
    final he = _he(context);
    final full = _chosen.length >= maxInterests;
    final enough = _chosen.length >= minInterests;

    return _StepFrame(
      step: 2,
      title: mTr(context, 'What Interests You?', 'מה מעניין אתכם?'),
      subtitle: mTr(
        context,
        'Choose your interests to help us personalize your Modiin experience.',
        'בחרו תחומי עניין כדי שנתאים לכם את מודיעין.',
      ),
      primaryLabel: mTr(context, 'Continue', 'המשך'),
      busy: _busy,
      onPrimary: _busy || !enough ? null : _continue,
      onSkip: () => _next(context, 2, widget.from),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final i in interests)
                _Chip(
                  icon: i.icon,
                  label: i.label(he),
                  selected: _chosen.contains(i.key),
                  enabled: _chosen.contains(i.key) || !full,
                  onTap: () => setState(() {
                    if (!_chosen.remove(i.key) && !full) _chosen.add(i.key);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            full
                ? mTr(context, 'Up to $maxInterests interests', 'עד $maxInterests תחומי עניין')
                : mTr(
                    context,
                    'Choose at least $minInterests interests · ${_chosen.length} chosen',
                    'בחרו לפחות $minInterests תחומי עניין · נבחרו ${_chosen.length}',
                  ),
            style: mText(12.5, color: enough ? mStepGrey : const Color(0xFFB4540C)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _Chip({required this.icon, required this.label, required this.selected, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? mStepMid : const Color(0xFFB8B8B8);
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6EDF7) : Colors.white,
            border: Border.all(color: selected ? mStepMid : mStepHairline, width: selected ? 1.4 : 1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: mText(13.5, weight: selected ? FontWeight.w600 : FontWeight.w400, color: enabled ? mStepInk : color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 3: favourite places ───

class UrbanProfileStep3 extends ConsumerStatefulWidget {
  final String? from;
  const UrbanProfileStep3({super.key, this.from});

  @override
  ConsumerState<UrbanProfileStep3> createState() => _Step3State();
}

class _Step3State extends ConsumerState<UrbanProfileStep3> {
  final _search = TextEditingController();
  final _chosen = <UrbanPlace>[];
  List<UrbanPlace>? _results;
  Timer? _debounce;
  bool _busy = false;
  bool _filled = false;
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // The directory is asked once typing pauses, not at every letter.
  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(q));
  }

  Future<void> _load(String q) async {
    final seq = ++_searchSeq;
    try {
      final list = await ref.read(urbanProfileRepositoryProvider).searchPlaces(q);
      if (mounted && seq == _searchSeq) setState(() => _results = list);
    } catch (_) {
      if (mounted && seq == _searchSeq) setState(() => _results = const []);
    }
  }

  void _toggle(UrbanPlace p) {
    setState(() {
      final at = _chosen.indexWhere((c) => c.id == p.id);
      if (at >= 0) {
        _chosen.removeAt(at);
      } else if (_chosen.length < maxPlaces) {
        _chosen.add(p);
      } else {
        mToast(context, mTr(context, 'Up to $maxPlaces places', 'עד $maxPlaces מקומות'));
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final mine = ref.read(myUrbanProfileProvider).valueOrNull;
      final picks = {for (final p in mine?.places ?? const <UrbanPlace>[]) p.id: p.topPick};
      await ref.read(urbanProfileRepositoryProvider).savePlaces([for (final p in _chosen) p.id], picks: picks);
      ref.invalidate(myUrbanProfileProvider);
      if (mounted) _next(context, 3, widget.from);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        mToast(context, mTr(context, 'Could not save. Please try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myUrbanProfileProvider).valueOrNull;
    if (!_filled && mine != null) {
      _filled = true;
      _chosen.addAll(mine.places);
    }
    final he = _he(context);
    final searching = _search.text.trim().isNotEmpty;
    final results = _results;

    return _StepFrame(
      step: 3,
      title: mTr(context, 'Your Favorite Places', 'המקומות האהובים עליכם'),
      subtitle: mTr(
        context,
        'Choose up to $maxPlaces places in Modiin you are always happy to return to.',
        'בחרו עד $maxPlaces מקומות במודיעין שתמיד כיף לחזור אליהם.',
      ),
      primaryLabel: mTr(context, 'Get Started', 'בואו נתחיל'),
      busy: _busy,
      onPrimary: _busy ? null : _finish,
      onSkip: () => _next(context, 3, widget.from),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            decoration: BoxDecoration(
              border: Border.all(color: mStepHairline),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(IconsaxPlusLinear.search_normal_1, size: 19, color: Color(0xFF3D3D3D)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) {
                      setState(() {});
                      _onSearch(v);
                    },
                    textInputAction: TextInputAction.search,
                    style: mText(14.5),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: mTr(context, 'Search places in Modiin…', 'חיפוש מקומות במודיעין…'),
                      hintStyle: mText(14.5, color: const Color(0xFF8A8A8A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_chosen.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              mTr(context, 'Your places (${_chosen.length}/$maxPlaces)', 'המקומות שלכם (${_chosen.length}/$maxPlaces)'),
              style: mText(14, weight: FontWeight.w600),
            ),
            for (final p in _chosen) _PlaceRow(place: p, hebrew: he, chosen: true, onTap: () => _toggle(p)),
          ],
          const SizedBox(height: 20),
          Text(
            searching ? mTr(context, 'Results', 'תוצאות') : mTr(context, 'Popular Places', 'מקומות פופולריים'),
            style: mText(14, weight: FontWeight.w600),
          ),
          if (results == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: mStepMid)),
            )
          else if (results.where((r) => !_chosen.any((c) => c.id == r.id)).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                searching
                    ? mTr(context, 'No place by that name.', 'לא נמצא מקום בשם הזה.')
                    : mTr(context, 'Search for a place above.', 'חפשו מקום למעלה.'),
                style: mText(13.5, color: mStepGrey),
              ),
            )
          else
            for (final p in results.where((r) => !_chosen.any((c) => c.id == r.id)))
              _PlaceRow(place: p, hebrew: he, chosen: false, onTap: () => _toggle(p)),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final UrbanPlace place;
  final bool hebrew;
  final bool chosen;
  final VoidCallback onTap;
  const _PlaceRow({required this.place, required this.hebrew, required this.chosen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: mStepHairline))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 56,
                child: place.image != null
                    ? NetworkPhoto(url: place.image!, icon: IconsaxPlusBold.shop, width: double.infinity, height: double.infinity)
                    : ColoredBox(
                        color: const Color(0xFFEEF2F7),
                        child: Icon(
                          place.kind == 'park' ? IconsaxPlusLinear.tree : IconsaxPlusLinear.shop,
                          color: mStepMid,
                          size: 22,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                place.label(hebrew),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: mText(14.5, weight: FontWeight.w500),
              ),
            ),
            Icon(
              chosen ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
              color: chosen ? const Color(0xFFE5484D) : mStepMid,
              size: 24,
              semanticLabel: chosen
                  ? mTr(context, 'Remove from my places', 'הסרה מהמקומות שלי')
                  : mTr(context, 'Add to my places', 'הוספה למקומות שלי'),
            ),
          ],
        ),
      ),
    );
  }
}
