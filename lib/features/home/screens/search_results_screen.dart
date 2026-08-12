import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final allResults = [
      _SearchResult('מסעדת נאיתאי', 'מסעדה תאילנדית · המע"ר', Icons.restaurant, '/business/demo_0', 'עסק'),
      _SearchResult('פיצה פרגו', 'פיצה · המע"ר', Icons.local_pizza, '/business/demo_1', 'עסק'),
      _SearchResult('קפה גרג', 'בית קפה · הפרחים', Icons.coffee, '/business/demo_2', 'עסק'),
      _SearchResult('בורגרס בר', 'המבורגרים · המע"ר', Icons.lunch_dining, '/business/demo_3', 'עסק'),
      _SearchResult('סושי מודיעין', 'סושי · כפר האורנים', Icons.set_meal, '/business/demo_4', 'עסק'),
      _SearchResult('פסטיבל אוכל רחוב', 'אירוע · פארק ענבה', Icons.event, '/event/demo_0', 'אירוע'),
      _SearchResult('הופעה — עידן רייכל', 'אירוע · היכל התרבות', Icons.music_note, '/event/demo_1', 'אירוע'),
      _SearchResult('דירת 4 חדרים הפרחים', 'נדל"ן · 2,450,000 ₪', Icons.apartment, '/listing/1', 'נדל"ן'),
      _SearchResult('חניה מוניציפלית', 'שירות עירוני', Icons.local_parking, '/parking', 'עירוני'),
      _SearchResult('שוק קהילתי', 'אירוע · כיכר המייסדים', Icons.storefront, '/event/demo_2', 'אירוע'),
    ];

    final filtered = query.isEmpty
        ? allResults
        : allResults.where((r) => r.title.contains(query) || r.subtitle.contains(query) || r.category.contains(query)).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('תוצאות חיפוש', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: AppColors.grayLight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        query.isEmpty ? 'הכל' : '"$query"',
                        style: GoogleFonts.rubik(fontSize: 15, color: AppColors.navy),
                      ),
                    ),
                    Text(
                      '${filtered.length} תוצאות',
                      style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: AppColors.grayLight.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('לא נמצאו תוצאות', style: GoogleFonts.rubik(fontSize: 16, color: AppColors.grayMeta)),
                          const SizedBox(height: 8),
                          Text('נסו חיפוש אחר', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.turquoise.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(result.icon, size: 22, color: AppColors.turquoise),
                          ),
                          title: Text(result.title, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.navy)),
                          subtitle: Text(result.subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.midBlue.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(result.category, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.midBlue)),
                          ),
                          onTap: () => context.push(result.route),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String category;

  const _SearchResult(this.title, this.subtitle, this.icon, this.route, this.category);
}
