/// The logged-in user.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        displayName: json['displayName'] as String,
      );

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
