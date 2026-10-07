import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
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
import '../../features/municipal/screens/shabbat_screen.dart';
import '../../features/municipal/screens/municipal_places_screen.dart';
import '../../features/municipal/models/municipal_place.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/business_signup_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import '../../features/auth/screens/favorites_screen.dart';
import '../../features/auth/screens/notifications_screen.dart';
import '../../features/auth/screens/settings_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/auth_callback_screen.dart';
import '../../features/auth/screens/auth_confirm_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/change_language_screen.dart';
import '../../features/auth/screens/help_support_screen.dart';
import '../../features/site_pages/screens/site_page_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/events_map_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/realestate/screens/realestate_screen.dart';
import '../../features/realestate/screens/listing_detail_screen.dart';
import '../../features/realestate/screens/add_apartment_screen.dart';
import '../../features/realestate/screens/my_apartments_screen.dart';
import '../../features/realestate/screens/realestate_map_screen.dart';
import '../../features/realestate/screens/neighborhood_detail_screen.dart';
import '../../features/realestate/screens/realestate_search_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/deals/screens/deals_screen.dart';
import '../../features/deals/screens/deal_detail_screen.dart';
import '../../features/municipal/screens/parking_detail_screen.dart';
import '../../features/steps/screens/steps_screen.dart';
import 'slug_routes.dart';
import '../../features/steps/screens/join_group_screen.dart';
import '../../features/steps/screens/step_group_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/widgets/admin_gate.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/search_results_screen.dart';
import '../../features/restaurants/screens/restaurants_screen.dart';
import '../../features/restaurants/screens/restaurants_map_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../../l10n/app_localizations.dart';


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
  /// Back one page — or, when there is none to go back to, to [fallback].
  ///
  /// A page opened straight from an address (a Google result on a phone, a
  /// shared link, the website's ☰ menu) is the only page on the stack, and
  /// `pop` there throws: the back arrow did nothing and there was no way out.
  void back([String fallback = '/']) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }

  /// Switches tab for a shell destination, pushes for anything else.
  void goOrPush(String location) {
    if (shellDestinations.contains(location.split('?').first)) {
      go(location);
    } else {
      push(location);
    }
  }
}

/// The phone's slide in from the side; in a browser, a quick fade instead —
/// a website swaps its pages in place (see `appPageTransitions`).
///
/// On an iPhone, Apple's own page: it slides in from the side a Hebrew
/// page starts on, and it can be swiped back from that edge. The custom
/// slide below has no back gesture, so on iPhone the only way out of a
/// page was its arrow — which scrolls away with the header on a long
/// business page. Found testing on the simulator, 5 Oct.
Page<void> _slideTransition(Widget child, GoRouterState state) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage(key: state.pageKey, child: child);
  }
  if (kIsWeb) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
    );
  }
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

/// The resident's own pages — an account, or something posted from one.
///
/// Not `/notifications`: notifications need no account, and on the website
/// that page is where a visitor turns them on — a browser only asks from a
/// click — and sees what was sent.
const _appOnlyPaths = {
  '/onboarding',
  '/signup',
  '/signup/business',
  '/profile',
  '/edit-profile',
  '/change-password',
  '/favorites',
  '/settings',
  '/my-apartments',
  '/add-apartment',
};

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,

  // A phone opens on the splash, which decides between the first-run
  // onboarding and the app. A website must not: go_router treats an incoming
  // location of "/" as no location at all and falls back to this, so someone
  // typing the address got a 2.2-second splash and then a sign-in wall
  // instead of the site. Nobody arrives at a city's website expecting to be
  // asked who they are before they can read the news.
  //
  initialLocation: kIsWeb ? '/' : '/splash',

  // Signing in and posting a property belong to the app. The client decided
  // it on 28 September: the website is for reading the city, the app is for
  // an account. So in a browser the resident's pages lead home — the buttons
  // that opened them are hidden too, but a remembered link or a typed address
  // should not reach a sign-up form either.
  //
  // `/login`, `/reset-password` and `/auth/*` are not on the list: they are
  // how an administrator gets into the control centre, which is web-only.
  redirect: (context, state) {
    final path = state.uri.path;
    if (kIsWeb && _appOnlyPaths.contains(path)) return '/';
    // The old site's addresses end in a slash (/news/modiin-news-523/), and
    // that is how Google and every link out there has them. The routes are
    // written without one.
    if (path.length > 1 && path.endsWith('/')) {
      return state.uri
          .replace(path: path.substring(0, path.length - 1))
          .toString();
    }
    return null;
  },
  errorBuilder: (context, state) => const PageNotFound(),
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
        // The old site's news category addresses (`/new/<slug>/`).
        GoRoute(
          path: '/new/:slug',
          pageBuilder: (context, state) => NoTransitionPage(
            child: SlugPage(
              kind: SlugKind.articleCategory,
              slug: state.pathParameters['slug']!,
              builder: (row) => NewsScreen(categoryId: row.id),
            ),
          ),
        ),
        GoRoute(
          // Where the navbar's news menu leads.
          path: '/news/category/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            child: NewsScreen(categoryId: state.pathParameters['id']),
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
        // A restaurant is a business. This route drew one invented grill
        // restaurant whatever id it was given; it opens the real one now.
        BusinessDetailScreen(businessId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/businesses/category/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        BusinessListScreen(
          categoryId: state.pathParameters['id'],
          title: state.uri.queryParameters['title'] ?? L.of(context).navBusinesses,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/businesses/all',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        BusinessListScreen(title: L.of(context).allBusinesses),
        state,
      ),
    ),
    // By id from inside the app, or by slug from the old site's addresses
    // (`/business/<slug>/`), which Google and every outside link still use.
    GoRoute(
      path: '/business/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        // A reply or review notification names what it is about (00065):
        // the page opens on the Reviews tab at it.
        final review = state.uri.queryParameters['review'];
        final reply = state.uri.queryParameters['reply'];
        return _slideTransition(
          isRowId(id)
              ? BusinessDetailScreen(
                  businessId: id,
                  focusReviewId: review,
                  focusReplyId: reply,
                )
              : SlugPage(
                  kind: SlugKind.business,
                  slug: id,
                  builder: (row) => BusinessDetailScreen(businessId: row.id),
                ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/article/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        ArticleScreen(articleId: state.pathParameters['id']!), state,
      ),
    ),
    // The old site's article addresses (`/news/<slug>/`).
    GoRoute(
      path: '/news/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        SlugPage(
          kind: SlugKind.article,
          slug: state.pathParameters['slug']!,
          builder: (row) => ArticleScreen(articleId: row.id),
        ),
        state,
      ),
    ),
    // The old site's business category addresses (`/business-cat/<slug>/`).
    GoRoute(
      path: '/business-cat/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        SlugPage(
          kind: SlugKind.businessCategory,
          slug: state.pathParameters['slug']!,
          builder: (row) =>
              BusinessListScreen(categoryId: row.id, title: row.name),
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/events',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          EventsScreen(category: state.uri.queryParameters['category']),
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
      path: '/listing/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        ListingDetailScreen(listingId: state.pathParameters['id']!), state,
      ),
    ),
    GoRoute(
      path: '/my-apartments',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const MyApartmentsScreen(), state),
    ),
    GoRoute(
      path: '/add-apartment',
      parentNavigatorKey: _rootNavigatorKey,
      // `?draft=<id>` reopens a draft saved from the phone form.
      pageBuilder: (context, state) => _slideTransition(
        AddApartmentScreen(draftId: state.uri.queryParameters['draft']),
        state,
      ),
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
      path: '/steps',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => StepsScreen(
        groupsTab: state.uri.queryParameters['tab'] == 'groups',
      ),
    ),
    GoRoute(
      path: '/steps/groups/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        StepGroupScreen(
          groupId: state.pathParameters['id']!,
          inviteNow: state.uri.queryParameters['invite'] == '1',
        ),
        state,
      ),
    ),
    // A step group invitation, https://<site>/join/<code>. In the app it
    // asks to join; on the website it offers to open the app. Not on the
    // app-only list: someone without the app must land somewhere.
    GoRoute(
      path: '/join/:code',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        JoinGroupScreen(code: state.pathParameters['code']!),
        state,
      ),
    ),
    GoRoute(
      path: '/parking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ParkingScreen(),
    ),
    // One car park, with what Google Maps knows about it (the client: show
    // whatever Google has).
    GoRoute(
      path: '/parking/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        ParkingDetailScreen(lotId: state.pathParameters['id']!),
        state,
      ),
    ),
    // Parks are businesses filed as a park (`kind = 'park'`); the Municipal
    // page's Parks tile leads here.
    GoRoute(
      path: '/parks',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        BusinessListScreen(title: L.of(context).svcParks, parks: true),
        state,
      ),
    ),
    // The Municipal page's service tiles: institutions, health, education,
    // transport, emergency. An unknown section falls back to the page.
    GoRoute(
      path: '/municipal/:section',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) =>
          MunicipalSection.fromSlug(state.pathParameters['section'] ?? '') ==
              null
          ? '/municipal'
          : null,
      pageBuilder: (context, state) => _slideTransition(
        MunicipalPlacesScreen(
          section: MunicipalSection.fromSlug(state.pathParameters['section']!)!,
        ),
        state,
      ),
    ),
    GoRoute(
      path: '/shabbat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ShabbatScreen(),
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
      path: '/signup/business',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(const BusinessSignUpScreen(), state),
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
    // Where the e-mail links land. The token arrives as `token_hash` and is
    // only spent when this screen's code runs — a mail provider's link
    // scanner fetches the page without running it, so it can no longer use
    // the token up before the person clicks. See AuthConfirmScreen.
    GoRoute(
      path: '/auth/confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AuthConfirmScreen(
        tokenHash: state.uri.queryParameters['token_hash'],
        type: state.uri.queryParameters['type'],
      ),
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
      // The client's own Terms of Use and Privacy Policy, from the panel's
      // עמודי מידע. The screen here printed invented English terms.
      pageBuilder: (context, state) =>
          _slideTransition(const SitePageScreen(slug: 'terms'), state),
    ),
    // The client's own pages, written in the panel (עמודי מידע); the footer's
    // About Us and Accessibility Statement links land here.
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideTransition(const SitePageScreen(slug: 'about'), state),
    ),
    GoRoute(
      path: '/accessibility',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideTransition(const SitePageScreen(slug: 'accessibility'), state),
    ),
    // The lawyer's Privacy Policy, apart from the Terms of Use since 5 Oct.
    GoRoute(
      path: '/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideTransition(const SitePageScreen(slug: 'privacy'), state),
    ),
    // How to delete an account, with or without the app: the address the
    // Terms and the Privacy Policy give, and the page Google Play asks for.
    // Not app-only — someone without the app must be able to open it.
    GoRoute(
      path: '/delete-account',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideTransition(const SitePageScreen(slug: 'delete-account'), state),
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
