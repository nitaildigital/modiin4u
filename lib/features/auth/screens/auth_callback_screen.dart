import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Where the links in Supabase's emails land.
///
/// One screen for both places the link can open. On the web it says the
/// address is confirmed and tells the person to go back to the app, which is
/// the whole journey there — a browser has nowhere else to send them. In the
/// app it waits for the session and then carries on to the home screen.
///
/// A password-reset link is different: the session it creates has to be spent
/// on setting a new password, so that case hands over to the reset screen.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    // The Supabase client reads the token out of the URL on its own; this
    // waits for the result rather than parsing anything itself.
    WidgetsBinding.instance.addPostFrameCallback((_) => _settle());
  }

  Future<void> _settle() async {
    // A reset link is handled by its own screen, and the router is already
    // being sent there.
    if (ref.read(passwordResetPendingProvider)) return;

    // Give the session a moment to arrive before deciding anything.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // On a phone there is nothing to read here, so it goes straight on.
    if (!kIsWeb && ref.read(authProvider) != null) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final signedIn = ref.watch(authProvider) != null;
    final restoring = ref.watch(authRestoringProvider);

    if (restoring) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: (signedIn ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    signedIn ? Icons.check_rounded : Icons.error_outline,
                    size: 44,
                    color: signedIn ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  signedIn ? l.emailConfirmed : l.confirmationFailed,
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
                  signedIn
                      ? (kIsWeb ? l.emailConfirmedWeb : l.emailConfirmedApp)
                      : l.confirmationFailedHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    height: 1.5,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
                const SizedBox(height: 32),

                // On the web the journey ends here, so there is nothing
                // useful to press; in the app there is.
                if (!kIsWeb)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go(signedIn ? '/' : '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.midBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        signedIn ? l.backHome : l.signIn,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
