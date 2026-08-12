import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.borderClr, width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex(context),
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                case 1:
                  context.go('/businesses');
                case 2:
                  context.go('/map');
                case 3:
                  context.go('/news');
                case 4:
                  context.go('/municipal');
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'בית',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: 'עסקים',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'מפה',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.newspaper_outlined),
                activeIcon: Icon(Icons.newspaper),
                label: 'חדשות',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_outlined),
                activeIcon: Icon(Icons.account_balance),
                label: 'עירוני',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
