import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/businesses/screens/businesses_screen.dart';
import '../../features/businesses/screens/business_detail_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/news/screens/article_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/municipal/screens/municipal_screen.dart';
import '../../features/municipal/screens/parking_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/professionals/screens/professional_detail_screen.dart';
import '../../features/realestate/screens/realestate_screen.dart';
import '../../features/realestate/screens/listing_detail_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/deals/screens/deals_screen.dart';
import '../../features/deals/screens/deal_detail_screen.dart';
import '../../features/games/screens/games_screen.dart';
import '../../features/steps/screens/steps_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/businesses',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BusinessesScreen(),
          ),
        ),
        GoRoute(
          path: '/news',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NewsScreen(),
          ),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapScreen(),
          ),
        ),
        GoRoute(
          path: '/municipal',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MunicipalScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/business/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BusinessDetailScreen(
        businessId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/article/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ArticleScreen(
        articleId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/events',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EventsScreen(),
    ),
    GoRoute(
      path: '/event/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => EventDetailScreen(
        eventId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/professional/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ProfessionalDetailScreen(
        professionalId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/realestate',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RealEstateScreen(),
    ),
    GoRoute(
      path: '/listing/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ListingDetailScreen(
        listingId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/community',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/deals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DealsScreen(),
    ),
    GoRoute(
      path: '/deal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => DealDetailScreen(
        dealId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/games',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GamesScreen(),
    ),
    GoRoute(
      path: '/steps',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StepsScreen(),
    ),
    GoRoute(
      path: '/parking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ParkingScreen(),
    ),
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
