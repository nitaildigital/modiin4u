import 'package:flutter/material.dart';
import '../../auth/keep_signed_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    // Someone signed in has been through onboarding, whichever way they left
    // it. Only "Skip" used to set the flag, so a resident who signed in from
    // it was shown onboarding again on every launch; it is set now, so a
    // later sign-out does not bring it back either.
    var signedIn = SupabaseConfig.client.auth.currentSession != null;
    // "Remember me" left unticked at sign-in: this start ends that session.
    if (signedIn && !keepSignedIn(prefs)) {
      try {
        await SupabaseConfig.client.auth.signOut();
      } catch (_) {}
      signedIn = false;
    }
    if (signedIn) await prefs.setBool('has_seen_onboarding', true);
    final hasSeenOnboarding = signedIn || (prefs.getBool('has_seen_onboarding') ?? false);
    if (!mounted) return;
    if (hasSeenOnboarding) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // The frame's 193.6° gradient: navy from the top, a touch to the
          // right, to blue at the bottom.
          gradient: LinearGradient(
            begin: Alignment(0.24, -1),
            end: Alignment(-0.24, 1),
            stops: [0.091, 1.0],
            colors: [
              Color(0xFF010A36), // dark navy
              Color(0xFF0058B5), // blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Bottom illustrations — left (palm trees)
            Positioned(
              left: -28,
              bottom: 0,
              child: Opacity(
                opacity: 0.5,
                // Drawn to the frame's width and cropped at the foot, as the
                // design crops it.
                child: SizedBox(
                  width: 275,
                  height: 243,
                  child: ClipRect(
                    child: Image.asset(
                      'assets/images/splash_illustration_left.png',
                      width: 275,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom illustrations — right (buildings)
            Positioned(
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/splash_illustration_right.png',
                  width: 92,
                  height: 217,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Centered logo
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: SvgPicture.asset(
                    'assets/images/logo_white.svg',
                    width: 164,
                    height: 88,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
