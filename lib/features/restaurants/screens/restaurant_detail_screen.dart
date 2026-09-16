import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'web_restaurant_detail_screen.dart';

// ═══════════════════════════════════════════════════════════
// Restaurant Detail Screen — wrapper with responsive layout
// Web-only page; mobile falls back to the app's own flows.
// ═══════════════════════════════════════════════════════════

class RestaurantDetailScreen extends StatelessWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebRestaurantDetailContent(restaurantId: restaurantId);
        }
        return const _MobilePlaceholder();
      },
    );
  }
}

class _MobilePlaceholder extends StatelessWidget {
  const _MobilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Restaurant',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Mobile version coming soon',
          style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF5F5E5A)),
        ),
      ),
    );
  }
}
