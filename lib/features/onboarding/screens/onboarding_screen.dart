import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'web_onboarding_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _skip(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebOnboardingContent();
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    // Every word on this screen was English, while the app opens in Hebrew.
    // English inside a right-to-left layout puts the punctuation on the wrong
    // side, so the first thing anyone saw read ",Everything in Modiin" and
    // "?Don't have an account".
    final l = L.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/hero_modiin.jpg',
            fit: BoxFit.cover,
          ),
          // Dark overlay for readability
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
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),
                // Skip button (top-right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _skip(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.onboardingSkip,
                              style: TextStyle(fontFamily: AppFonts.inter, 
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
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Logo
                SvgPicture.asset(
                  'assets/images/logo_white.svg',
                  width: 164,
                  height: 88,
                ),
                const SizedBox(height: 40),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Text(
                    l.onboardingTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: AppFonts.rubik, 
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.22,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 58),
                  child: Text(
                    l.onboardingSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: AppFonts.inter, 
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.21,
                    ),
                  ),
                ),
                const Spacer(),
                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sign In button
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
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // A "Continue with Google" button stood here. Its
                      // handler was `// TODO: Google sign-in` — pressing it
                      // did nothing. The provider is off in Supabase
                      // (`/auth/v1/settings` reports `google: false`), so it
                      // could not have worked, and there is no such button
                      // anywhere in the Figma file.
                      //
                      // Wiring it up is real work — credentials in Google
                      // Cloud, the provider enabled, the redirect listed —
                      // and it should be designed before it is built.
                      const SizedBox(height: 21),
                      // Don't have an account? Sign Up
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.dontHaveAccount,
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.signUp,
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Terms text
                      Text(
                        l.onboardingTermsFull,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
