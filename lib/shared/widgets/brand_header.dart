import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class BrandHeader extends ConsumerWidget {
  final String? searchHint;
  final ValueChanged<String>? onSearch;

  const BrandHeader({
    super.key,
    this.searchHint,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;

    return Container(
      width: double.infinity,
      color: context.cardBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoggedIn)
                          Text(
                            'היי ${user.name.split(' ').first}',
                            style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta),
                          ),
                        Text(
                          'מודיעין בשבילך',
                          style: GoogleFonts.rubik(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isLoggedIn) {
                        context.push('/profile');
                      } else {
                        context.push('/login');
                      }
                    },
                    child: isLoggedIn
                        ? Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              gradient: AppColors.brandGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.initials,
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.surfaceDim,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.borderClr, width: 1),
                            ),
                            child: const Icon(Icons.person_outline, size: 20, color: AppColors.grayMeta),
                          ),
                  ),
                ],
              ),
              if (!isLoggedIn) ...[
                const SizedBox(height: 2),
                Text(
                  'הכל על העיר שלך — במקום אחד',
                  style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta),
                ),
              ],
              if (searchHint != null) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: context.surfaceDim,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onSubmitted: onSearch,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.search, color: AppColors.grayLight, size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.turquoise, size: 16),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
