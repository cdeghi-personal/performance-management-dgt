import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/sydle_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/auth/auth_token_storage.dart';
import '../../../core/error/sydle_exception.dart';
import '../domain/auth_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      client: ref.read(sydleClientProvider),
      storage: ref.read(authTokenStorageProvider),
    ));

class AuthRepository {
  final SydleClient _client;
  final AuthTokenStorage _storage;

  AuthRepository({required SydleClient client, required AuthTokenStorage storage})
      : _client = client,
        _storage = storage;

  /// Valida credenciais no SYDLE. Resposta esperada: {"status": "OK"} ou {"status": "NOK"}.
  /// A requisição HTTP já usa o token fixo de serviço (Basic auth).
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final data = await _client.call(
      SydlePackage.appDgt,
      SydleClass.authorization,
      SydleMethod.login,
      body: {'username': username, 'password': password},
    ) as Map<String, dynamic>;

    final status = data['status'] as String?;
    if (status != 'OK') throw const SydleAuthException('Usuário ou senha inválidos.');

    // Persiste sessão localmente (MVP: sem expiração)
    await _storage.saveSession(username: username);

    return AuthUser(username: username);
  }

  Future<bool> hasSession() => _storage.hasSession();

  Future<AuthUser?> restoreSession() async {
    if (!await _storage.hasSession()) return null;
    final username = await _storage.getUsername();
    final displayName = await _storage.getDisplayName();
    final id = await _storage.getUserId();
    if (username == null) return null;
    return AuthUser(username: username, displayName: displayName, id: id);
  }

  Future<void> logout() => _storage.clear();
}