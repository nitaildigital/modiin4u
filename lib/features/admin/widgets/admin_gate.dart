import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../admin_language.dart';

/// Stands in front of the admin area.
///
/// `/admin` was an ordinary route: anyone who typed it, or who followed a
/// link, opened the whole control centre. This asks who is there first.
///
/// It is the outer of two doors, not the only one — the row level security
/// policies decide what the admin area may actually read and write, and this
/// resolves an administrator through the same `is_admin()` the policies use,
/// so the screen and the database cannot disagree.
class AdminGate extends ConsumerWidget {
  final Widget child;

  const AdminGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    // The stored session takes a moment to read back, so a null here does not
    // yet mean signed out.
    //
    // Nor does it straight after signing in. That is two steps — the session
    // arrives, then the profile and the admin check load — and the sign-in
    // page comes here as soon as the first is done. On a slow line the second
    // had not, so the gate saw nobody, sent the administrator back to sign in,
    // and the fields came up empty as if the password had been wrong. A
    // session with no user yet is a load in progress, not a stranger.
    final signingIn = SupabaseConfig.client.auth.currentSession != null;
    if (user == null && (ref.watch(authRestoringProvider) || signingIn)) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      // Carry the destination through the sign-in. Without it, somebody who
      // opens /admin is sent to the resident login, signs in, and lands on
      // the resident home page — having to know to type /admin a second
      // time. There is one account system and administration is a role on
      // the account, so the login screen is the right one; forgetting the
      // errand is not.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.pushReplacement('/login?next=/admin'),
      );
      return const SizedBox.shrink();
    }

    if (!user.isAdmin) return const _NoAccess();

    return child;
  }
}

class _NoAccess extends ConsumerWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: adminDir,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.lock_1,
                      size: 32,
                      color: Color(0xFF6D6D6D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('אין לך גישה לאזור הניהול', 'You do not have access to the admin area'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.midBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        tr('חזרה לדף הבית', 'Back to the home page'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Someone signed in as a resident (say, after confirming
                  // an e-mail in this browser) had no way to the admin
                  // account but to clear the browser.
                  TextButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    child: Text(
                      tr('כניסה עם חשבון אחר', 'Sign in with another account'),
                      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.midBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
