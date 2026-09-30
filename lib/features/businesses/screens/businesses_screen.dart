import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../providers/business_providers.dart';
import '../widgets/business_card.dart';
import 'business_list_screen.dart';
import 'web_businesses_screen.dart';
import '../../../l10n/app_localizations.dart';

/// Business directory – responsive wrapper.
class BusinessesScreen extends StatelessWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebBusinessesContent();
        }
        return const _MobileBusinessesContent();
      },
    );
  }
}

class _MobileBusinessesContent extends ConsumerStatefulWidget {
  const _MobileBusinessesContent();

  @override
  ConsumerState<_MobileBusinessesContent> createState() =>
      _MobileBusinessesContentState();
}

class _MobileBusinessesContentState
    extends ConsumerState<_MobileBusinessesContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    context.push('/search?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(businessCategoriesProvider);
    final businesses = ref.watch(businessesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Center(
                  child: Text(
                    L.of(context).navBusinesses,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SearchField(controller: _searchController, onSubmit: _search),
                // The frame goes straight from the search field to the tiles.
                const SizedBox(height: 20),
                categories.when(
                  loading: () => const _CategoryGridSkeleton(),
                  error: (_, _) => ErrorRetry(
                    onRetry: () => ref.invalidate(businessCategoriesProvider),
                  ),
                  data: (list) => _CategoryGrid(categories: list),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/businesses/all'),
                      child: Text(
                        L.of(context).seeAll,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF123A72),
                        ),
                      ),
                    ),
                    _SectionTitle(L.of(context).allBusinesses),
                  ],
                ),
                const SizedBox(height: 12),
                businesses.when(
                  loading: () => Column(
                    children: const [
                      BusinessCardSkeleton(),
                      SizedBox(height: 12),
                      BusinessCardSkeleton(),
                      SizedBox(height: 12),
                      BusinessCardSkeleton(),
                    ],
                  ),
                  error: (_, _) => ErrorRetry(
                    onRetry: () => ref.invalidate(businessesProvider),
                  ),
                  data: (list) => list.isEmpty
                      ? EmptyState(
                          icon: IconsaxPlusLinear.shop,
                          title: L.of(context).noBusinessesToShow,
                        )
                      : Column(
                          children: [
                            for (final b in list.take(8)) ...[
                              BusinessListTile(business: b),
                              const SizedBox(height: 12),
                            ],
                          ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.rubik,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _SearchField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 20,
            color: Color(0xFF6D6D6D),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              decoration: InputDecoration(
                // The app theme fills inputs grey, which drew a second pill
                // inside this one. The frame has the outline only.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                hintText: L.of(context).searchBusinessesHint,
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Category grid
// ═══════════════════════════════════════════════
class _CategoryGrid extends ConsumerWidget {
  final List<BusinessCategory> categories;

  const _CategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) return const SizedBox.shrink();

    // Empty until the content load links businesses to categories, at which
    // point every card picks up its count without another change here.
    final counts =
        ref.watch(businessCountsByCategoryProvider).valueOrNull ?? const {};

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: 174 / 170,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          count: counts[category.id],
          onTap: () => context.push(
            '/businesses/category/${category.id}'
            '?title=${Uri.encodeComponent(category.name)}',
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final BusinessCategory category;
  final int? count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  static const _icons = <String, IconData>{
    'restaurants': IconsaxPlusBold.reserve,
    'cafe-bakery': IconsaxPlusBold.coffee,
    'health': IconsaxPlusBold.health,
    'sports-fitness': IconsaxPlusBold.weight,
    'education': IconsaxPlusBold.book,
    'services': IconsaxPlusBold.setting_2,
    'shopping': IconsaxPlusBold.shopping_bag,
    'automotive': IconsaxPlusBold.car,
    'beauty': IconsaxPlusBold.brush_2,
    'entertainment': IconsaxPlusBold.music,
  };

  static const _colors = <Color>[
    Color(0xFF17A9D0),
    Color(0xFF2ECC71),
    Color(0xFF8B5CF6),
    Color(0xFFE74C3C),
    Color(0xFFFF9800),
    Color(0xFF123A72),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[category.sortOrder.abs() % _colors.length];
    final image = category.imageUrl;
    final hasImage = image != null && image.isNotEmpty;

    // The frame: the category's photograph under a gradient that runs from
    // clear at the middle to black at the foot, the name and the count in
    // white at the bottom. A category with no photograph on its row keeps
    // the coloured tile and its icon.
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              NetworkPhoto(url: image, icon: IconsaxPlusBold.shop)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.55)!],
                  ),
                ),
              ),
            if (hasImage)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.52, 1],
                    colors: [Color(0x00000000), Colors.black],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasImage)
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Icon(
                        _icons[category.slug] ?? IconsaxPlusBold.shop,
                        size: 26,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count != null && count! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      L.of(context).businessesCount('$count'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the category grid — the same two columns, the same tile
/// aspect, so the grid does not resize when the categories land.
class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: 174 / 170,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const SkeletonBox(radius: 12),
      ),
    );
  }
}
