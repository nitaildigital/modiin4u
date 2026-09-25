import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../models/business.dart';
import '../providers/business_providers.dart';
import '../widgets/business_card.dart';
import 'web_business_list_screen.dart';

/// Businesses in one category, or all of them when [categoryId] is null.
class BusinessListScreen extends ConsumerWidget {
  final String? categoryId;
  final String title;

  const BusinessListScreen({super.key, this.categoryId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebBusinessListContent(categoryId: categoryId, title: title);
        }
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final provider = businessesByCategoryProvider(categoryId);
    final businesses = ref.watch(provider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            IconsaxPlusLinear.arrow_right_3,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: businesses.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const BusinessCardSkeleton(),
            ),
            error: (error, _) =>
                ErrorRetry(onRetry: () => ref.invalidate(provider)),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: IconsaxPlusLinear.shop,
                    title: 'אין עסקים להצגה',
                    subtitle: 'עסקים יופיעו כאן ברגע שיתווספו',
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(provider);
                      await ref.read(provider.future);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          BusinessListTile(business: list[i]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// One business, rendered with the shared card.
class BusinessListTile extends StatelessWidget {
  final Business business;

  const BusinessListTile({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return BusinessCard(
      name: business.name,
      category: business.category.isNotEmpty
          ? business.category
          : (business.description ?? ''),
      rating: business.rating,
      reviewCount: business.reviewCount,
      // No hours on record yet, so the open/closed tag stays hidden.
      isOpen: business.hours.isEmpty ? null : business.isOpenNow,
      kosher: business.kosherLabel,
      neighborhood: business.neighborhood,
      imageUrl: business.imageUrl,
      onTap: () => context.push('/business/${business.id}'),
    );
  }
}
