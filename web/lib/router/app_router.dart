import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/app_shell.dart';
import '../screens/home_screen.dart';
import '../screens/browse_screen.dart';
import '../screens/search_screen.dart';
import '../screens/library_screen.dart';
import '../screens/artist_detail_screen.dart';
import '../screens/album_detail_screen.dart';
import '../screens/now_playing_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/web/web_home_screen.dart';
import '../screens/web/creator_auth_screen.dart';
import '../screens/web/my_tracks_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Web routes
      GoRoute(
        path: '/web',
        builder: (context, state) => const WebHomeScreen(),
      ),
      GoRoute(
        path: '/web/store',
        builder: (context, state) =>
            const WebHomeScreen(section: 'store'),
      ),
      GoRoute(
        path: '/web/licensing',
        builder: (context, state) =>
            const WebHomeScreen(section: 'licensing'),
      ),
      GoRoute(
        path: '/web/creator',
        builder: (context, state) =>
            const WebHomeScreen(section: 'creator'),
      ),
      GoRoute(
        path: '/web/creator-login',
        builder: (context, state) => const CreatorAuthScreen(),
      ),
      GoRoute(
        path: '/web/my-tracks',
        builder: (context, state) => const MyTracksScreen(),
      ),
      // Mobile shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/browse', builder: (context, state) => const BrowseScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/artist/:id',
        builder: (context, state) => ArtistDetailScreen(artistId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/album/:id',
        builder: (context, state) => AlbumDetailScreen(albumId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/now-playing',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const NowPlayingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
    ],
    redirect: (context, state) {
      if (kIsWeb && state.uri.path == '/') {
        return '/web';
      }
      return null;
    },
  );
}
