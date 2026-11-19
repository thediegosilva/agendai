enum UserRole { client, owner }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;

  bool get isOwner => role == UserRole.owner;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: json['role'] == 'OWNER' ? UserRole.owner : UserRole.client,
  );
}
