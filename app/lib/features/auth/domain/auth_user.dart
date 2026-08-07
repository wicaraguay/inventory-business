/// The logged-in user.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    this.canManageInventory = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        displayName: json['displayName'] as String,
        canManageInventory: json['canManageInventory'] as bool? ?? false,
      );

  final String id;
  final String username;
  final String role;
  final String displayName;

  /// Employee-only toggle enabling inventory management. Owners ignore it.
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
