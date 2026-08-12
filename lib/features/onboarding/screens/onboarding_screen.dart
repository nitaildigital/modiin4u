import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    (
      icon: Icons.location_city,
      title: 'ברוכים הבאים למודיעין בשבילך',
      subtitle: 'כל מה שצריך על העיר שלך — במקום אחד.\nעסקים, חדשות, אירועים, נדל"ן ועוד.',
      color: Color(0xFF123A72),
    ),
    (
      icon: Icons.star_rounded,
      title: 'גלו את הטוב ביותר',
      subtitle: 'ביקורות אמיתיות מתושבים מאומתים,\nהטבות בלעדיות ודירוגים שאפשר לסמוך עליהם.',
      color: Color(0xFF17A9D0),
    ),
    (
      icon: Icons.people_rounded,
      title: 'הצטרפו לקהילה',
      subtitle: 'צברו נקודות, השתתפו באירועים,\nותהיו חלק מהקהילה הדיגיטלית של מודיעין.',
      color: Color(0xFF2ECC71),
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [page.color, page.color.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 70, color: Colors.white),
                        ),
                        const SizedBox(height: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rubik(fontSize: 16, color: Colors.white.withValues(alpha: 0.85), height: 1.6),
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text('דלג', style: GoogleFonts.rubik(fontSize: 14, color: Colors.white70)),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i ? Colors.white : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Center(
                            child: Text(
                              _currentPage < _pages.length - 1 ? 'הבא' : 'בואו נתחיל!',
                              style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: _pages[_currentPage].color),
                            ),
                          ),
                        ),
                      ),
                    ],
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
