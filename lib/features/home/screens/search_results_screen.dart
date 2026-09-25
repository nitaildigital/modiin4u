import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../providers/search_providers.dart';
import 'web_search_results_screen.dart';

class SearchResultsScreen extends ConsumerWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebSearchResultsContent(query: query);
        }
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final provider = searchResultsProvider(query);
    final results = ref.watch(provider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('תוצאות חיפוש', style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w700)),
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
                        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 15, color: context.textPrimary),
                      ),
                    ),
                    Text(
                      '${results.valueOrNull?.length ?? 0} תוצאות',
                      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayMeta),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: results.when(
                loading: () => const _SearchSkeleton(),
                error: (_, _) =>
                    ErrorRetry(onRetry: () => ref.invalidate(provider)),
                data: (hits) => hits.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'לא נמצאו תוצאות',
                        subtitle: 'נסו חיפוש אחר',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: hits.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final result = hits[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 6),
                            leading: NetworkPhoto(
                              url: result.imageUrl,
                              width: 44,
                              height: 44,
                              radius: BorderRadius.circular(12),
                              gradient: [
                                AppColors.turquoise.withValues(alpha: 0.10),
                                AppColors.turquoise.withValues(alpha: 0.06),
                              ],
                              icon: result.icon,
                              iconSize: 22,
                              iconColor: AppColors.turquoise,
                            ),
                            title: Text(result.title,
                                style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: context.textPrimary)),
                            subtitle: result.subtitle.isEmpty
                                ? null
                                : Text(result.subtitle,
                                    style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 12,
                                        color: AppColors.grayMeta),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.midBlue.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(result.category,
                                  style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 11,
                                      color: AppColors.midBlue)),
                            ),
                            onTap: () => context.push(result.route),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows shaped like the result tiles: the 44px leading square,
/// two lines, and the category chip on the end.
class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) =>
            const Divider(color: AppColors.border, height: 1),
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              SkeletonBox(width: 44, height: 44, radius: 12),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 170, fontSize: 15),
                    SizedBox(height: 8),
                    SkeletonLine(width: 220, fontSize: 12),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(width: 44, height: 20, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
