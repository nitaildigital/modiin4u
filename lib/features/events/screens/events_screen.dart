import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/event_providers.dart';
import 'web_events_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_labels.dart';
import '../widgets/m_event_card.dart';
import '../widgets/m_event_categories.dart';

/// Events – responsive wrapper.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebEventsContent();
        return const _MobileEventsContent();
      },
    );
  }
}

/// Events discovery screen (Figma mobile "Events"): back + "Events in
/// Modiin", the search pill, the category circles, then the event cards and
/// a floating "View on Map".
class _MobileEventsContent extends ConsumerStatefulWidget {
  const _MobileEventsContent();

  @override
  ConsumerState<_MobileEventsContent> createState() =>
      _MobileEventsContentState();
}

class _MobileEventsContentState extends ConsumerState<_MobileEventsContent> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// The circle the list is narrowed to: `all`, `free` or a category slug.
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(eventSearchProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(eventSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final labels = EventLabels(mEventsIsHebrew(context));
    final events = ref.watch(filteredEventsProvider);
    final upcoming = ref.watch(upcomingEventsProvider).valueOrNull;
    final categories =
        ref.watch(eventCategoriesProvider).valueOrNull ?? const [];
    final byEvent =
        ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};
    final circles = upcoming == null
        ? const <MEventCircle>[]
        : MEventCircle.build(
            upcoming: upcoming,
            categories: categories,
            byEvent: byEvent,
            labels: labels,
            l: l,
          );
    final active = circles.where((c) => c.filter == _filter).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, labels),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (circles.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  L.of(context).eventCategories,
                                  style: _sectionTitle,
                                ),
                              ),
                              const SizedBox(height: 16),
                              MEventCategoryRow(
                                circles: circles,
                                selected: _filter,
                                onSelect: (f) => setState(() => _filter = f),
                              ),
                            ],
                            const SizedBox(height: 32),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                active == null || active.filter == 'all'
                                    ? L.of(context).eventsInModiin
                                    : active.label,
                                style: _sectionTitle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: events.when(
                                loading: () => const _EventListSkeleton(),
                                error: (_, _) => ErrorRetry(
                                  onRetry: () =>
                                      ref.invalidate(filteredEventsProvider),
                                ),
                                data: (all) {
                                  final list = active == null
                                      ? all
                                      : all
                                            .where((e) => active.matches(e, byEvent))
                                            .toList();
                                  if (list.isEmpty) {
                                    return ref.watch(eventSearchProvider).isNotEmpty
                                        ? EmptyState(
                                            icon: Icons.search_off,
                                            title: l.noEventsMatch,
                                          )
                                        : EmptyState(
                                            icon: Icons.event_busy_outlined,
                                            title: L.of(context).noUpcomingEvents,
                                            subtitle: L.of(context).newEventsAppearHere,
                                          );
                                  }
                                  return Column(
                                    children: [
                                      for (var i = 0; i < list.length; i++) ...[
                                        MEventCard(
                                          event: list[i],
                                          category: (byEvent[list[i].id] ?? const [])
                                              .map(labels.category)
                                              .firstOrNull,
                                        ),
                                        if (i < list.length - 1)
                                          const SizedBox(height: 12),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating "View on Map" (Figma 598:4750, 141 × 40).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/events-map'),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/m_events_map.svg',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.viewOnMapBtn,
                              style: const TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  static const _sectionTitle = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F1F1F),
  );

  /// Back arrow, the centred title and the search pill (Figma 0–144).
  Widget _buildHeader(BuildContext context, EventLabels labels) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/'),
                  // The arrow points the way back: right in Hebrew.
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: const Icon(
                      IconsaxPlusLinear.arrow_left,
                      size: 24,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    L.of(context).eventsInModiin,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 39),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE7E7E7)),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/web/common/search24.svg',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: L.of(context).searchEvents,
                        hintStyle: const TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          color: Color(0xFF6D6D6D),
                        ),
                        // The pill is the field; the theme's grey fill
                        // and outline would draw a second one inside it.
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the event cards — the same 200px banner and the same
/// three lines beneath it.
class _EventListSkeleton extends StatelessWidget {
  const _EventListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 200, radius: 12),
                SizedBox(height: 12),
                SkeletonLine(width: 230, fontSize: 20),
                SizedBox(height: 10),
                SkeletonLine(width: 170, fontSize: 14),
                SizedBox(height: 12),
                SkeletonLine(width: 110, fontSize: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
