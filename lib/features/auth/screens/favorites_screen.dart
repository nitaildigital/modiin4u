import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('מועדפים', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.turquoise,
            unselectedLabelColor: AppColors.grayMeta,
            labelStyle: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.rubik(fontSize: 14),
            indicatorColor: AppColors.turquoise,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'עסקים'),
              Tab(text: 'נדל"ן'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _BusinessFavorites(
              ids: user?.favoriteBusinessIds ?? [],
              onRemove: (id) => ref.read(authProvider.notifier).toggleFavoriteBusiness(id),
            ),
            _ListingFavorites(
              ids: user?.favoriteListingIds ?? [],
              onRemove: (id) => ref.read(authProvider.notifier).toggleFavoriteListing(id),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessFavorites extends StatelessWidget {
  final List<String> ids;
  final ValueChanged<String> onRemove;

  const _BusinessFavorites({required this.ids, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return _EmptyState(
        icon: Icons.store_outlined,
        title: 'אין עסקים מועדפים',
        subtitle: 'שמרו עסקים שאהבתם וחזרו אליהם בקלות',
        buttonLabel: 'גלו עסקים',
        onTap: () => context.go('/businesses'),
      );
    }

    const allBusinesses = {
      'demo_0': ('מסעדת נאיתאי', 'תאילנדי · המע"ר', '4.6', Icons.restaurant),
      'demo_1': ('פיצה פרגו', 'פיצה · הפרחים', '4.5', Icons.local_pizza),
      'demo_2': ('קפה גרג', 'בית קפה · נופים', '4.3', Icons.coffee),
      'demo_3': ('בורגרס בר', 'המבורגרים · מוריה', '4.7', Icons.lunch_dining),
      'demo_4': ('סושי מודיעין', 'סושי · אבני חן', '4.4', Icons.set_meal),
      'demo_5': ('המאפייה של שלומי', 'מאפייה · המע"ר', '4.8', Icons.bakery_dining),
      'demo_6': ('ביסטרו 770', 'איטלקי · הנחלים', '4.2', Icons.dinner_dining),
      'demo_7': ('מסעדת ג\'ויה', 'ים תיכוני · משואה', '4.5', Icons.restaurant),
      'demo_8': ('הסטייקיה', 'בשרים · המגינים', '4.1', Icons.restaurant),
      'demo_9': ('בית הפלאפל', 'ישראלי · השבטים', '4.6', Icons.fastfood),
    };
    const fallback = ('עסק', 'קטגוריה · שכונה', '4.0', Icons.store);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: ids.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
      itemBuilder: (context, index) {
        final (name, info, rating, icon) = allBusinesses[ids[index]] ?? fallback;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.midBlue, size: 24),
          ),
          title: Text(name, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
          subtitle: Row(
            children: [
              Text(info, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 2),
              Text(rating, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: AppColors.error, size: 20),
            onPressed: () => onRemove(ids[index]),
          ),
          onTap: () => context.push('/business/${ids[index]}'),
        );
      },
    );
  }
}

class _ListingFavorites extends StatelessWidget {
  final List<String> ids;
  final ValueChanged<String> onRemove;

  const _ListingFavorites({required this.ids, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return _EmptyState(
        icon: Icons.apartment_outlined,
        title: 'אין נכסים שמורים',
        subtitle: 'שמרו דירות שעניינו אתכם ועקבו אחרי שינויי מחיר',
        buttonLabel: 'חפשו נכסים',
        onTap: () => context.push('/realestate'),
      );
    }

    const allListings = {
      'listing_0': ('4 חדרים · 110 מ"ר', 'הפרחים', '2,450,000 ₪'),
      'listing_1': ('5 חדרים · 140 מ"ר', 'אבני חן', '3,100,000 ₪'),
      'listing_2': ('דופלקס · 6 חדרים', 'נופים', '4,200,000 ₪'),
      'listing_3': ('3 חדרים · 85 מ"ר', 'מוריה', '1,950,000 ₪'),
      'listing_4': ('פנטהאוז · 7 חדרים', 'המע"ר', '5,800,000 ₪'),
      'listing_5': ('4 חדרים · 120 מ"ר', 'הנחלים', '2,700,000 ₪'),
    };
    const fallback = ('דירה', 'שכונה', '- ₪');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: ids.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
      itemBuilder: (context, index) {
        final (specs, neighborhood, price) = allListings[ids[index]] ?? fallback;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment, color: AppColors.midBlue, size: 24),
          ),
          title: Text(price, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
          subtitle: Text('$specs · $neighborhood', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: AppColors.error, size: 20),
            onPressed: () => onRemove(ids[index]),
          ),
          onTap: () => context.push('/listing/${ids[index]}'),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.grayMeta),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onTap,
              child: Text(buttonLabel, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
