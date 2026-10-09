import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/urban_profile.dart';
import '../widgets/urban_profile_card.dart';

/// "Your Urban Profile is ready 🎉" (the spec's §7): the card as it now
/// stands, the profile link, who may see it, and Enter Modiin4U / Share.
class UrbanProfileDoneScreen extends ConsumerStatefulWidget {
  final String? from;
  const UrbanProfileDoneScreen({super.key, this.from});

  @override
  ConsumerState<UrbanProfileDoneScreen> createState() => _DoneState();
}

class _DoneState extends ConsumerState<UrbanProfileDoneScreen> {
  final _card = GlobalKey();
  bool _settled = false;
  bool _sharing = false;

  /// On arrival: the profile link is made if there is none (the spec: a
  /// permanent username for everyone), and a profile with all three steps
  /// is marked complete.
  Future<void> _settle(UrbanProfile p) async {
    if (_settled) return;
    _settled = true;
    final repo = ref.read(urbanProfileRepositoryProvider);
    try {
      if (!p.hasUsername) {
        final user = ref.read(authProvider);
        final free = await repo.suggestUsernames(usernameSeed(p.name, user?.email ?? ''));
        if (free.isNotEmpty) await repo.setUsername(free.first);
      }
      if (p.firstIncompleteStep == null && p.completedAt == null) await repo.markCompleted();
      if (!p.hasUsername || (p.firstIncompleteStep == null && p.completedAt == null)) {
        ref.invalidate(myUrbanProfileProvider);
      }
    } catch (_) {
      // The card is still shown; the link can be made from the Profile.
    }
  }

  void _enter() {
    if (widget.from == 'profile') {
      context.go('/profile');
    } else {
      context.go('/');
    }
  }

  Future<void> _setVisible(bool on) async {
    try {
      await ref.read(urbanProfileRepositoryProvider).setVisible(on);
      ref.invalidate(myUrbanProfileProvider);
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Could not save. Please try again.', 'לא ניתן היה לשמור. נסו שוב.'), error: true);
    }
  }

  /// The card as a picture, with the line and — when others may open it —
  /// the link. A private profile's link opens nothing, so sharing it asks
  /// first whether to let residents see the profile.
  Future<void> _share(UrbanProfile p) async {
    var withLink = p.isVisible && p.hasUsername;
    if (!p.isVisible && p.hasUsername) {
      final answer = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(mTr(ctx, 'Share your link too?', 'לשתף גם את הקישור?'), style: mText(17, weight: FontWeight.w600)),
          content: Text(
            mTr(
              ctx,
              'Your profile is private. To open your link, other residents must be able to see it — turn that on?',
              'הפרופיל שלכם פרטי. כדי שאחרים יוכלו לפתוח את הקישור, הם צריכים לראות את הפרופיל — להפעיל?',
            ),
            style: mText(14, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(mTr(ctx, 'Picture only', 'רק תמונה')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(mTr(ctx, 'Turn on and share', 'להפעיל ולשתף')),
            ),
          ],
        ),
      );
      if (answer == null || !mounted) return;
      if (answer) {
        await _setVisible(true);
        withLink = true;
      }
    }

    if (!mounted) return;
    final line = mTr(context, 'This is my Urban Profile on Modiin4U.', 'זה הפרופיל העירוני שלי במודיעין בשבילך.');
    setState(() => _sharing = true);
    try {
      final box = _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final text = withLink ? '$line\n${urbanProfileLink(p.username!)}' : line;
      final files = <XFile>[];
      if (box != null) {
        final image = await box.toImage(pixelRatio: 3);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png != null) {
          files.add(XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png', name: 'urban-profile.png'));
        }
      }
      if (!mounted) return;
      final origin = context.findRenderObject() as RenderBox?;
      final at = origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size;
      if (files.isEmpty) {
        await Share.share(text, sharePositionOrigin: at);
      } else {
        await Share.shareXFiles(files, text: text, sharePositionOrigin: at);
      }
    } catch (_) {
      if (mounted) mToast(context, mTr(context, 'Could not share. Please try again.', 'לא ניתן היה לשתף. נסו שוב.'), error: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myUrbanProfileProvider);
    final p = async.valueOrNull;
    if (p != null) WidgetsBinding.instance.addPostFrameCallback((_) => _settle(p));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: p == null
                ? Center(
                    child: async.hasError
                        ? Text(mTr(context, 'Could not load your profile.', 'לא ניתן היה לטעון את הפרופיל.'), style: mText(14))
                        : const CircularProgressIndicator(color: mStepMid),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                mTr(context, 'Your Urban Profile is ready 🎉', 'הפרופיל העירוני שלכם מוכן 🎉'),
                                textAlign: TextAlign.center,
                                style: mText(24, weight: FontWeight.w700, color: Colors.black),
                              ),
                              const SizedBox(height: 20),
                              RepaintBoundary(
                                key: _card,
                                child: ColoredBox(
                                  color: const Color(0xFFF6F8FB),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: UrbanProfileCard(profile: p),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              UrbanProfileLinkRow(profile: p, editable: true),
                              const SizedBox(height: 12),
                              UrbanProfileVisibilitySwitch(profile: p, onChanged: _setVisible),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Column(
                          children: [
                            MButton(
                              label: widget.from == 'profile'
                                  ? mTr(context, 'Back to my profile', 'חזרה לפרופיל')
                                  : mTr(context, 'Enter Modiin4U', 'כניסה למודיעין בשבילך'),
                              onTap: _enter,
                            ),
                            const SizedBox(height: 10),
                            MButton(
                              label: mTr(context, 'Share Your Urban Profile', 'שיתוף הפרופיל העירוני'),
                              icon: IconsaxPlusLinear.export_1,
                              outlined: true,
                              loading: _sharing,
                              onTap: _sharing ? null : () => _share(p),
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

/// The profile link with Copy — and, on the finished screen, a way to change
/// the username while the profile is new (the spec wants the link stable).
class UrbanProfileLinkRow extends ConsumerWidget {
  final UrbanProfile profile;
  final bool editable;
  const UrbanProfileLinkRow({super.key, required this.profile, this.editable = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = profile.username;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final link = urbanProfileLink(name);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.link_2, size: 18, color: mStepMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              link.replaceFirst('https://', ''),
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mText(13.5, weight: FontWeight.w500),
            ),
          ),
          if (editable)
            IconButton(
              tooltip: mTr(context, 'Change', 'שינוי'),
              icon: const Icon(IconsaxPlusLinear.edit_2, size: 18, color: mStepGrey),
              onPressed: () => _edit(context, ref, name),
            ),
          IconButton(
            tooltip: mTr(context, 'Copy Profile Link', 'העתקת הקישור לפרופיל'),
            icon: const Icon(IconsaxPlusLinear.copy, size: 18, color: mStepMid),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) mToast(context, mTr(context, 'Link copied', 'הקישור הועתק'));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String current) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => _UsernameDialog(current: current),
    );
    if (chosen == null || chosen == current) return;
    try {
      await ref.read(urbanProfileRepositoryProvider).setUsername(chosen);
      ref.invalidate(myUrbanProfileProvider);
    } catch (_) {
      if (context.mounted) {
        mToast(context, mTr(context, 'That name was just taken. Try another.', 'השם הזה נתפס הרגע. נסו אחר.'), error: true);
      }
    }
  }
}

class _UsernameDialog extends ConsumerStatefulWidget {
  final String current;
  const _UsernameDialog({required this.current});

  @override
  ConsumerState<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends ConsumerState<_UsernameDialog> {
  late final _field = TextEditingController(text: widget.current);
  String? _error;
  List<String> _suggestions = const [];
  bool _checking = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final name = _field.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_.]{3,30}$').hasMatch(name)) {
      setState(() => _error = mTr(
        context,
        '3–30 characters: English letters, numbers, dot or underscore.',
        '3–30 תווים: אותיות באנגלית, ספרות, נקודה או קו תחתון.',
      ));
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final repo = ref.read(urbanProfileRepositoryProvider);
    try {
      if (name == widget.current || await repo.usernameAvailable(name)) {
        if (mounted) Navigator.pop(context, name);
        return;
      }
      final near = await repo.suggestUsernames(name);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = mTr(context, 'That name is taken.', 'השם הזה תפוס.');
        _suggestions = near;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = mTr(context, 'Could not check. Please try again.', 'לא ניתן היה לבדוק. נסו שוב.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(mTr(context, 'Your profile link', 'הקישור לפרופיל שלכם'), style: mText(17, weight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(urbanProfileLinkBase.replaceFirst('https://', ''), textDirection: TextDirection.ltr, style: mText(12.5, color: mStepGrey)),
          const SizedBox(height: 6),
          TextField(
            controller: _field,
            autofocus: true,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')), LengthLimitingTextInputFormatter(30)],
            decoration: InputDecoration(errorText: _error, errorMaxLines: 3),
            onSubmitted: (_) => _check(),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _suggestions)
                  // Not the theme's chips, whose label is drawn white.
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, s),
                    child: Text(s, textDirection: TextDirection.ltr, style: mText(13, color: mStepMid)),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(mTr(context, 'Cancel', 'ביטול'))),
        FilledButton(onPressed: _checking ? null : _check, child: Text(mTr(context, 'Save', 'שמירה'))),
      ],
    );
  }
}

/// "Let other residents see my Urban Profile" — off by default (the client,
/// 9 Oct), with exactly what they would see, and what they never do.
class UrbanProfileVisibilitySwitch extends StatelessWidget {
  final UrbanProfile profile;
  final ValueChanged<bool> onChanged;
  const UrbanProfileVisibilitySwitch({super.key, required this.profile, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mTr(context, 'Let other residents see my Urban Profile', 'תושבים אחרים יכולים לראות את הפרופיל העירוני שלי'),
                  style: mText(14, weight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  mTr(
                    context,
                    'They see your photo, name, neighbourhood, bio, interests and places — never your phone, e-mail or date of birth.',
                    'הם רואים תמונה, שם, שכונה, כמה מילים, תחומי עניין ומקומות — אף פעם לא טלפון, אימייל או תאריך לידה.',
                  ),
                  style: mText(12, color: mStepGrey, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MSwitch(value: profile.isVisible, onChanged: onChanged),
        ],
      ),
    );
  }
}
