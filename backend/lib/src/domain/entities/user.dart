/// A system user. Two roles: 'owner' (dueño, full access) and 'employee'
/// (empleado, can sell and view stock; may also manage inventory if the owner
/// enables [canManageInventory]).
class User {
  User({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    this.canManageInventory = false,
  });

  final String id;
  final String username;
  final String role;
  final String displayName;

  /// Employee-only toggle. Owners ignore it (they can do everything).
  final bool canManageInventory;

  bool get isOwner => role == 'owner';

  /// Whether this user may create/edit products and register stock movements.
  bool get canManage => isOwner || canManageInventory;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'displayName': displayName,
        'canManageInventory': canManageInventory,
      };
}
