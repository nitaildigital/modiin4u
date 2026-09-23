import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// My Apartments screen – user's own apartment listings with status
/// badges (Pending / Approved / Rejected), search bar with filter
/// icon, and an "Add Apartment" button. Shows an empty state when
/// there are no listings.
class MyApartmentsScreen extends StatefulWidget {
  const MyApartmentsScreen({super.key});

  @override
  State<MyApartmentsScreen> createState() => _MyApartmentsScreenState();
}

class _MyApartmentsScreenState extends State<MyApartmentsScreen> {
  final _searchController = TextEditingController();

  static const _demoListings = <_ApartmentListing>[
    _ApartmentListing(
      title: 'Modern 3BR Apartment',
      location: 'Tel Aviv, Israel',
      price: '₪2,450,000',
      statusText: 'Pending',
      statusColor: Color(0xFFDC7600),
      statusBg: Color(0xFFFFF9EF),
      dateText: 'Submitted on 28 July 2026',
    ),
    _ApartmentListing(
      title: 'Luxury 2BR Apartment',
      location: 'Tel Aviv, Israel',
      price: '₪1,850,000',
      statusText: 'Approved',
      statusColor: Color(0xFF0E7E4B),
      statusBg: Color(0xFFE3F6EB),
      dateText: 'Approved on 12 July 2026',
    ),
    _ApartmentListing(
      title: 'Cozy 1BR Apartment',
      location: 'Tel Aviv, Israel',
      price: '₪980,000',
      statusText: 'Rejected',
      statusColor: Color(0xFFCB3E3C),
      statusBg: Color(0xFFFCE9E9),
      dateText: 'Rejected on 05 Jun 2026',
    ),
  ];

  List<_ApartmentListing> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _demoListings;
    return _demoListings
        .where((l) =>
            l.title.toLowerCase().contains(q) ||
            l.location.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = _filtered;

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
                            'My Apartments',
                            style: TextStyle(fontFamily: AppFonts.inter, 
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

                // ═══════════════════════════════════
                // Content: empty or populated
                // ═══════════════════════════════════
                if (_demoListings.isEmpty)
                  Expanded(child: _buildEmptyState())
                else ...[
                  const SizedBox(height: 18),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: const Color(0xFFE7E7E7)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            IconsaxPlusLinear.search_normal_1,
                            size: 18,
                            color: Color(0xFF6D6D6D),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1F1F1F),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search apartments',
                                hintStyle: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6D6D6D),
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                          const Icon(
                            IconsaxPlusLinear.setting_4,
                            size: 20,
                            color: Color(0xFF123A72),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Listings
                  Expanded(
                    child: listings.isEmpty
                        ? Center(
                            child: Text(
                              'No apartments match your search',
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: listings.length,
                            itemBuilder: (_, i) =>
                                _ListingCard(listing: listings[i]),
                          ),
                  ),

                  // Add Apartment button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: GestureDetector(
                      onTap: () => context.push('/add-apartment'),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF123A72),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              IconsaxPlusLinear.add,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add Apartment',
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Empty state
  // ═══════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Illustration placeholder
        Container(
          width: 205,
          height: 153,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              IconsaxPlusLinear.building_3,
              size: 64,
              color: Color(0xFF6D6D6D),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No apartments listed yet',
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Add your first apartment to get started.',
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 40),

        // Add Apartment button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 53),
          child: GestureDetector(
            onTap: () => context.push('/add-apartment'),
            child: Container(
              width: 287,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF123A72),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    IconsaxPlusLinear.add,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Apartment',
                    style: TextStyle(fontFamily: AppFonts.inter, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════════

class _ApartmentListing {
  final String title;
  final String location;
  final String price;
  final String statusText;
  final Color statusColor;
  final Color statusBg;
  final String dateText;

  const _ApartmentListing({
    required this.title,
    required this.location,
    required this.price,
    required this.statusText,
    required this.statusColor,
    required this.statusBg,
    required this.dateText,
  });
}

// ═══════════════════════════════════════════════════
// Listing card
// ═══════════════════════════════════════════════════

class _ListingCard extends StatelessWidget {
  final _ApartmentListing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image thumbnail with status badge ──
          SizedBox(
            width: 120,
            height: 100,
            child: Stack(
              children: [
                // Image placeholder
                Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: listing.statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.statusText,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: listing.statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Info column ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  listing.title,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.location,
                      size: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      listing.location,
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 12,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price
                Text(
                  listing.price,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Date
                Text(
                  listing.dateText,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
          ),

          // ── More menu icon ──
          const Icon(
            IconsaxPlusLinear.more,
            size: 20,
            color: Color(0xFF6D6D6D),
          ),
        ],
      ),
    );
  }
}
