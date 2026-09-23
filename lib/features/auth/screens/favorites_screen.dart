import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../providers/auth_provider.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';

/// Favorites screen – horizontal filter chips (All, Restaurants, Events,
/// Bars, Apartments, News) and a scrollable list of favorited items,
/// each with image thumbnail, info rows, type badge, and red heart icon.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _activeFilter = 0;

  // ── Filter chips ──
  ///
  /// Bars and Apartments are gone from the row: a bar is a business like any
  /// other, and there is no property table to save from.
  static const _filters = [
    _FilterDef('All', IconsaxPlusLinear.element_3, null),
    _FilterDef('Businesses', IconsaxPlusLinear.shop, FavoriteKind.business),
    _FilterDef('Events', IconsaxPlusLinear.calendar_1, FavoriteKind.event),
    _FilterDef('News', IconsaxPlusLinear.document_text, FavoriteKind.article),
  ];

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isLoggedInProvider);
    final entries = ref.watch(favoriteEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Back button + title
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Favorites',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════
                // Filter chips (horizontal scroll)
                // ═══════════════════════════════════
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final f = _filters[index];
                      final active = index == _activeFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = index),
                        child: Container(
                          height: 36,
                          padding: EdgeInsets.symmetric(
                            horizontal: index == 0 ? 15 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFEEF4FD)
                                : Colors.white,
                            border: Border.all(
                              color: active
                                  ? const Color(
                                      0xFF123A72,
                                    ).withValues(alpha: 0.8)
                                  : const Color(0xFFE7E7E7),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                f.icon,
                                size: 16,
                                color: active
                                    ? const Color(0xFF123A72)
                                    : const Color(0xFF6D6D6D),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f.label,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: active
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: active
                                      ? const Color(0xFF123A72)
                                      : const Color(0xFF6D6D6D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════
                // Favorites list
                // ═══════════════════════════════════
                Expanded(
                  child: !signedIn
                      ? _buildSignedOutState()
                      : entries.when(
                          loading: () => const _FavoritesSkeleton(),
                          error: (_, _) => ErrorRetry(
                            onRetry: () =>
                                ref.invalidate(favoriteEntriesProvider),
                          ),
                          data: (all) {
                            final kind = _filters[_activeFilter].kind;
                            final items = kind == null
                                ? all
                                : all.where((e) => e.kind == kind).toList();

                            if (items.isEmpty) return _buildEmptyState();
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: items.length,
                              itemBuilder: (_, i) =>
                                  _FavoriteCard(entry: items[i]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Signed out there is nothing to show and nothing to fetch, so the screen
  /// says what to do rather than looking like an account with nothing saved.
  Widget _buildSignedOutState() {
    return Center(
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
              IconsaxPlusLinear.heart,
              size: 32,
              color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sign in to see your favorites',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => context.push('/login'),
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
                'Sign In',
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              IconsaxPlusLinear.heart,
              size: 32,
              color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save places and items you love',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════

class _FilterDef {
  final String label;
  final IconData icon;

  /// Null on "All".
  final FavoriteKind? kind;

  const _FilterDef(this.label, this.icon, this.kind);
}

// ═══════════════════════════════════════════════
// Favorite card – 120×100 image + info + heart
// ═══════════════════════════════════════════════

class _FavoriteCard extends StatelessWidget {
  final FavoriteEntry entry;
  const _FavoriteCard({required this.entry});

  static const _months = [
    'ינו',
    'פבר',
    'מרץ',
    'אפר',
    'מאי',
    'יונ',
    'יול',
    'אוג',
    'ספט',
    'אוק',
    'נוב',
    'דצמ',
  ];

  String get _typeName => switch (entry.kind) {
    FavoriteKind.business => 'Business',
    FavoriteKind.event => 'Event',
    FavoriteKind.article => 'News',
  };

  Color get _typeColor => switch (entry.kind) {
    FavoriteKind.business => const Color(0xFF31AC4E),
    FavoriteKind.event => const Color(0xFF7247ED),
    FavoriteKind.article => const Color(0xFF1E40B5),
  };

  IconData get _fallbackIcon => switch (entry.kind) {
    FavoriteKind.business => IconsaxPlusBold.shop,
    FavoriteKind.event => IconsaxPlusBold.calendar_1,
    FavoriteKind.article => IconsaxPlusBold.document_text,
  };

  @override
  Widget build(BuildContext context) {
    final date = entry.date;
    final rating = entry.rating;

    return GestureDetector(
      onTap: () => context.push(entry.route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkPhoto(
              url: entry.imageUrl,
              width: 120,
              height: 100,
              radius: BorderRadius.circular(8),
              icon: _fallbackIcon,
              iconSize: 28,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A1230),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (entry.subtitle != null) ...[
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.location,
                          size: 14,
                          color: Color(0xFF6D6D6D),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: const Color(0xFF6D6D6D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (date != null) ...[
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.calendar_1,
                          size: 14,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${date.day} ב${_months[date.month - 1]} ${date.year}',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Hidden at zero rather than shown as 0.0, since no review
                  // has been written yet.
                  if (rating != null && rating > 0) ...[
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusBold.star_1,
                          size: 16,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${entry.reviewCount ?? 0})',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _typeName,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tapping it here removes the row from this very list.
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: FavoriteButton(
                kind: entry.kind,
                id: entry.id,
                size: 32,
                iconSize: 20,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows shaped like the cards: the 120x100 thumbnail, the title,
/// two detail lines and the badge.
class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120, height: 100, radius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 180, fontSize: 14),
                    SizedBox(height: 12),
                    SkeletonLine(width: 140, fontSize: 12),
                    SizedBox(height: 12),
                    SkeletonLine(width: 90, fontSize: 12),
                    SizedBox(height: 12),
                    SkeletonBox(width: 56, height: 18, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
