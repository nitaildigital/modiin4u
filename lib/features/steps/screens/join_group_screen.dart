import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart' show MBackArrow;
import '../../../shared/providers/app_settings_provider.dart';
import '../models/step_group.dart';
import '../providers/step_groups_providers.dart';
import '../widgets/step_groups_tab.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

/// Where an invitation lands: `/join/<code>`.
///
/// In the app — opened by the link itself where the phone has verified the
/// site, or by the website's button, or by a code typed under Groups — it
/// shows the group's name and size, says that members see each other's
/// daily steps, and asks: join, or not now. Signed out, it asks the person
/// to sign in first and comes back here.
///
/// In a browser — someone without the app, or a phone that has not
/// verified the link — it shows the same group and offers to open the
/// invitation in the app (the `il.co.modiin4u://app/join/<code>` scheme,
/// which both platforms route here), with the code to type in by hand.
/// The website has no accounts, so nobody joins from it.
class JoinGroupScreen extends ConsumerWidget {
  final String code;
  const JoinGroupScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb && constraints.maxWidth > 1100) {
          return _WebJoinPage(code: normalizeInviteCode(code));
        }
        return _PhoneJoinPage(code: normalizeInviteCode(code));
      },
    );
  }
}

class _PhoneJoinPage extends StatelessWidget {
  final String code;
  const _PhoneJoinPage({required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MBackArrow(
                      color: const Color(0xFF3D3D3D),
                      onTap: () => _leave(context),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: _InvitationCard(code: code, l: L.of(context)),
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

/// Back where the person came from, or — opened from a link, with nothing
/// behind — the Step Counter's groups (the website's home in a browser).
void _leave(BuildContext context) {
  if (context.canPop()) {
    context.back('/steps');
  } else {
    context.go(kIsWeb ? '/' : '/steps?tab=groups');
  }
}

class _WebJoinPage extends ConsumerStatefulWidget {
  final String code;
  const _WebJoinPage({required this.code});

  @override
  ConsumerState<_WebJoinPage> createState() => _WebJoinPageState();
}

class _WebJoinPageState extends ConsumerState<_WebJoinPage>
    with WebLanguageState<_WebJoinPage> {
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));

  @override
  Widget build(BuildContext context) {
    final hebrew = webIsHebrew.value;
    return Directionality(
      textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: hebrew, activeId: null),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 72),
                    Center(
                      child: SizedBox(
                        width: 460,
                        child: _InvitationCard(
                          code: widget.code,
                          l: hebrew ? _he : _en,
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                    WebFooter(isHebrew: hebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends ConsumerStatefulWidget {
  final String code;
  final L l;
  const _InvitationCard({required this.code, required this.l});

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _busy = false;

  L get l => widget.l;

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final id = await ref.read(stepGroupsRepositoryProvider).join(widget.code);
      ref.invalidate(myStepGroupsProvider);
      ref.invalidate(groupPreviewProvider(widget.code));
      if (mounted) context.go('/steps/groups/$id');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showGroupError(context, groupErrorText(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(groupPreviewProvider(widget.code));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: preview.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _message(
          l.somethingWentWrong,
          action: l.tryAgain,
          onAction: () => ref.invalidate(groupPreviewProvider(widget.code)),
        ),
        data: (group) => group == null
            ? _message(
                l.sgInviteInvalid,
                action: kIsWeb ? null : l.close,
                onAction: () => _leave(context),
              )
            : _invitation(group),
      ),
    );
  }

  Widget _invitation(GroupPreview group) {
    final signedIn = ref.watch(authProvider) != null;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE7ECF7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            IconsaxPlusLinear.people,
            size: 30,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.sgInvitationTitle,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          group.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.sgMembers(group.memberCount),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                IconsaxPlusLinear.info_circle,
                size: 18,
                color: AppColors.midBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.sgJoinConsent,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (kIsWeb) ..._webActions() else ..._appActions(group, signedIn),
      ],
    );
  }

  List<Widget> _appActions(GroupPreview group, bool signedIn) {
    if (group.isMember) {
      return [
        Text(
          l.sgAlreadyMember,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _button(l.sgOpenGroup, () => context.go('/steps/groups/${group.id}')),
      ];
    }
    if (!signedIn) {
      return [
        _button(
          l.sgSignInToJoin,
          () => context.push(
            '/login?next=${Uri.encodeComponent('/join/${widget.code}')}',
          ),
        ),
        const SizedBox(height: 8),
        _textButton(l.sgNotNow, () => _leave(context)),
      ];
    }
    return [
      _button(l.sgJoin, _busy ? null : _join, busy: _busy),
      const SizedBox(height: 8),
      _textButton(l.sgNotNow, () => _leave(context)),
    ];
  }

  List<Widget> _webActions() => [
    _button(
      l.sgOpenInApp,
      () => launchUrl(
        Uri.parse('il.co.modiin4u://app/join/${widget.code}'),
        webOnlyWindowName: '_self',
      ),
    ),
    const SizedBox(height: 14),
    Text(
      l.sgWebJoinHint(widget.code),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.inter,
        fontSize: 13,
        color: const Color(0xFF6D6D6D),
      ),
    ),
    // Someone without the app had no way to get it from here. The links are
    // the panel's (Settings), shown once it has them.
    ..._storeLinks(),
  ];

  List<Widget> _storeLinks() {
    final settings = ref.watch(appSettingsProvider).valueOrNull ?? const {};
    final android = storeUrl(settings, AppSettingKeys.androidStoreUrl);
    final ios = storeUrl(settings, AppSettingKeys.iosStoreUrl);
    if (android == null && ios == null) return const [];
    void open(String url) => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    return [
      const SizedBox(height: 14),
      Text(
        // In the card's own language (the desktop page passes it in).
        l.localeName.startsWith('he') ? 'אין לכם את האפליקציה?' : "Don't have the app?",
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFF3D3D3D)),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          if (android != null) _textButton('Google Play', () => open(android)),
          if (ios != null) _textButton('App Store', () => open(ios)),
        ],
      ),
    ];
  }

  Widget _button(String label, VoidCallback? onTap, {bool busy = false}) =>
      SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.midBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onTap,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );

  Widget _textButton(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    child: Text(
      label,
      style: TextStyle(
        fontFamily: AppFonts.inter,
        fontSize: 14,
        color: const Color(0xFF6D6D6D),
      ),
    ),
  );

  Widget _message(String text, {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Icon(
              IconsaxPlusLinear.info_circle,
              size: 32,
              color: Color(0xFF6D6D6D),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              _textButton(action, onAction ?? () {}),
            ],
          ],
        ),
      );
}
