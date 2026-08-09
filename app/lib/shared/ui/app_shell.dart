import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/alerts/presentation/widgets/alerts_bell.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/auth/presentation/widgets/change_password_sheet.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

typedef NavItem = ({IconData icon, String label, String path, bool ownerOnly});

const navItems = <NavItem>[
  (icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/dashboard', ownerOnly: true),
  (icon: Icons.inventory_2_outlined, label: 'Inventario', path: '/inventory', ownerOnly: false),
  (icon: Icons.sell_outlined, label: 'Precio', path: '/price', ownerOnly: false),
  (icon: Icons.point_of_sale_outlined, label: 'Ventas', path: '/sales', ownerOnly: true),
  (icon: Icons.account_balance_wallet_outlined, label: 'Caja', path: '/cash', ownerOnly: true),
  (icon: Icons.swap_vert, label: 'Movimientos', path: '/movements', ownerOnly: true),
  (icon: Icons.people_outline, label: 'Usuarios', path: '/users', ownerOnly: true),
  (icon: Icons.settings_outlined, label: 'Configuración', path: '/settings', ownerOnly: true),
];

/// App shell: persistent sidebar (wide) or drawer (narrow). Router-driven — the
/// routed page arrives as [child]. Nav items are filtered by the user's role.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static bool _isActive(String path, String location) =>
      location == path || location.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(location: location),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        final activeLabel = navItems
            .firstWhere(
              (n) => _isActive(n.path, location),
              orElse: () => navItems.first,
            )
            .label;
        return Scaffold(
          appBar: AppBar(
            title: Text(activeLabel),
            actions: const [AlertsBell(), SizedBox(width: 4)],
          ),
          drawer: Drawer(child: _Sidebar(location: location)),
          body: child,
        );
      },
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.location});

  final String location;

  void _closeDrawerIfOpen(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.hasDrawer && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;
    final visible = navItems.where((n) => isOwner || !n.ownerOnly);
    return Container(
      width: 280,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [Expanded(child: _Brand()), AlertsBell()],
          ),
          const SizedBox(height: 24),
          for (final item in visible)
            _NavTile(
              item: item,
              selected: AppShell._isActive(item.path, location),
              onTap: () {
                _closeDrawerIfOpen(context);
                context.go(item.path);
              },
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              _closeDrawerIfOpen(context);
              context.go('/scan');
            },
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Nueva venta'),
          ),
          const SizedBox(height: 8),
          const _UserFooter(),
        ],
      ),
    );
  }
}

class _Brand extends ConsumerWidget {
  const _Brand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final base = ref.watch(apiBaseUrlProvider);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: settings.hasLogo
              ? Image.network(
                  '$base/settings/logo?v=${settings.logoVersion}',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackLogo(),
                )
              : _fallbackLogo(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Gestión de stock',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackLogo() => Container(
        width: 40,
        height: 40,
        color: AppColors.primary,
        child: const Icon(Icons.inventory_2, color: Colors.white, size: 22),
      );
}

class _UserFooter extends ConsumerWidget {
  const _UserFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                user.isOwner ? 'Dueño' : 'Empleado',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mi cuenta',
          icon: Icon(Icons.more_vert, color: AppColors.onSurface),
          onSelected: (action) {
            if (action == 'password') {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ChangePasswordSheet(),
              );
            } else {
              ref.read(authProvider.notifier).logout();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'password',
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Cambiar contraseña'),
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: AppColors.danger),
                title: Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: fg),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
