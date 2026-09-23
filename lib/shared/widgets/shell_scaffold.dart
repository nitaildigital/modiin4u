import 'package:flutter/material.dart';
import '../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/theme/app_colors.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/businesses')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/news')) return 3;
    if (location.startsWith('/municipal')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isWide = MediaQuery.of(context).size.width > 1100;

    // Back from a tab other than Home returns to Home rather than leaving the
    // app; back from Home itself exits, which is what Android expects.
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: child,
        // Padded for the system navigation bar; without it the labels sit
        // under the gesture pill or the three-button bar on some devices.
        bottomNavigationBar: isWide
            ? null
            : Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                height: 72 + MediaQuery.of(context).padding.bottom,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Color(0x1A555555), blurRadius: 12),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: IconsaxPlusLinear.home,
                      activeIcon: IconsaxPlusBold.home,
                      label: 'בית',
                      isActive: currentIndex == 0,
                      onTap: () => context.go('/'),
                    ),
                    _NavItem(
                      icon: IconsaxPlusLinear.shop,
                      activeIcon: IconsaxPlusBold.shop,
                      label: 'עסקים',
                      isActive: currentIndex == 1,
                      onTap: () => context.go('/businesses'),
                    ),
                    _NavItem(
                      icon: IconsaxPlusLinear.map,
                      activeIcon: IconsaxPlusBold.map,
                      label: 'מפה',
                      isActive: currentIndex == 2,
                      onTap: () => context.go('/map'),
                    ),
                    _NavItem(
                      icon: IconsaxPlusLinear.note,
                      activeIcon: IconsaxPlusBold.note,
                      label: 'חדשות',
                      isActive: currentIndex == 3,
                      onTap: () => context.go('/news'),
                    ),
                    _NavItem(
                      icon: IconsaxPlusLinear.bank,
                      activeIcon: IconsaxPlusBold.bank,
                      label: 'עירייה',
                      isActive: currentIndex == 4,
                      onTap: () => context.go('/municipal'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isActive ? AppColors.midBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.midBlue : const Color(0xFF6D6D6D),
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? AppColors.midBlue : const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
