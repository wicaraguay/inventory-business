import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/users/presentation/users_providers.dart';
import 'package:inventy_app/features/users/presentation/widgets/create_user_sheet.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';

/// Container: Usuarios — the owner manages who can log in and their role.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Usuarios',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Quién puede entrar y con qué permisos',
                      style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Nuevo usuario'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: users.when(
              data: (list) => Card(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _row(context, ref, list[i], zebra: i.isOdd),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AuthUser u,
      {required bool zebra}) {
    final me = ref.watch(currentUserProvider);
    final isSelf = me?.id == u.id;
    return Container(
      color: zebra ? AppColors.canvas : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (u.isOwner ? AppColors.primary : AppColors.success)
                .withValues(alpha: 0.15),
            child: Icon(u.isOwner ? Icons.shield_outlined : Icons.person,
                color: u.isOwner ? AppColors.primary : AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('@${u.username}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          if (!u.isOwner && u.canManageInventory) ...[
            const _InventoryChip(),
            const SizedBox(width: 8),
          ],
          _RoleChip(u.isOwner),
          IconButton(
            tooltip: 'Editar',
            onPressed: () => _edit(context, ref, u),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (!isSelf)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () => _delete(context, ref, u),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<NewUser>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateUserSheet(),
    );
    if (result == null) return;
    try {
      await ref.read(usersProvider.notifier).create(
            username: result.username,
            password: result.password,
            role: result.role,
            displayName: result.displayName,
            canManageInventory: result.canManageInventory,
          );
      if (context.mounted) {
        await showAppAlert(context,
            message: 'Usuario creado.', kind: AlertKind.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo crear: $e', kind: AlertKind.error);
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AuthUser u) async {
    final result = await showModalBottomSheet<NewUser>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateUserSheet(user: u),
    );
    if (result == null) return;
    try {
      await ref.read(usersProvider.notifier).edit(
            id: u.id,
            username: result.username,
            role: result.role,
            displayName: result.displayName,
            canManageInventory: result.canManageInventory,
            newPassword: result.password,
          );
      if (context.mounted) {
        await showAppAlert(context,
            message: 'Usuario actualizado.', kind: AlertKind.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo guardar: $e', kind: AlertKind.error);
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AuthUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a "${u.displayName}"? No podrá volver a entrar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(usersProvider.notifier).remove(u.id);
      if (context.mounted) {
        await showAppAlert(context,
            message: 'Usuario eliminado.', kind: AlertKind.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        await showAppAlert(context,
            message: 'No se pudo eliminar: $e', kind: AlertKind.error);
      }
    }
  }
}

/// Small badge marking an employee who was granted inventory management.
class _InventoryChip extends StatelessWidget {
  const _InventoryChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Inventario',
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip(this.isOwner);
  final bool isOwner;
  @override
  Widget build(BuildContext context) {
    final color = isOwner ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOwner ? 'Dueño' : 'Empleado',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
