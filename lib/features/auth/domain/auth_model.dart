/// Sessão retornada pelo endpoint /sys/auth/signIn do SYDLE ONE.
class AuthSession {
  final String code;         // _id da conta de sistema SYDLE
  final String name;
  final String login;
  final String accessToken;
  final String? sessionId;
  final int expMs;           // expiração em ms desde epoch

  const AuthSession({
    required this.code,
    required this.name,
    required this.login,
    required this.accessToken,
    this.sessionId,
    required this.expMs,
  });

  /// Parseia a resposta real do SYDLE ONE /sys/auth/signIn.
  ///
  /// Estrutura esperada:
  /// {
  ///   "code": "...", "name": "...", "login": "...",
  ///   "accessToken": {
  ///     "token": "<JWT>",
  ///     "payload": { "exp": <unix_seconds>, "sessionId": "...", ... }
  ///   }
  /// }
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokenObj = json['accessToken'] as Map<String, dynamic>? ?? {};
    final token    = tokenObj['token']   as String? ?? '';
    final payload  = tokenObj['payload'] as Map<String, dynamic>? ?? {};

    // exp está em segundos (Unix timestamp)
    final expSec = payload['exp'] as int? ?? 0;
    final expMs  = expSec > 0
        ? expSec * 1000
        : DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch;

    return AuthSession(
      code:        json['code']              as String? ?? payload['code']  as String? ?? '',
      name:        json['name']              as String? ?? payload['name']  as String? ?? '',
      login:       json['login']             as String? ?? payload['login'] as String? ?? '',
      accessToken: token,
      sessionId:   payload['sessionId']      as String?,
      expMs:       expMs,
    );
  }
}

enum UserProfile {
  employee,
  leader,
  hr;

  static UserProfile fromString(String value) {
    switch (value.toLowerCase()) {
      case 'leader':
        return UserProfile.leader;
      case 'hr':
      case 'rh':
        return UserProfile.hr;
      default:
        return UserProfile.employee;
    }
  }

  bool get isLeader => this == UserProfile.leader;
  bool get isHR => this == UserProfile.hr;
  bool get isEmployee => this == UserProfile.employee;

  // Leader e HR têm acesso à equalização
  bool get canAccessEqualization => isLeader || isHR;
  // Só HR acessa configurações
  bool get canAccessConfig => isHR;
  // Todos os perfis têm auto-avaliação
  bool get hasOwnEvaluations => true;
}

class AuthUser {
  final String username;
  final String colaboradorId;
  final String name;
  final UserProfile profile;

  const AuthUser({
    required this.username,
    required this.colaboradorId,
    required this.name,
    required this.profile,
  });

  // Getters de compatibilidade com telas existentes
  String? get displayName => name;
  String? get id => colaboradorId;
  bool get isManager => profile.canAccessEqualization;
  String get role => switch (profile) {
    UserProfile.leader   => 'leader',
    UserProfile.hr       => 'hr',
    UserProfile.employee => 'employee',
  };
}

class AuthState {
  final bool isAuthenticated;
  final AuthUser? user;

  const AuthState({required this.isAuthenticated, this.user});
  const AuthState.initial() : isAuthenticated = false, user = null;
}
