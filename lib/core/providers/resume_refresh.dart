import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/businesses/providers/business_providers.dart';
import '../../features/deals/providers/offer_providers.dart';
import '../../features/events/providers/event_providers.dart';
import '../../features/home/providers/home_web_providers.dart';
import '../../features/jobs/providers/job_providers.dart' show liveJobsProvider;
import '../../features/messages/data/messages.dart' show unreadMessagesProvider, conversationsProvider;
import 'account_refresh.dart';
import '../../features/municipal/providers/parking_providers.dart';
import '../../features/news/providers/news_providers.dart';
import '../../features/realestate/providers/listing_providers.dart';
import '../../features/steps/providers/steps_providers.dart';

/// Reads the city's lists again when the app comes back after a while away.
///
/// They are read once and kept for the whole session, so what the client
/// changed in the panel — a business edited, a deal ended, a challenge
/// deleted, a listing approved — showed only after the app was closed and
/// opened again, which on a phone can be days. Back after [away] or more,
/// they are dropped and each screen reads them again as it is shown; a quick
/// glance at another app does not reload anything.
class ResumeRefresh extends ConsumerStatefulWidget {
  final Widget child;
  final Duration away;

  const ResumeRefresh({
    super.key,
    required this.child,
    this.away = const Duration(minutes: 2),
  });

  @override
  ConsumerState<ResumeRefresh> createState() => _ResumeRefreshState();
}

class _ResumeRefreshState extends ConsumerState<ResumeRefresh> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _leftAt = DateTime.now(),
      onShow: () {
        // Messages are read on every return, however short: a reply is what
        // brings someone back to the app.
        ref
          ..invalidate(unreadMessagesProvider)
          ..invalidate(conversationsProvider);
        refreshAfterNotificationWidget(ref);
        final left = _leftAt;
        _leftAt = null;
        if (left != null && DateTime.now().difference(left) >= widget.away) {
          _refresh();
        }
      },
    );
  }

  void _refresh() {
    ref
      ..invalidate(businessesProvider)
      ..invalidate(businessPrimaryCategoryProvider)
      ..invalidate(offersProvider)
      ..invalidate(activeOffersProvider)
      ..invalidate(myClaimsProvider)
      ..invalidate(eventsProvider)
      ..invalidate(listingsProvider)
      ..invalidate(allActiveListingsProvider)
      ..invalidate(publishedArticlesProvider)
      ..invalidate(featuredArticleProvider)
      ..invalidate(restOfArticlesProvider)
      ..invalidate(activeChallengeProvider)
      ..invalidate(homeNoticeProvider)
      ..invalidate(parkingLotsProvider)
      ..invalidate(liveJobsProvider);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
