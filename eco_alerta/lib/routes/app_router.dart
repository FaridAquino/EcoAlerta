import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_step1_screen.dart';
import '../features/auth/presentation/screens/register_step2_screen.dart';
import '../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(authRepositoryProvider).isLoggedIn();
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/login') || loc.startsWith('/register');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
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
      GoRoute(
        path: '/home',
        builder: (_, __) => _HomeScreen(authNotifier: authNotifier),
      ),
    ],
  );
});

class _HomeScreen extends ConsumerWidget {
  final AuthNotifier authNotifier;
  const _HomeScreen({required this.authNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 64, color: Color(0xFF0F5238)),
            const SizedBox(height: 16),
            const Text(
              'EcoAlerta',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF0F5238)),
            ),
            const SizedBox(height: 8),
            const Text('Inicio de sesión exitoso'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                await authNotifier.logout();
                if (context.mounted) context.go('/login');
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
