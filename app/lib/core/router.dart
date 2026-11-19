import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/auth_controller.dart';
import 'widgets/ui.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/booking/presentation/booking_page.dart';
import '../features/booking/presentation/business_page.dart';
import '../features/home/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Notifica o GoRouter sempre que o estado de login muda.
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) return '/splash';

      final loggedIn = auth.value != null;
      final onAuthPage = loc == '/login' || loc == '/register';
      if (!loggedIn) return onAuthPage ? null : '/login';
      if (onAuthPage || loc == '/splash') return '/';
      return null;
    },
    routes: [
      _fade('/splash', (_) => const _SplashPage()),
      _fade('/login', (_) => const LoginPage()),
      _fade('/register', (_) => const RegisterPage()),
      _fade('/', (_) => const HomePage()),
      _fade(
        '/business/:id',
        (s) => BusinessPage(businessId: s.pathParameters['id']!),
      ),
      _fade(
        '/business/:id/book/:serviceId',
        (s) => BookingPage(
          businessId: s.pathParameters['id']!,
          serviceId: s.pathParameters['serviceId']!,
        ),
      ),
    ],
  );
});

/// Rota com transição suave de fade entre telas.
GoRoute _fade(String path, Widget Function(GoRouterState) builder) => GoRoute(
  path: path,
  pageBuilder: (_, state) => CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 400),
    child: builder(state),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  ),
);

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: CinematicBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(),
            SizedBox(height: 32),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    ),
  );
}
