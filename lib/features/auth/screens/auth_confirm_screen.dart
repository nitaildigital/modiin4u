import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Where the links in the e-mails land now.
///
/// They used to point straight at Supabase's `/auth/v1/verify`, which spends
/// the one-time token the moment anything asks for the address. Mail
/// providers ask first: Gmail, Outlook and most security filters follow every
/// link in an incoming message to check it is safe, and that visit used the
/// token up. The person then clicked a link that had already been clicked,
/// and landed on `otp_expired` — every time, however quickly they opened it.
///
/// A link scanner fetches a page; it does not run it. So the mail now brings
/// the token here, as `token_hash`, and nothing is spent until this screen's
/// code runs in a real browser and makes the call itself. See
/// `supabase/email_templates/`.
class AuthConfirmScreen extends ConsumerStatefulWidget {
  final String? tokenHash;
  final String? type;

  const AuthConfirmScreen({super.key, this.tokenHash, this.type});

  @override
  ConsumerState<AuthConfirmScreen> createState() => _AuthConfirmScreenState();
}

enum _Stage { working, failed, confirmed }

class _AuthConfirmScreenState extends ConsumerState<AuthConfirmScreen> {
  _Stage _stage = _Stage.working;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  OtpType? get _otpType => switch (widget.type) {
    'recovery' => OtpType.recovery,
    'email' => OtpType.email,
    'signup' => OtpType.signup,
    'invite' => OtpType.invite,
    'email_change' => OtpType.emailChange,
    _ => null,
  };

  Future<void> _verify() async {
    final hash = widget.tokenHash;
    final type = _otpType;
    if (hash == null || hash.isEmpty || type == null) {
      setState(() => _stage = _Stage.failed);
      return;
    }

    try {
      await SupabaseConfig.client.auth.verifyOTP(type: type, tokenHash: hash);
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.failed);
      return;
    }
    if (!mounted) return;

    // A recovery link signs the person in so they can choose a password;
    // that session has to be spent there before anything else.
    if (type == OtpType.recovery) {
      ref.read(passwordResetPendingProvider.notifier).state = true;
      context.go('/reset-password');
    } else if (kIsWeb) {
      // A resident confirms their address from the e-mail, which opens the
      // website — where residents have no accounts. They were dropped on the
      // home page, signed in, with no word that it had worked. Now the page
      // says so and sends them back to the app; the website session is
      // ended rather than left open.
      await SupabaseConfig.client.auth.signOut();
      if (mounted) setState(() => _stage = _Stage.confirmed);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = _stage == _Stage.failed;

    // The app's language sets the direction; this page was held right to
    // left, so in English its text read back to front.
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: failed
                  ? _buildFailed(context)
                  : _stage == _Stage.confirmed
                  ? _buildConfirmed(context)
                  : _buildWorking(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          L.of(context).verifyingLink,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 16,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmed(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
        ),
        const SizedBox(height: 28),
        Text(
          L.of(context).emailConfirmedWeb,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        TextButton(
          onPressed: () => context.go('/'),
          child: Text(
            Localizations.localeOf(context).languageCode == 'he' ? 'לאתר' : 'Go to the website',
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: AppColors.midBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context) {
    final isRecovery = widget.type == 'recovery';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 44,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          L.of(context).linkInvalid,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRecovery
              ? L.of(context).resetLinkUsedOnce
              : L.of(context).linkUsedOrExpired,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 1.55,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: Text(
              isRecovery ? L.of(context).requestNewLink : L.of(context).signIn,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
