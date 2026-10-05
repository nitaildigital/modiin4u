import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'web_realestate_search_screen.dart';

// ═══════════════════════════════════════════════════════════
// Real Estate Search Screen — wrapper with responsive layout
// Web-only page; at phone width it opens the phone Real Estate page.
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
        return _MobileRedirect(listingType: listingType);
      },
    );
  }
}

/// At phone width these addresses (the old site's, and the website's links)
/// showed "Mobile version coming soon", in English. The phone Real Estate
/// page already lists sale or rent: it opens there on the right tab.
class _MobileRedirect extends ConsumerStatefulWidget {
  final String listingType;
  const _MobileRedirect({required this.listingType});

  @override
  ConsumerState<_MobileRedirect> createState() => _MobileRedirectState();
}

class _MobileRedirectState extends ConsumerState<_MobileRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final f = ref.read(listingFilterProvider);
      ref.read(listingFilterProvider.notifier).state = f.copyWith(
        kind: widget.listingType == 'rent' ? ListingKind.rent : ListingKind.sale,
      );
      context.go('/realestate');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: CircularProgressIndicator()),
  );
}
