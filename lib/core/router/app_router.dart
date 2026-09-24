import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/businesses/screens/businesses_screen.dart';
import '../../features/businesses/screens/business_detail_screen.dart';
import '../../features/businesses/screens/business_list_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/news/screens/article_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/municipal/screens/municipal_screen.dart';
import '../../features/municipal/screens/parking_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import '../../features/auth/screens/favorites_screen.dart';
import '../../features/auth/screens/notifications_screen.dart';
import '../../features/auth/screens/settings_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/auth_callback_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/change_language_screen.dart';
import '../../features/auth/screens/help_support_screen.dart';
import '../../features/auth/screens/terms_conditions_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/events_map_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/professionals/screens/professional_detail_screen.dart';
import '../../features/realestate/screens/realestate_screen.dart';
import '../../features/realestate/screens/listing_detail_screen.dart';
import '../../features/realestate/screens/new_listing_screen.dart';
import '../../features/realestate/screens/add_apartment_screen.dart';
import '../../features/realestate/screens/my_apartments_screen.dart';
import '../../features/realestate/screens/realestate_map_screen.dart';
import '../../features/realestate/screens/neighborhood_detail_screen.dart';
import '../../features/realestate/screens/realestate_search_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/deals/screens/deals_screen.dart';
import '../../features/deals/screens/deal_detail_screen.dart';
import '../../features/games/screens/games_screen.dart';
import '../../features/steps/screens/steps_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/widgets/admin_gate.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/search_results_screen.dart';
import '../../features/restaurants/screens/restaurants_screen.dart';
import '../../features/restaurants/screens/restaurants_map_screen.dart';
import '../../features/restaurants/screens/restaurant_detail_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';


/// The six destinations that live inside the bottom-navigation shell.
///
/// Navigating to one of these should switch tab, which is what `go` does.
/// Navigating anywhere else with `go` throws the whole stack away, so the
/// back button leaves the app instead of returning to the previous screen —
/// use [AppNavigation.goOrPush] rather than choosing by hand.
const shellDestinations = {
  '/',
  '/businesses',
  '/news',
  '/map',
  '/municipal',
  '/realestate',
};

extension AppNavigation on BuildContext {
  /// Switches tab for a shell destination, pushes for anything else.
  void goOrPush(String location) {
    if (shellDestinations.contains(location.split('?').first)) {
      go(location);
    } else {
      push(location);
    }
  }
}

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
      path: '/restaurants',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        const RestaurantsScreen(), state,
      ),
    ),
    GoRoute(
      path: '/restaurants-map',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        const RestaurantsMapScreen(), state,
      ),
    ),
    GoRoute(
      path: '/restaurant/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        RestaurantDetailScreen(restaurantId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/businesses/category/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        BusinessListScreen(
          categoryId: state.pathParameters['id'],
          title: state.uri.queryParameters['title'] ?? 'עסקים',
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/businesses/all',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        const BusinessListScreen(title: 'כל העסקים'),
        state,
      ),
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
      path: '/events-map',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        const EventsMapScreen(), state,
      ),
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
      path: '/my-apartments',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const MyApartmentsScreen(), state),
    ),
    GoRoute(
      path: '/add-apartment',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const AddApartmentScreen(), state),
    ),
    GoRoute(
      path: '/realestate-map',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        const RealEstateMapScreen(), state,
      ),
    ),
    GoRoute(
      path: '/neighborhood/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        NeighborhoodDetailScreen(neighborhoodId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/apartments-sale',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        RealEstateSearchScreen(
          listingType: 'sale',
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/apartments-rent',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        RealEstateSearchScreen(
          listingType: 'rent',
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
        state,
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
    // The control centre is web only. It was compiled into the mobile app,
    // so all 23 of its screens shipped to Play inside the resident's build.
    // `kIsWeb` is a compile-time constant, so on mobile this branch and
    // everything it reaches is dropped from the bundle rather than merely
    // hidden.
    if (kIsWeb)
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        // Anyone who typed this path opened the whole control centre.
        builder: (context, state) =>
            const AdminGate(child: AdminDashboardScreen()),
      ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const LoginScreen(), state),
    ),
    GoRoute(
      path: '/signup',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const SignUpScreen(), state),
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
    // Where the links in Supabase's emails land — both on the web, where the
    // person reads that their address is confirmed, and in the app.
    GoRoute(
      path: '/auth/callback',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthCallbackScreen(),
    ),
    // A reset link needs its own screen: the session it creates has to be
    // spent on setting a new password.
    GoRoute(
      path: '/reset-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/change-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const ChangePasswordScreen(), state),
    ),
    GoRoute(
      path: '/change-language',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const ChangeLanguageScreen(), state),
    ),
    GoRoute(
      path: '/help-support',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const HelpSupportScreen(), state),
    ),
    GoRoute(
      path: '/terms',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const TermsConditionsScreen(), state),
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
