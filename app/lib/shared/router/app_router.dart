import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/auth/presentation/login_screen.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inventy_app/features/home/presentation/home_screen.dart';
import 'package:inventy_app/features/movements/presentation/movements_screen.dart';
import 'package:inventy_app/features/products/presentation/products_screen.dart';
import 'package:inventy_app/features/sales/presentation/arqueo_screen.dart';
import 'package:inventy_app/features/sales/presentation/sales_screen.dart';
import 'package:inventy_app/features/scanning/presentation/price_check_screen.dart';
import 'package:inventy_app/features/scanning/presentation/scan_screen.dart';
import 'package:inventy_app/features/settings/presentation/settings_screen.dart';
import 'package:inventy_app/features/users/presentation/users_screen.dart';
import 'package:inventy_app/shared/ui/app_shell.dart';

/// Paths only the owner may reach. An employee who deep-links here (or whose
/// nav somehow points here) is bounced back to Inventario. This mirrors the
/// backend's owner-only guard so the UI never shows a screen it can't feed.
const _ownerOnlyPaths = {
  '/dashboard',
  '/sales',
  '/movements',
  '/users',
  '/settings',
};

bool _isOwnerOnly(String location) =>
    _ownerOnlyPaths.any((p) => location == p || location.startsWith('$p/'));

/// URL-driven navigation with an auth guard: if not logged in you land on
/// /login; the ShellRoute keeps the sidebar mounted across the app routes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<bool>(isAuthenticatedProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(isAuthenticatedProvider);
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/home';
      // Logged in but not the owner: keep employees out of owner-only screens.
      final isOwner = ref.read(currentUserProvider)?.isOwner ?? false;
      if (!isOwner && _isOwnerOnly(state.matchedLocation)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const ProductsScreen(),
          ),
          GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
          GoRoute(
            path: '/price',
            builder: (_, __) => const PriceCheckScreen(),
          ),
          GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
          GoRoute(path: '/cash', builder: (_, __) => const ArqueoScreen()),
          GoRoute(
            path: '/movements',
            builder: (_, __) => const MovementsScreen(),
          ),
          GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
