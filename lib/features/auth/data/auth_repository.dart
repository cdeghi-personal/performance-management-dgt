import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/sydle_client.dart';
import '../../../core/api/sydle_search_response.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/error/sydle_exception.dart';
import '../domain/auth_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      client:      ref.read(sydleClientProvider),
      authService: ref.read(authServiceProvider),
      session:     ref.read(sessionManagerProvider),
    ));

class AuthRepository {
  final SydleClient _client;
  final AuthService _authService;
  final SessionManager _session;

  AuthRepository({
    required SydleClient client,
    required AuthService authService,
    required SessionManager session,
  })  : _client = client,
        _authService = authService,
        _session = session;

  /// Login em duas fases:
  ///  1. GET /sys/auth/signIn  → Bearer token
  ///  2a. search employeeDgt  → colaboradorId (via user._id == code do signIn)
  ///  2b. search employeeProfile → perfil do colaborador
  Future<AuthUser> login({required String username, required String password}) async {
    // Fase 1 — token Bearer
    final sess = await _authService.signIn(username, password);
    if (sess.accessToken.isEmpty) {
      throw const SydleAuthException('Usuário ou senha inválidos.');
    }

    // Salva token para que o AuthInterceptor o injete nas chamadas seguintes
    await _session.saveToken(
      accessToken: sess.accessToken,
      expMs:       sess.expMs,
      name:        sess.name,
      login:       sess.login,
      code:        sess.code,
      sessionId:   sess.sessionId,
    );

    // Fase 2a — colaboradorId: search employeeDgt where user._id == sess.code
    final colaboradorId = await _fetchColaboradorId(sess.code);

    // Fase 2b — perfil: search employeeProfile where employee._id == colaboradorId
    final profile = await _fetchProfile(colaboradorId);

    await _session.saveProfile(
      colaboradorId: colaboradorId,
      profile:       profile.name,   // 'employee' | 'leader' | 'hr'
    );

    return AuthUser(
      username:      username,
      colaboradorId: colaboradorId,
      name:          sess.name,
      profile:       profile,
    );
  }

  /// Busca o _id do registro employeeDgt cujo user._id é o code do signIn.
  Future<String> _fetchColaboradorId(String userCode) async {
    final data = await _client.call(
      SydlePackage.projetosDGT,
      SydleClass.colaboradorDGT,
      SydleMethod.search,
      body: {
        'query': {'term': {'user._id': userCode}},
        'size': 1,
      },
    ) as Map<String, dynamic>;

    final id = SydleSearchResponse
        .fromJson(data, (s) => s['_id'] as String? ?? '')
        .firstOrNull ?? '';

    if (id.isEmpty) {
      await _session.clear();
      throw const SydleAuthException(
        'Usuário sem colaborador vinculado. Contate o administrador.',
      );
    }
    return id;
  }

  /// Busca o campo profile do employeeProfile do colaborador.
  /// Retorna UserProfile.employee como fallback.
  Future<UserProfile> _fetchProfile(String colaboradorId) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.employeeProfile,
      SydleMethod.search,
      body: {
        'query': {'term': {'employee._id': colaboradorId}},
        'size': 1,
      },
    ) as Map<String, dynamic>;

    final profileStr = SydleSearchResponse
        .fromJson(data, (s) => s['profile'] as String? ?? '')
        .firstOrNull ?? '';

    return UserProfile.fromString(profileStr);
  }

  Future<bool> hasSession() => _session.hasValidSession();

  Future<AuthUser?> restoreSession() async {
    if (!await _session.hasValidSession()) return null;

    final login         = await _session.getLogin();
    final name          = await _session.getName();
    final colaboradorId = await _session.getColaboradorId();
    final profileStr    = await _session.getProfile();

    if (login == null || colaboradorId == null || colaboradorId.isEmpty) return null;

    return AuthUser(
      username:      login,
      colaboradorId: colaboradorId,
      name:          name ?? login,
      profile:       UserProfile.fromString(profileStr ?? 'employee'),
    );
  }

  Future<void> logout() async {
    final token = await _session.getToken();
    if (token != null && token.isNotEmpty) {
      await _authService.signOut(token);
    }
    await _session.clear();
  }
}
