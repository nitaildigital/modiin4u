import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';

class BusinessesScreen extends StatelessWidget {
  const BusinessesScreen({super.key});

  static const _categories = [
    _Category('Bars', '24 businesses', Color(0xFF2D1B4E), Color(0xFF4A2D6E)),
    _Category(
        'Coffee Shops', '38 businesses', Color(0xFF3E2723), Color(0xFF5D4037)),
    _Category(
        'Restaurants', '126 businesses', Color(0xFF1B3A2D), Color(0xFF2E5A47)),
    _Category('Aesthetics &\nGrooming', '42 businesses', Color(0xFF4E1B3A),
        Color(0xFF6E2D54)),
    _Category('Sports &\nFitness', '31 businesses', Color(0xFF1A237E),
        Color(0xFF283593)),
    _Category(
        'Hairdressers', '27 businesses', Color(0xFF4E342E), Color(0xFF6D4C41)),
    _Category(
        'Services', '51 businesses', Color(0xFF263238), Color(0xFF37474F)),
    _Category('Education', '19 businesses', Color(0xFF1B5E20),
        Color(0xFF2E7D32)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Title ──
            Text(
              'Filter Your Discover Feed',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE7E7E7)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      IconsaxPlusLinear.search_normal_1,
                      size: 18,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search businesses in Modiin...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Category grid ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: 174 / 170,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _CategoryCard(
                      category: cat,
                      onTap: () {
                        // TODO: Navigate to filtered business list
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Category data model
// ═══════════════════════════════════════════════
class _Category {
  final String name;
  final String count;
  final Color colorStart;
  final Color colorEnd;

  const _Category(this.name, this.count, this.colorStart, this.colorEnd);
}

// ═══════════════════════════════════════════════
// Category card widget
// ═══════════════════════════════════════════════
class _CategoryCard extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              category.colorEnd,
              category.colorStart,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Dark bottom gradient overlay (like the Figma design)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5235, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0xBB000000),
                    ],
                  ),
                ),
              ),
            ),

            // Category icon watermark
            Positioned(
              top: 16,
              right: 16,
              child: Icon(
                _iconFor(category.name),
                size: 40,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),

            // Text content at bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.count,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Bars':
        return IconsaxPlusBold.coffee;
      case 'Coffee Shops':
        return IconsaxPlusBold.coffee;
      case 'Restaurants':
        return IconsaxPlusBold.reserve;
      case 'Aesthetics &\nGrooming':
        return IconsaxPlusBold.brush_1;
      case 'Sports &\nFitness':
        return IconsaxPlusBold.weight;
      case 'Hairdressers':
        return IconsaxPlusBold.scissor;
      case 'Services':
        return IconsaxPlusBold.setting_2;
      case 'Education':
        return IconsaxPlusBold.book_1;
      default:
        return IconsaxPlusBold.shop;
    }
  }
}
