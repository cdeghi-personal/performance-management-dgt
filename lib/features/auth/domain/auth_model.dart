class AuthUser {
  final String username;
  final String? id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String role; // 'employee' | 'manager' | 'director' | 'admin'
  final String? departmentId;
  final String? departmentName;

  const AuthUser({
    required this.username,
    this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.role = 'employee',
    this.departmentId,
    this.departmentName,
  });

  String get name => displayName ?? username;
  bool get isManager => role == 'manager' || role == 'director' || role == 'admin';
  bool get isDirector => role == 'director' || role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        username: json['username'] as String? ?? json['login'] as String? ?? '',
        id: json['_id'] as String? ?? json['id'] as String?,
        displayName: json['displayName'] as String? ?? json['name'] as String?,
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String? ?? 'employee',
        departmentId: json['departmentId'] as String?,
        departmentName: json['departmentName'] as String?,
      );

  AuthUser copyWith({String? displayName, String? id, String? role}) => AuthUser(
        username: username,
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        email: email,
        avatarUrl: avatarUrl,
        role: role ?? this.role,
        departmentId: departmentId,
        departmentName: departmentName,
      );
}

class AuthState {
  final bool isAuthenticated;
  final AuthUser? user;

  const AuthState({required this.isAuthenticated, this.user});
  const AuthState.initial() : isAuthenticated = false, user = null;
}