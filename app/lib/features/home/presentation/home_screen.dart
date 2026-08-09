import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

typedef _Action = ({
  IconData icon,
  String label,
  String path,
  Color color,
  bool ownerOnly,
});

const _actions = <_Action>[
  (
    icon: Icons.point_of_sale,
    label: 'Nueva venta',
    path: '/scan',
    color: AppColors.primary,
    ownerOnly: false,
  ),
  (
    icon: Icons.sell_outlined,
    label: 'Consultar precio',
    path: '/price',
    color: Color(0xFF0891B2), // cyan
    ownerOnly: false,
  ),
  (
    icon: Icons.inventory_2_outlined,
    label: 'Inventario',
    path: '/inventory',
    color: Color(0xFF7C3AED), // violet
    ownerOnly: false,
  ),
  (
    icon: Icons.account_balance_wallet_outlined,
    label: 'Caja',
    path: '/cash',
    color: AppColors.warning,
    ownerOnly: true,
  ),
  (
    icon: Icons.receipt_long_outlined,
    label: 'Ventas',
    path: '/sales',
    color: AppColors.success,
    ownerOnly: true,
  ),
  (
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    path: '/dashboard',
    color: Color(0xFF4F46E5),
    ownerOnly: true,
  ),
  (
    icon: Icons.people_outline,
    label: 'Usuarios',
    path: '/users',
    color: Color(0xFFDB2777), // pink
    ownerOnly: true,
  ),
  (
    icon: Icons.settings_outlined,
    label: 'Configuración',
    path: '/settings',
    color: Color(0xFF475569), // slate
    ownerOnly: true,
  ),
];

/// The landing screen after login: a warm welcome + quick-access tiles filtered
/// by role. Simpler and friendlier than dropping the user into the inventory.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isOwner = user?.isOwner ?? false;
    final name = user?.displayName ?? '';
    final actions = _actions.where((a) => isOwner || !a.ownerOnly).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _Welcome(name: name, isOwner: isOwner),
          const SizedBox(height: 24),
          Text('Accesos rápidos',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              // 2 columns on phones, more on wide screens.
              final cols = c.maxWidth ~/ 200 < 2 ? 2 : c.maxWidth ~/ 200;
              const gap = 12.0;
              final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final a in actions)
                    SizedBox(
                      width: tileW,
                      child: _Tile(
                        action: a,
                        onTap: () => context.go(a.path),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Welcome extends ConsumerWidget {
  const _Welcome({required this.name, required this.isOwner});

  final String name;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final base = ref.watch(apiBaseUrlProvider);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: settings.hasLogo
              ? Image.network(
                  '$base/settings/logo?v=${settings.logoVersion}',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatar(),
                )
              : _avatar(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenido 👋',
                  style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.6))),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(isOwner ? 'Dueño' : 'Empleado',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar() => Container(
        width: 56,
        height: 56,
        color: AppColors.primary,
        alignment: Alignment.center,
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.action, required this.onTap});

  final _Action action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
