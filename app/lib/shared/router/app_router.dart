import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inventy_app/features/movements/presentation/movements_screen.dart';
import 'package:inventy_app/features/products/presentation/products_screen.dart';
import 'package:inventy_app/features/sales/presentation/sales_screen.dart';
import 'package:inventy_app/features/scanning/presentation/scan_screen.dart';
import 'package:inventy_app/features/settings/presentation/settings_screen.dart';
import 'package:inventy_app/shared/ui/app_shell.dart';

/// URL-driven navigation. The ShellRoute keeps the sidebar mounted across
/// routes; only the content area changes. Selecting a product deep-links to
/// /inventory/:productId without leaving the shell.
final appRouter = GoRouter(
  initialLocation: '/inventory',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (_, __) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (_, __) => const ScanScreen(),
        ),
        GoRoute(
          path: '/sales',
          builder: (_, __) => const SalesScreen(),
        ),
        GoRoute(
          path: '/movements',
          builder: (_, __) => const MovementsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
