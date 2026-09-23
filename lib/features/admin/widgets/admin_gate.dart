import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../auth/providers/auth_provider.dart';

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
    if (user == null && ref.watch(authRestoringProvider)) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.pushReplacement('/login'),
      );
      return const SizedBox.shrink();
    }

    if (!user.isAdmin) return const _NoAccess();

    return child;
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
                    'אין לך גישה לאזור הניהול',
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
                        'חזרה לדף הבית',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
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
      ),
    );
  }
}
