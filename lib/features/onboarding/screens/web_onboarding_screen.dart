import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════
// Web Onboarding — the same hero, at desktop width
//
// This is the one screen with no navbar and no footer: it sits before the
// app proper, so there is nothing yet to navigate to. What it needed was
// a width. The phone layout stretches its buttons to the full window, so
// on a 1920 screen "Sign In" ran nearly two metres wide and the title sat
// alone in the middle of a very large photograph. The content is gathered
// into one 480px card over the same background instead.
//
// Every word comes from the ARB through L.of(context) — this screen was
// translated in September and reads the same keys the phone layout does.
// ═══════════════════════════════════════════════════════════

class WebOnboardingContent extends StatelessWidget {
  const WebOnboardingContent({super.key});

  Future<void> _skip(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/get_started_bg.png', fit: BoxFit.cover),
          // The same overlay the phone layout uses, so the white type holds
          // against a photograph that is light in places.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _skip(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.onboardingSkip,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrolls rather than overflows on a short laptop window.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildCard(context, l),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, L l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 44),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/images/logo_white.svg',
            width: 164,
            height: 88,
          ),
          const SizedBox(height: 32),
          Text(
            l.onboardingTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.onboardingSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.21,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: Text(
                l.signIn,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Google sign-in
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              icon: Image.network(
                'https://www.google.com/favicon.ico',
                width: 24,
                height: 24,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: Color(0xFF4285F4),
                ),
              ),
              label: Text(
                l.continueWithGoogle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 21),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/signup'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.dontHaveAccount,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.signUp,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '${l.onboardingTerms} ${l.termsOfService} '
            '${l.andConjunction.trim()} ${l.privacyPolicy}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
