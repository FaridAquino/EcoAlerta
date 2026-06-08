import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_step1_screen.dart';
import '../features/auth/presentation/screens/register_step2_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/routes/presentation/screens/routes_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';
import '../features/track/presentation/screens/track_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(authRepositoryProvider).isLoggedIn();
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/login') || loc.startsWith('/register');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/schedule';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register/step1',
        builder: (_, __) => const RegisterStep1Screen(),
      ),
      GoRoute(
        path: '/register/step2',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RegisterStep2Screen(
            email: extra['email'] as String,
            password: extra['password'] as String,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/track', builder: (_, __) => const TrackScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/routes', builder: (_, __) => const RoutesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen())],
          ),
        ],
      ),
    ],
  );
});
