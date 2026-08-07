/// A system user. Two roles: 'owner' (dueño, full access) and 'employee'
/// (empleado, can only sell and view stock).
class User {
  User({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
  });

  final String id;
  final String username;
  final String role;
  final String displayName;

  bool get isOwner => role == 'owner';

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'displayName': displayName,
      };
}
