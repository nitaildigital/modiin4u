import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'web_realestate_search_screen.dart';

// ═══════════════════════════════════════════════════════════
// Real Estate Search Screen — wrapper with responsive layout
// Web-only page; mobile falls back to the app's own flows.
// ═══════════════════════════════════════════════════════════

class RealEstateSearchScreen extends StatelessWidget {
  final String listingType; // 'sale' or 'rent'
  final String initialQuery;
  const RealEstateSearchScreen({
    super.key,
    required this.listingType,
    this.initialQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebRealEstateSearchContent(
            listingType: listingType,
            initialQuery: initialQuery,
          );
        }
        return _MobilePlaceholder(listingType: listingType);
      },
    );
  }
}

class _MobilePlaceholder extends StatelessWidget {
  final String listingType;
  const _MobilePlaceholder({required this.listingType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          listingType == 'rent' ? 'Apartments For Rent' : 'Apartments For Sale',
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
