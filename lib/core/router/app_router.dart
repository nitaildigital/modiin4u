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
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import '../../features/auth/screens/favorites_screen.dart';
import '../../features/auth/screens/notifications_screen.dart';
import '../../features/auth/screens/settings_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/professionals/screens/professional_detail_screen.dart';
import '../../features/realestate/screens/realestate_screen.dart';
import '../../features/realestate/screens/listing_detail_screen.dart';
import '../../features/realestate/screens/new_listing_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/deals/screens/deals_screen.dart';
import '../../features/deals/screens/deal_detail_screen.dart';
import '../../features/games/screens/games_screen.dart';
import '../../features/steps/screens/steps_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/search_results_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';

CustomTransitionPage<void> _slideTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
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
        GoRoute(
          path: '/realestate',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RealEstateScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/business/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        BusinessDetailScreen(businessId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/article/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        ArticleScreen(articleId: state.pathParameters['id']!), state,
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
      pageBuilder: (context, state) => _slideTransition(
        EventDetailScreen(eventId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/professional/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        ProfessionalDetailScreen(professionalId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/listing/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        ListingDetailScreen(listingId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/new-listing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NewListingScreen(),
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
      pageBuilder: (context, state) => _slideTransition(
        DealDetailScreen(dealId: state.pathParameters['id']!), state,
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
      pageBuilder: (context, state) => _slideTransition(const LoginScreen(), state),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const ProfileScreen(), state),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const EditProfileScreen(), state),
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        return SearchResultsScreen(query: query);
      },
    ),
  ],
);
