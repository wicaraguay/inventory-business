import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

typedef NavItem = ({IconData icon, String label, String path});

const _navItems = <NavItem>[
  (icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/dashboard'),
  (icon: Icons.inventory_2_outlined, label: 'Inventario', path: '/inventory'),
  (icon: Icons.point_of_sale_outlined, label: 'Ventas', path: '/sales'),
  (icon: Icons.swap_vert, label: 'Movimientos', path: '/movements'),
  (icon: Icons.settings_outlined, label: 'Configuración', path: '/settings'),
];

/// App shell: persistent sidebar (wide) or drawer (narrow). Router-driven — the
/// routed page arrives as [child]; nav taps change the URL via context.go.
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
        final activeLabel = _navItems
            .firstWhere(
              (n) => _isActive(n.path, location),
              orElse: () => _navItems.first,
            )
            .label;
        return Scaffold(
          appBar: AppBar(title: Text(activeLabel)),
          drawer: Drawer(child: _Sidebar(location: location)),
          body: child,
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location});

  final String location;

  void _closeDrawerIfOpen(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.hasDrawer && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 24),
          for (final item in _navItems)
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
        ],
      ),
    );
  }
}

class _Brand extends ConsumerWidget {
  const _Brand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.businessName));
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              'Gestión de stock',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurface.withValues(alpha: 0.6),
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
