class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role; // 'employee' | 'manager' | 'director' | 'admin'
  final String? departmentId;
  final String? departmentName;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.departmentId,
    this.departmentName,
  });

  bool get isManager => role == 'manager' || role == 'director' || role == 'admin';
  bool get isDirector => role == 'director' || role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'employee',
        departmentId: json['department_id'] as String?,
        departmentName: json['department_name'] as String?,
      );
}

class AuthState {
  final bool isAuthenticated;
  final AuthUser? user;

  const AuthState({required this.isAuthenticated, this.user});

  const AuthState.initial() : isAuthenticated = false, user = null;
}